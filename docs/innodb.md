# InnoDB: how the (user_id, score) CRUD lands on disk

This document walks one table through InnoDB’s real structures: a clustered
B+ tree, 16 KiB pages, the buffer pool, redo WAL, undo/MVCC, the adaptive
hash index, and the change buffer.

It is **not** an InnoDB reimplementation. The statements in
[`examples/innodb_demo.sql`](../examples/innodb_demo.sql) run against a
MySQL 8.0 container (`mysql:8.0` in `docker-compose.yml`). What follows is
how that engine is documented to behave for this schema.

Runnable demo size: **10,000 rows**. Layout arithmetic below for
**1,000,000 rows** is a **calculation from documented constants** (16 KiB
pages, COMPACT/DYNAMIC record headers). It is not a measured `EXPLAIN` or
a benchmark.

LeetCode tags in each section point at [LEETCODE_MAPPING.md](../LEETCODE_MAPPING.md).

---

## Schema

```sql
CREATE TABLE users (
    user_id     INT NOT NULL,
    score       INT NOT NULL,
    updated_at  TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id),
    KEY idx_users_score (score)
) ENGINE=InnoDB;
```

- Clustered index (`PRIMARY`): B+ tree on `user_id`. **The row lives in this tree.**
- Secondary index `idx_users_score`: B+ tree on `score`, with `user_id` appended
  as the row pointer (InnoDB does not store a heap TID).

Insert formula used by the demo: `score = (user_id * 37) % 100`.

---

## Physical layout math (16 KiB pages, clustered PK B+ tree)

**LeetCode:** [704 Binary Search](https://leetcode.com/problems/binary-search/) —
searching a sorted leaf is the same *ordered comparison* idea; the tree is a
hierarchy of pages, not a single array.

InnoDB’s default page size is **16 KiB** (`innodb_page_size = 16384`). Every
index, including the clustered table, is a B+ tree of these pages.

### Page overhead (documented layout)

| Region | Size |
|---|---|
| File header (`FIL` header) | 38 bytes |
| Page header | 56 bytes |
| Infimum + supremum system records (COMPACT) | 26 bytes |
| File trailer (checksum + LSN) | 8 bytes |
| **Fixed overhead** | **128 bytes** |
| Bytes left for user records + page directory | 16,384 − 128 = **16,256** |

The page directory stores a 2-byte slot per ~4–8 records. Treat that as
roughly **0.5 bytes/row** extra for this arithmetic.

### Clustered leaf record for this schema

Default row format in MySQL 8.0 is `DYNAMIC` (same on-page header as
`COMPACT` for these fixed-width columns). A clustered record carries
transaction metadata that secondary-index records do not:

| Field | Bytes |
|---|---|
| Record header | 5 |
| `trx_id` | 6 |
| `roll_ptr` | 7 |
| `user_id` INT | 4 |
| `score` INT | 4 |
| `updated_at` TIMESTAMP (no fractional seconds) | 4 |
| **Total** | **30** |

No off-page overflow: nothing here approaches the 768-byte prefix / overflow
threshold.

Rows per clustered leaf ≈ `16256 / (30 + 0.5) ≈ 533`.

### 1,000,000-row table — calculation, not a measured run

| Quantity | Calculation |
|---|---|
| Clustered leaf pages | `1_000_000 / 533 ≈ 1,876` pages |
| Clustered leaf bytes | `1,876 × 16,384 ≈ 30.7 MiB` |
| Internal-node record (header + INT key + 4-byte child page number) | ~13–14 bytes |
| Fanout | `16256 / 14 ≈ 1,160` children per internal page |
| Height | 1,876 leaves fit under two internal pages plus a root → **height 3** (root, internal, leaf) |

A **10,000-row** demo is ~`10000 / 533 ≈ 19` clustered leaf pages, typically
height 2 (root + leaves).

### Secondary index `idx_users_score`

Secondary leaves store `(score, user_id)` plus a 5-byte header. They do
**not** store `trx_id` / `roll_ptr`.

| Field | Bytes |
|---|---|
| Record header | 5 |
| `score` | 4 |
| `user_id` (PK appended) | 4 |
| **Total** | **13** |

Rows per secondary leaf ≈ `16256 / 13.5 ≈ 1,204`.

For 1,000,000 rows (calculation): `1_000_000 / 1204 ≈ 830` secondary leaf
pages ≈ **13 MiB**.

`SELECT *` on a score range is **not covering**: InnoDB range-scans the
secondary leaves, then does a clustered lookup per `user_id` (bookmark
lookup).

---

## B+ tree descent

**LeetCode:** 704 Binary Search.

Point lookup `WHERE user_id = 1`:

1. Latch the root page of `PRIMARY`.
2. Binary-search the page directory / records for the child whose key range
   contains `1`.
3. Repeat on the child until a leaf.
4. Binary-search the leaf for `user_id = 1` and return the clustered record
   (`score`, `updated_at`, hidden `trx_id` / `roll_ptr`).

Because user_ids in the demo are inserted **in order** (1..10000), the
rightmost leaf absorbs almost every clustered insert. That is sequential
page allocation, not random leaf splits. The **score** secondary index is
the opposite: `(user_id * 37) % 100` scatters keys across ~100 score values,
so those inserts hit many leaves.

Range `score BETWEEN 50 AND 60`:

1. Descend `idx_users_score` to the first leaf key `>= 50`.
2. Walk right-leaf links while `score <= 60` (B+ trees chain leaves).
3. For each `(score, user_id)`, look up the clustered record if the query
   needs `updated_at`.

From the insert formula, residues 50..60 inclusive are 11 values × 100 rows
= **1,100 matches** in 10,000 rows. That number is determined by the data
generator, not by a timing run.

---

## Buffer pool midpoint LRU

**LeetCode:** [146 LRU Cache](https://leetcode.com/problems/lru-cache/) —
same eviction idea (keep recently used pages), **different insertion rule**.

InnoDB does not cache rows; it caches **pages** in the buffer pool.

Textbook LRU inserts a newly read page at the head of the list. A full
index scan would then evict every useful page. InnoDB splits the LRU into
a **young** (new) sublist and an **old** sublist:

- `innodb_old_blocks_pct` default **37%** of the list is “old.”
- A page read from disk is inserted at the **midpoint**, on the old side.
- A second access after `innodb_old_blocks_time` (default **1000 ms**)
  promotes it to the young half.
- Eviction still happens at the tail of the old half.

The 10k insert dirties clustered leaves (right-hand page) and many score
index pages. The later PK lookup and range scan may find those pages still
resident. This document does not invent hit-rate numbers; `SHOW ENGINE
INNODB STATUS` / Performance Schema would be the way to measure them after
a run.

---

## WAL (redo) write path

**LeetCode:** **no perfect analog.** Sequential append plus a later page
flush is not an LC problem. See the WAL row in
[LEETCODE_MAPPING.md](../LEETCODE_MAPPING.md).

InnoDB is write-ahead:

1. A mini-transaction (mtr) modifies a page in the buffer pool and appends
   redo to the **log buffer**.
2. Commit durability depends on `innodb_flush_log_at_trx_commit` (default
   `1`: flush redo to the redo log at commit).
3. The dirty page may remain in the buffer pool. A checkpoint later writes
   it (via the flush list, ordered by oldest LSN). The **doublewrite** batch
   exists so a torn 16 KiB page can be recovered.

So an `UPDATE` of `users.score` does **not** mean “fsync that heap page
before commit.” It means “fsync the redo that describes the change.” Crash
recovery replays redo from the last checkpoint.

The demo’s INSERT/UPDATE/DELETE all generate redo. This repo does not parse
redo files.

---

## MVCC undo-chain walk

**LeetCode:** [206](https://leetcode.com/problems/reverse-linked-list/) /
[141](https://leetcode.com/problems/linked-list-cycle/) as a **pointer-chase
analogy, not identity**. Undo is a version log; visibility uses a Read View.

Each clustered record stores:

- `trx_id` — which transaction last modified it
- `roll_ptr` — pointer into the **undo log** (undo tablespace)

Default isolation is `REPEATABLE READ`. A consistent read builds a
**Read View** (the set of active transaction ids). If the row’s `trx_id` is
not visible:

1. Follow `roll_ptr` to the undo record (previous column values + previous
   `roll_ptr`).
2. Repeat until a version visible to this Read View is found, or the chain
   ends (row not visible → no match).

That is a linked walk. It is **not** reversing a list and **not** cycle
detection; purge eventually truncates old undo once no Read View needs it.

- **INSERT:** insert-undo exists until commit, then can be discarded (the
  row itself is the new version).
- **UPDATE** of user 1: in-place clustered update (INT→INT, same size),
  `trx_id` replaced, `roll_ptr` points at undo that still has `score = 37`.
  The secondary index delete-marks `(37, 1)` and inserts `(42, 1)`.
- **DELETE** of user 2: the clustered record is delete-marked, not
  physically removed. **Purge** later removes it and the secondary entries
  once no snapshot needs the old version.

PostgreSQL does this differently (see [postgresql.md](postgresql.md)): old
versions stay on the heap (`xmin`/`xmax`) instead of an undo chain.

---

## Adaptive hash index

**LeetCode:** [1 Two Sum](https://leetcode.com/problems/two-sum/) /
[706 Design HashMap](https://leetcode.com/problems/design-hashmap/).

The AHI is an **in-memory** hash table from search key → cached B+ tree
leaf record, built for pages that see repeated point lookups. It is not
durable and is invalidated when the underlying leaf splits or the record
moves.

`innodb_adaptive_hash_index` defaults to ON in 8.0. A single
`WHERE user_id = 1` after a cold insert may still walk the B+ tree; AHI
helps **repeated** point reads of hot keys. `EXPLAIN` will still show the
PK lookup; it does not reliably advertise AHI. Do not invent a “AHI hit”
metric here.

---

## Change buffer

**LeetCode:** no clean analog (deferred secondary-index maintenance).

If a **secondary** index page is not in the buffer pool, InnoDB may record
the insert/delete-mark/purge in the **change buffer** (historically the
insert buffer) and merge when that page is later read. This avoids a random
read of the secondary leaf just to apply one update.

- Clustered (PK) changes are **never** change-buffered: the row page must
  be present.
- Non-unique secondary indexes (`idx_users_score`) are the usual
  beneficiaries.
- Unique secondary indexes are more restricted because uniqueness may
  require seeing the page.

Sequential PK inserts of `user_id` 1..10000 therefore dirty clustered
pages immediately. Score-index inserts are the ones that *may* land in the
change buffer when those leaves are cold.

---

## CRUD walkthrough for this table

Assume a fresh `users` table, then the demo sequence.

### INSERT 10,000 users

For `user_id = n`, `score = (n * 37) % 100`, `updated_at` staggered by `n`
seconds from `2026-01-01`.

| Structure | What happens |
|---|---|
| Clustered B+ tree | Append-ish inserts into the rightmost leaf; occasional leaf split when the page fills (~533 rows). Redo + insert-undo. |
| `idx_users_score` | Insert `(score, n)` into a leaf chosen by score. More random than the PK. Eligible for the change buffer. |
| Buffer pool | Rightmost clustered leaf stays hot. Score leaves churn more. Midpoint LRU: first touch goes to the old sublist. |
| WAL | One (or more) redo records per page change, flushed per commit settings. |

### Point UPDATE (`user_id = 1`, `score = 42`)

1. Descend clustered index (or AHI if hot) to the leaf with `user_id = 1`.
2. Old score is `(1 * 37) % 100 = 37`. New score `42` is the same 4 bytes →
   in-place clustered update.
3. Write undo (old `score`, old `trx_id`) and set a new `roll_ptr`.
4. Secondary: delete-mark `(37, 1)`, insert `(42, 1)`.
5. Redo describes both the clustered page change and the secondary changes.

A concurrent `REPEATABLE READ` transaction whose Read View predates this
update still sees `score = 37` by walking undo.

### Range scan (`score BETWEEN 50 AND 60`)

1. Descend `idx_users_score` to 50, scan leaves through 60 (**range scan** /
   sorted-interval walk; LC range-query family).
2. 1,100 secondary records (formula, not a timed benchmark).
3. Each `SELECT *` does a clustered PK lookup. That is nested-loops from
   secondary leaf → clustered leaf — many random clustered pages if the PK
   order and score order disagree (they do: score is `n * 37 % 100`).

Captured `EXPLAIN FORMAT=TREE` from **2026-08-26** against **MySQL 8.0.46**
(image `mysql:8.0` as resolved that day):

PK lookup (`WHERE user_id = 1`):

```
-> Rows fetched before execution  (cost=0..0 rows=1)
```

MySQL 8.0 TREE format reports a unique PK equality as a **const** table: the
clustered record is read once before the iterator plan. That is still a
PRIMARY lookup, not a table scan.

Range (`score BETWEEN 50 AND 60`):

```
-> Index range scan on users using idx_users_score over (50 <= score <= 60), with index condition: (users.score between 50 and 60)  (cost=495 rows=1100)
```

`rows=1100` is the optimizer’s estimate and happens to match the insert
formula. `cost=495` is also an optimizer number from this EXPLAIN, not a
wall-clock measurement. The plan confirms a secondary-index **range scan**
on `idx_users_score`. Do not treat 1,100 as an I/O count.

### DELETE (`user_id = 2`)

1. Clustered lookup, delete-mark the record, undo for rollback/MVCC.
2. Secondary delete-mark for `(score_of_2, 2)` where `score_of_2 = 74`.
3. Row count becomes **9,999**. Purge later physically reclaims.

---

## What the SQL example asserts

[`examples/run_demos.py`](../examples/run_demos.py) checks:

- `COUNT(*)` for `score BETWEEN 50 AND 60` = **1100**
- `COUNT(*)` after the delete = **9999**

Those are generator/row-count checks, not latency numbers.
