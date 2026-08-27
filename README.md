# storage-engine

This repository demonstrates how InnoDB, PostgreSQL, and Redis behave for the
same `(user_id, score)` CRUD workload via runnable examples against real
containers — it does not reimplement engine internals.

## Landscape

| Engine | What stores a row / member | Point lookup | Range on `score` | Durability log | Versions / snapshots |
|---|---|---|---|---|---|
| **InnoDB** | Clustered B+ tree on `user_id` (row lives in the PK leaf) | Descend PK (sometimes adaptive hash) | Secondary B+ tree, then PK bookmark lookup | Redo (write-ahead) | Undo chain (`trx_id` / `roll_ptr`) |
| **PostgreSQL** | Heap (slotted 8 KiB pages) + btree indexes | PK btree → heap TID | Score btree → heap fetch; HOT if non-indexed columns change | WAL (`pg_wal`) | Heap tuple `xmin`/`xmax`; VACUUM reclaims |
| **Redis** zset | Dict (member→score) + skip list (score order) | `ZSCORE` via dict | `ZRANGEBYSCORE` via skip list | Optional AOF/RDB (not used in the demo) | Single-threaded command; no MVCC |
| **RocksDB** (context only) | LSM: memtable + SST files | Bloom filter + SST index / data block | Iterator over ordered keys | WAL + memtable flush | Sequence-number snapshots |
| **SQLite** (context only) | B-tree (rowid table, or clustered `WITHOUT ROWID`) | B-tree descent | B-tree range | Rollback journal or WAL mode | WAL readers see a snapshot; not InnoDB-style undo |

RocksDB and SQLite are listed for orientation. This repo does not ship
examples for them.

## Docs

- [docs/innodb.md](docs/innodb.md) — 16 KiB pages, clustered B+ tree, midpoint LRU, redo, undo/MVCC, AHI, change buffer
- [docs/postgresql.md](docs/postgresql.md) — slotted heap, B-link btree, HOT, VACUUM, WAL
- [docs/redis.md](docs/redis.md) — dict + skip list via `ZADD` / `ZSCORE` / `ZRANGEBYSCORE` / `ZREM`
- [LEETCODE_MAPPING.md](LEETCODE_MAPPING.md) — mechanism ↔ problem ↔ how the demo touches it

## How to run

Images are pinned in `docker-compose.yml` (`mysql:8.0`, `postgres:16`, `redis:7`).
Postgres is published on **5434** so it does not collide with a local 5432.
On 2026-08-26 those tags resolved to MySQL 8.0.46, PostgreSQL 16.14, and
Redis 7.4.11; `EXPLAIN` / `OBJECT ENCODING` output in `docs/` is from that run.

```bash
docker compose up -d
pip install -r requirements.txt
python examples/run_demos.py
```

The demo inserts **10,000** users (`score = (user_id * 37) % 100`), point-updates
one row, range-scans `score BETWEEN 50 AND 60`, and deletes one user. Docs also
show **page-layout arithmetic** for a 1,000,000-row table of the same schema;
that arithmetic is labeled as a calculation from documented page sizes, not as
a measured run.

Host / port overrides: `MYSQL_HOST`, `POSTGRES_HOST`, `REDIS_HOST` (default
`localhost`), plus `MYSQL_PORT` (3306), `POSTGRES_PORT` (5434), `REDIS_PORT`
(6379). GitHub Actions maps Postgres at 5432; see `.github/workflows/ci.yml`.

## Leftover sandbox

[`postgres_sample/`](postgres_sample/) is an older student/joins sandbox with
its own `compose.yaml` (Postgres on 5432). It is not the main demo. Prefer the
root `docker-compose.yml` and `examples/` for the storage-engine walkthrough.
Do not start both compose files if you need 5432/3306/6379 for something else.
