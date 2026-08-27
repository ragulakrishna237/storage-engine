# PostgreSQL: heap + btree for the same (user_id, score) CRUD

This document walks the shared `users` table through PostgreSQL’s heap,
btree (B-link) indexes, HOT updates, VACUUM, and WAL.

It is **not** a PostgreSQL reimplementation. The statements in
[`examples/postgres_demo.sql`](../examples/postgres_demo.sql) run against a
`postgres:16` container. Host port **5434** maps to container 5432 (see
`docker-compose.yml`).

Runnable demo size: **10,000 rows**. Any 1,000,000-row figures below are
**calculations from documented page layout**, not a measured run.

LeetCode tags: [LEETCODE_MAPPING.md](../LEETCODE_MAPPING.md).

---

## Schema

```sql
CREATE TABLE users (
    user_id     INTEGER NOT NULL,
    score       INTEGER NOT NULL,
    updated_at  TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id)
) WITH (fillfactor = 70);

CREATE INDEX idx_users_score ON users (score);
```

Unlike InnoDB, the table is a **heap** (unordered pages of tuples). The
primary key is a separate btree whose leaf entries point at heap TIDs
`(block_number, item_pointer)`.

`fillfactor = 70` is intentional for the HOT demo: the default heap
fillfactor of 100 packs pages so a same-page HOT update often cannot find
space, even when no indexed column changes.

Insert formula: `score = (user_id * 37) % 100`.

---

## Slotted heap page

Default `BLCKSZ` is **8 KiB** (8192 bytes). A heap page is a slotted page:

```
+----------------------+  offset 0
| PageHeaderData       |  24 bytes
+----------------------+
| ItemIdData ...       |  4-byte line pointers, grow downward
|         |            |
|         v            |
|   (free space)       |
|         ^            |
|         |            |
| HeapTupleHeader +    |  tuples grow upward from the end
|  column data         |
+----------------------+  offset 8192
```

`PageHeaderData` is 24 bytes. Each live tuple needs:

| Piece | Size |
|---|---|
| Line pointer (`ItemIdData`) | 4 bytes |
| `HeapTupleHeaderData` | 23 bytes |
| `user_id` int4 | 4 |
| `score` int4 | 4 |
| `updated_at` timestamp (no tz, 8-byte microsecond format) | 8 |
| Alignment to `MAXALIGN` (8 on 64-bit) | header+data 23+16=39 → **40** |

Per-tuple occupancy ≈ 4 + 40 = **44 bytes**. Usable payload ≈ `8192 − 24 = 8168`.
Tuples per packed page ≈ `8168 / 44 ≈ 185` at fillfactor 100.

### 1,000,000-row heap — calculation, not a measured run

At fillfactor 100: `1_000_000 / 185 ≈ 5,406` heap pages ≈ **42.2 MiB**.

At fillfactor 70 (what the demo uses): roughly `185 * 0.70 ≈ 130` tuples per
page → `1_000_000 / 130 ≈ 7,693` pages ≈ **60.1 MiB**. Extra space is what
makes HOT possible.

The **10,000-row** demo is ~77 pages at fillfactor 70 (`10000 / 130`), plus
btree pages for `PRIMARY` and `idx_users_score`.

Indexes are also 8 KiB pages, but they use the btree special space at the
end of the page (sibling pointers), not a heap tuple header.

---

## B-link / btree indexes

**LeetCode:** [704 Binary Search](https://leetcode.com/problems/binary-search/),
with a concurrency footnote.

PostgreSQL btree is a Lehman & Yao **B-link** tree: each page stores a
**high key** and a **right-link** to the next page at the same level. During
a split, a search that arrived at a page whose high key is now too small
follows the right-link instead of restarting at the root. That is how
readers avoid taking a lock on the parent during every split.

Point lookup `WHERE user_id = 1`:

1. Descend the PK btree (binary search within each page).
2. Leaf holds TID `(block, offset)` for `user_id = 1`.
3. Read that heap page, follow the line pointer, return the tuple if it is
   visible (`xmin`/`xmax` vs the snapshot).

Range `score BETWEEN 50 AND 60`:

1. Descend `idx_users_score` to the first leaf key `>= 50`.
2. Scan right (including via right-links) while `score <= 60`.
3. Collect TIDs, then fetch heap tuples (often an index-only scan is
   **not** possible here: `COUNT(*)` can be index-only if the visibility map
   says the page is all-visible; `SELECT *` cannot).

Expected matches in the 10k demo: **1,100** (11 score residues × 100 rows),
from the insert formula.

---

## HOT updates

**LeetCode:** in-place vs copy-on-write — **conceptual**, no single problem.

A Heap-Only Tuple update is allowed when:

1. No **indexed** column changes, and
2. The new tuple **fits on the same heap page**.

Then Postgres:

- Inserts the new tuple on that page.
- Sets the old tuple’s `t_ctid` to point at the new item (HOT chain).
- **Does not** insert new btree entries. Existing index entries still
  point at the original line pointer; heap fetch follows the chain.

Updating `score` **cannot** be HOT (`idx_users_score` and, if uniqueness
matters, the PK still identifies the row but `score` itself is indexed).
Updating only `updated_at` **can** be HOT.

The demo:

1. `UPDATE ... SET score = 42 ... WHERE user_id = 1` — not HOT.
2. `UPDATE ... SET updated_at = clock_timestamp() WHERE user_id = 3` — HOT
   if fillfactor left space (hence `fillfactor = 70`).

Captured **2026-08-26** against PostgreSQL 16.14: `n_tup_upd = 2`,
`n_tup_hot_upd = 1`. The non-indexed `updated_at` update was HOT; the
indexed `score` update was not.

`pg_stat_user_tables.n_tup_hot_upd` is the counter
`examples/run_demos.py` asserts is `>= 1`. PostgreSQL 15+ keeps those
counters in the backend until disconnect; the orchestrator reconnects
before reading them.

---

## WAL

**LeetCode:** **no perfect analog** (same note as InnoDB redo).

PostgreSQL appends WAL to `pg_wal` before a heap/index page is flushed.
`full_page_writes` (on by default) logs a full page image the first time a
page is dirtied after a checkpoint, to survive torn writes.

- Heap INSERT: heap WAL + WAL for each index insert.
- Non-HOT UPDATE: heap WAL (old+new) + WAL for index entries that change.
- HOT UPDATE: heap WAL only — **no index WAL**. That is the I/O reason HOT
  exists.
- DELETE: heap WAL (set `xmax`); index entries stay until VACUUM, so DELETE
  does not emit per-index-delete WAL the way a btree `DELETE` key would.

This repo does not dump WAL records. The HOT vs non-HOT distinction is
observable via `n_tup_hot_upd` and via `EXPLAIN (ANALYZE, BUFFERS)` on the
HOT `UPDATE`.

---

## VACUUM

**LeetCode:** no perfect analog (reclamation / GC).

PostgreSQL UPDATE/DELETE do not immediately reuse tuple slots.

- Dead heap tuples stay until **VACUUM** (or HOT pruning on a later heap
  page access).
- Index entries that point at dead tuples stay until VACUUM walks the
  indexes (HOT chains are an exception: indexes never pointed at the
  newer HOT tuples, so VACUUM’s index cleanup is lighter for pure-HOT
  updates).
- `VACUUM` (not `VACUUM FULL`) is concurrent: it reclaims space for the
  same table, it does not rewrite the whole heap.
- Freeze of old `xmin` is a separate VACUUM duty (wraparound). The 10k
  demo will not wrap `xid`.

The demo ends with `VACUUM (VERBOSE, ANALYZE) users` after deleting
`user_id = 2`.

---

## READ / UPDATE / DELETE / VACUUM walkthrough

### INSERT 10,000 rows

Heap: tuples appended, pages filled to ~70%. PK btree and score btree each
get 10,000 leaf entries. WAL for heap + both indexes. `ANALYZE users`
updates planner statistics (not the same as `VACUUM ANALYZE`).

### READ — point and range

- Point: PK btree → one heap page (hopefully already in `shared_buffers`
  after the insert).
- Range: score btree leaf walk, then heap fetches. Score order is not heap
  order, so this is not a sequential heap scan.

Row count for `score BETWEEN 50 AND 60` is **1100** by construction.

I/O counts belong in `EXPLAIN (ANALYZE, BUFFERS)` output from a real run
(shared vs read buffers). They are **not** estimated in this section.

### UPDATE — indexed column (`user_id = 1`, new `score`)

1. Fetch heap tuple via PK.
2. Set `xmax` on the old tuple; insert a new heap tuple (often the same
   page if there is space, but **indexes still change**).
3. Insert new PK entry? PK column `user_id` is unchanged, so the PK btree
   can use HOT **only if** no indexed column changed — but `score` *did*
   change, so HOT is disallowed. New index entries for both indexes; old
   ones remain until VACUUM.
4. WAL for heap and indexes.

### UPDATE — HOT (`user_id = 3`, only `updated_at`)

1. Same heap page, new tuple, `t_ctid` redirect.
2. No btree inserts.
3. `n_tup_hot_upd` increments.

### DELETE (`user_id = 2`)

Sets `xmax`. Heap slot and index entries remain. `COUNT(*)` becomes
**9999** because the snapshot does not see the deleted tuple. `n_dead_tup`
stays non-zero until VACUUM.

### VACUUM

Reclaims the delete (and the non-HOT update’s dead tuple). HOT chain for
user 3 can be pruned so the line pointer refers to the latest tuple
directly.

---

## HOT-update `EXPLAIN (ANALYZE, BUFFERS)`

SQL captured by the demo (and by `psql -f examples/postgres_demo.sql`):

```sql
EXPLAIN (ANALYZE, BUFFERS)
UPDATE users
SET updated_at = clock_timestamp()
WHERE user_id = 3;
```

Captured **2026-08-26** against **PostgreSQL 16.14** (image `postgres:16` as
resolved that day). `EXPLAIN` does not print the word HOT; the HOT evidence
from the same run is `pg_stat_user_tables`: `n_tup_upd = 2`,
`n_tup_hot_upd = 1`, `n_dead_tup = 2` (the non-HOT score change plus the
HOT `updated_at` change). After `VACUUM (VERBOSE, ANALYZE)`, `n_dead_tup = 0`
and `n_live_tup = 9998` — that live count is ANALYZE’s **estimate**
(`reltuples`); `COUNT(*)` after the delete was **9999**.

```
Update on users  (cost=0.29..8.31 rows=0 width=0) (actual time=0.070..0.071 rows=0 loops=1)
  Buffers: shared hit=5
  ->  Index Scan using users_pkey on users  (cost=0.29..8.31 rows=1 width=14) (actual time=0.036..0.037 rows=1 loops=1)
        Index Cond: (user_id = 3)
        Buffers: shared hit=3
Planning Time: 0.112 ms
Execution Time: 0.219 ms
```

Reading the plan: the `UPDATE` found the row with an **index scan on
`users_pkey`** (`user_id = 3`), then updated the heap. `Buffers: shared hit=5`
(3 of them on the index scan) means those pages were already in
`shared_buffers` — no disk reads on this run. `actual ... rows=0` on the
`Update` node is normal: `UPDATE` returns no result rows; the scan node
under it shows `rows=1`. Times are from this capture only; they will move
on the next run.
