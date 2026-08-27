-- InnoDB CRUD demo against a real MySQL 8.0 container (ENGINE=InnoDB).
-- This file does not reimplement InnoDB; it is a workload for the server.
--
-- Shared schema: (user_id INT PK, score INT, updated_at TIMESTAMP)
-- Score formula: (user_id * 37) % 100  → scores 0..99, 100 rows per residue
-- in 10,000 inserts, so score BETWEEN 50 AND 60 matches 11 * 100 = 1,100 rows
-- (calculation from the insert formula, not a benchmark).
--
-- Connect to database storage_demo (created by docker-compose.yml).
-- Example: mysql -h 127.0.0.1 -P 3306 -u demo -pdemo storage_demo < examples/innodb_demo.sql

DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id     INT NOT NULL,
    score       INT NOT NULL,
    updated_at  TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id),
    KEY idx_users_score (score)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- MySQL 8.0 default cte_max_recursion_depth is 1000.
SET SESSION cte_max_recursion_depth = 10000;

INSERT INTO users (user_id, score, updated_at)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10000
)
SELECT
    n,
    (n * 37) % 100,
    TIMESTAMP('2026-01-01 00:00:00') + INTERVAL n SECOND
FROM seq;

ANALYZE TABLE users;

-- Point UPDATE of one user (clustered PK lookup; secondary index on score must change).
UPDATE users
SET score = 42, updated_at = CURRENT_TIMESTAMP
WHERE user_id = 1;

-- Range scan on the secondary index.
SELECT COUNT(*) AS range_count
FROM users
WHERE score BETWEEN 50 AND 60;

-- PK point lookup plan.
EXPLAIN FORMAT=TREE
SELECT * FROM users WHERE user_id = 1;

-- Secondary-index range plan (SELECT * is not covering: bookmark lookups into the clustered index).
EXPLAIN FORMAT=TREE
SELECT * FROM users WHERE score BETWEEN 50 AND 60;

-- DELETE one user (delete-mark; purge happens later).
DELETE FROM users WHERE user_id = 2;

SELECT COUNT(*) AS row_count_after_delete FROM users;
