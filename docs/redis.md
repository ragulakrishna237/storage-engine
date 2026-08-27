# Redis: dict + skip list for the same (user_id, score) dataset

This document walks the shared `(user_id, score)` example through Redis’s
sorted-set implementation: a **hash table** (dict) for member→score and a
**skip list** for score-ordered traversal.

It is **not** a Redis reimplementation. [`examples/redis_demo.py`](../examples/redis_demo.py)
issues `ZADD` / `ZSCORE` / `ZRANGEBYSCORE` / `ZREM` against a `redis:7`
container. Redis may also persist via RDB/AOF; this demo does not configure
either, and it does not claim durability comparable to InnoDB redo or
PostgreSQL WAL.

LeetCode tags: [LEETCODE_MAPPING.md](../LEETCODE_MAPPING.md).

---

## Why a sorted set (not only a HASH)

A Redis `HASH` is a dict: `HSET users 1 37` gives O(1) point reads and no
ordered range. InnoDB and PostgreSQL both offer a range on `score`, so the
matching Redis structure is a **sorted set**:

| SQL | Redis |
|---|---|
| row `user_id` | zset **member** (string `"1"` … `"10000"`) |
| column `score` | zset **score** (float; we store integers 0–99) |
| `INSERT` | `ZADD` |
| point read of score | `ZSCORE` |
| `score BETWEEN 50 AND 60` | `ZRANGEBYSCORE 50 60` |
| `DELETE` | `ZREM` |

`updated_at` is not stored in the zset (a zset has one score per member).
The SQL tables keep `updated_at` to show HOT vs secondary-index updates.
On Redis, a point “update” is `ZADD` with a new score for the same member.

Key used by the demo: `users:scores`.

---

## Hash table (dict)

**LeetCode:** [1 Two Sum](https://leetcode.com/problems/two-sum/) /
[706 Design HashMap](https://leetcode.com/problems/design-hashmap/).

Redis’s dict is an open-addressed / chained hash table (chaining via a
next pointer in the entry) with **incremental rehashing**: when the table
grows, Redis allocates `ht[1]`, then moves buckets gradually on subsequent
commands so a 10k `ZADD` loop does not pause for a full copy.

Inside a large zset, the dict maps `member → score` so `ZSCORE` does not
walk the skip list. The keyspace itself is another dict (`users:scores` →
the zset object).

Load factor: Redis expands when `used == size` (roughly 1:1). Inserting
10,000 members grows the dict through several powers of two. This document
does not print Redis’s internal `used`/`size`; `ZCARD` is the observable.

---

## Skip list

**LeetCode:** [1206 Design Skiplist](https://leetcode.com/problems/design-skiplist/).

A skip list is a layered linked list: level-0 is every node, higher levels
are coin-flip express lanes. Redis uses `p = 1/4` for promoting a node to
the next level (not 1/2), and a max level of 32.

Zset nodes are ordered by `(score, member)` so equal scores still have a
total order (members are compared lexicographically). That matches
`ZRANGEBYSCORE` with exclusive/inclusive bounds and makes `ZREM` find the
node without scanning the whole list: Redis looks up the score in the dict,
then searches the skip list for that `(score, member)`.

Expected height of a 10,000-node list with `p = 1/4` is on the order of
`log_4(10000) ≈ 6–7` plus the always-present top. That is **arithmetic from
the algorithm**, not a measured `OBJECT` field (Redis does not expose skip
list height on the object).

### Encoding: listpack vs skiplist+dict

Small zsets are stored as a **listpack** (contiguous encoded entries) for
CPU-cache friendliness. Defaults (Redis 7):

- `zset-max-listpack-entries` = 128
- `zset-max-listpack-value` = 64

**10,000 members exceeds 128**, so the object is converted to the
skiplist+dict representation. Captured **2026-08-26** against **Redis 7.4.11**
(image `redis:7` as resolved that day):

```
OBJECT ENCODING users:scores: skiplist
```

If a custom `redis.conf` raised `zset-max-listpack-entries` above 10,000, the
encoding would differ. This compose uses image defaults.

---

## CRUD walkthrough

Score formula matches SQL: `(user_id * 37) % 100`.

### INSERT (`ZADD` × 10,000)

```text
ZADD users:scores 37 "1"
ZADD users:scores 74 "2"
...
```

The demo pipelines the 10k writes.

For each member:

1. Dict insert `member → score` (rehash a few buckets if a resize is in
   progress).
2. Skip-list insert: random height, splice into each level by comparing
   `(score, member)`.

`ZCARD` must be **10000**. Duplicate `ZADD` of the same member would
overwrite the score and keep cardinality unchanged; the demo inserts
distinct members.

### Point UPDATE (`ZADD users:scores 42 "1"`)

Member `"1"` already exists (`score` 37). Redis:

1. Dict: update the score to 42.
2. Skip list: remove the node from its old `(37, "1")` position and
   re-insert at `(42, "1")`.

`ZSCORE users:scores 1` returns `42`. Cardinality stays 10000.

This is the Redis analog of the SQL point UPDATE. There is no undo chain
and no HOT vs index split: one single-threaded command mutates both
structures.

### Range (`ZRANGEBYSCORE users:scores 50 60`)

Walk the skip list from the first node with `score >= 50` until `score > 60`.
That is the same *sorted interval* idea as `score BETWEEN 50 AND 60`
(range-query family in the mapping table).

Match count is **1100** by the insert formula (11 integer scores × 100
members), independent of skip-list height. Captured **2026-08-26** against
Redis 7.4.11: `ZRANGEBYSCORE 50..60 count: 1100`.

### DELETE (`ZREM users:scores 2`)

Dict delete + skip-list delete. `ZCARD` becomes **9999**.

There is no VACUUM step: the command frees the node before the client gets
the reply. Compare [postgresql.md](postgresql.md), where `DELETE` leaves a
dead heap tuple until VACUUM.

---

## What this does *not* show

- **Hash-only CRUD.** A `HASH` would demonstrate the dict without a skip
  list, but it cannot serve `BETWEEN` without a scan of all fields.
- **Cluster hash slots / Redis Cluster.** One standalone process.
- **Measured ops/sec.** No invented throughput. `ZCARD` and range length
  are counts from the commands that were run.

Assertions in `redis_demo.py`: cardinality after insert == 10000; after one
`ZREM` == 9999.
