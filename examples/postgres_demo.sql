-- PostgreSQL heap + btree CRUD demo against a real postgres:16 container.
-- This file does not reimplement PostgreSQL; it is a workload for the server.
--
-- Shared schema: (user_id INT PK, score INT, updated_at TIMESTAMP)
-- Score formula: (user_id * 37) % 100  → score BETWEEN 50 AND 60 matches 1,100 rows
-- (calculation from the insert formula, not a benchmark).
--
-- fillfactor=70 leaves free space on heap pages so a HOT update of a
-- non-indexed column can land on the same page. The default fillfactor of 100
-- packs pages and often forces a non-HOT update even when no indexed column
-- changes.
--
-- Connect to database storage_demo on host port 5434 (compose maps 5434:5432).
-- Example: psql "postgresql://demo:demo@127.0.0.1:5434/storage_demo" -f examples/postgres_demo.sql
--
-- No psql meta-commands: this file is also executed statement-by-statement
-- from examples/run_demos.py.

DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id     INTEGER NOT NULL,
    score       INTEGER NOT NULL,
    updated_at  TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id)
) WITH (fillfactor = 70);

CREATE INDEX idx_users_score ON users (score);

INSERT INTO users (user_id, score, updated_at)
SELECT
    g,
    (g * 37) % 100,
    TIMESTAMP '2026-01-01 00:00:00' + (g || ' seconds')::interval
FROM generate_series(1, 10000) AS g;

ANALYZE users;

-- Point UPDATE of one user. score is indexed, so this cannot be HOT:
-- a new heap tuple is written and both btree indexes get new entries.
UPDATE users
SET score = 42, updated_at = clock_timestamp()
WHERE user_id = 1;

-- Range scan on the score btree.
SELECT COUNT(*) AS range_count
FROM users
WHERE score BETWEEN 50 AND 60;

-- HOT-friendly UPDATE: only updated_at changes (not in any index).
-- Capture this plan for docs/postgresql.md.
EXPLAIN (ANALYZE, BUFFERS)
UPDATE users
SET updated_at = clock_timestamp()
WHERE user_id = 3;

-- Observable HOT counter (n_tup_hot_upd). PostgreSQL 15+ keeps these
-- counters in the backend until it disconnects (or a flush interval
-- elapses); run_demos.py reconnects before this statement.
SELECT
    n_tup_upd,
    n_tup_hot_upd,
    n_dead_tup
FROM pg_stat_user_tables
WHERE relname = 'users';

-- DELETE one user: xmax is set; index entries remain until VACUUM.
DELETE FROM users WHERE user_id = 2;

SELECT COUNT(*) AS row_count_after_delete FROM users;

-- VACUUM reclaims the dead tuple from the DELETE (and any non-HOT update debris).
VACUUM (VERBOSE, ANALYZE) users;

SELECT
    n_live_tup,
    n_dead_tup
FROM pg_stat_user_tables
WHERE relname = 'users';
