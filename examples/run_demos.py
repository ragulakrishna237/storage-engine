"""Run the InnoDB, PostgreSQL, and Redis demos against live containers.

This orchestrator does not reimplement engine internals. It waits for the
servers started by docker-compose.yml (or CI service containers), executes
the example workloads, and asserts observable counts.

Environment (defaults match docker-compose.yml):
  MYSQL_HOST, MYSQL_PORT (3306), MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE
  POSTGRES_HOST, POSTGRES_PORT (5434), POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
  REDIS_HOST, REDIS_PORT (6379)

GitHub Actions maps Postgres at 5432; set POSTGRES_PORT accordingly.
"""

from __future__ import annotations

import os
import sys
import time
from pathlib import Path

import mysql.connector
import psycopg2
import redis as redis_lib

EXAMPLES_DIR = Path(__file__).resolve().parent
if str(EXAMPLES_DIR) not in sys.path:
    sys.path.insert(0, str(EXAMPLES_DIR))

from redis_demo import run as run_redis_demo  # noqa: E402

INNODB_SQL = EXAMPLES_DIR / "innodb_demo.sql"
POSTGRES_SQL = EXAMPLES_DIR / "postgres_demo.sql"

WAIT_SECONDS = 90
WAIT_INTERVAL = 2

RANGE_COUNT_EXPECTED = 1100  # 11 residues * 100 rows; from the insert formula
N_ROWS = 10_000


def _env(name: str, default: str) -> str:
    return os.environ.get(name, default)


def mysql_kwargs() -> dict:
    return {
        "host": _env("MYSQL_HOST", "localhost"),
        "port": int(_env("MYSQL_PORT", "3306")),
        "user": _env("MYSQL_USER", "demo"),
        "password": _env("MYSQL_PASSWORD", "demo"),
        "database": _env("MYSQL_DATABASE", "storage_demo"),
    }


def postgres_kwargs() -> dict:
    return {
        "host": _env("POSTGRES_HOST", "localhost"),
        "port": int(_env("POSTGRES_PORT", "5434")),
        "user": _env("POSTGRES_USER", "demo"),
        "password": _env("POSTGRES_PASSWORD", "demo"),
        "dbname": _env("POSTGRES_DB", "storage_demo"),
    }


def redis_kwargs() -> dict:
    return {
        "host": _env("REDIS_HOST", "localhost"),
        "port": int(_env("REDIS_PORT", "6379")),
        "decode_responses": True,
    }


def split_sql(text: str) -> list[str]:
    statements: list[str] = []
    current: list[str] = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("--") or stripped.startswith("#"):
            continue
        current.append(line)
        if stripped.endswith(";"):
            stmt = "\n".join(current).strip().rstrip(";").strip()
            if stmt:
                statements.append(stmt)
            current = []
    tail = "\n".join(current).strip().rstrip(";").strip()
    if tail:
        statements.append(tail)
    return statements


def wait_for_mysql() -> None:
    deadline = time.time() + WAIT_SECONDS
    last_err: Exception | None = None
    while time.time() < deadline:
        try:
            conn = mysql.connector.connect(**mysql_kwargs(), connection_timeout=3)
            conn.close()
            print("MySQL is accepting connections.")
            return
        except Exception as exc:  # noqa: BLE001 — retry until timeout
            last_err = exc
            time.sleep(WAIT_INTERVAL)
    raise RuntimeError(f"MySQL did not become ready within {WAIT_SECONDS}s: {last_err}")


def wait_for_postgres() -> None:
    deadline = time.time() + WAIT_SECONDS
    last_err: Exception | None = None
    while time.time() < deadline:
        try:
            conn = psycopg2.connect(**postgres_kwargs(), connect_timeout=3)
            conn.close()
            print("PostgreSQL is accepting connections.")
            return
        except Exception as exc:  # noqa: BLE001
            last_err = exc
            time.sleep(WAIT_INTERVAL)
    raise RuntimeError(f"PostgreSQL did not become ready within {WAIT_SECONDS}s: {last_err}")


def wait_for_redis() -> None:
    deadline = time.time() + WAIT_SECONDS
    last_err: Exception | None = None
    client = redis_lib.Redis(**redis_kwargs())
    while time.time() < deadline:
        try:
            client.ping()
            print("Redis is accepting connections.")
            return
        except Exception as exc:  # noqa: BLE001
            last_err = exc
            time.sleep(WAIT_INTERVAL)
    raise RuntimeError(f"Redis did not become ready within {WAIT_SECONDS}s: {last_err}")


def run_mysql_demo() -> dict[str, int]:
    print("\n=== InnoDB / MySQL ===")
    statements = split_sql(INNODB_SQL.read_text(encoding="utf-8"))
    conn = mysql.connector.connect(**mysql_kwargs())
    conn.autocommit = True
    cur = conn.cursor(buffered=True)
    range_count = None
    row_count_after_delete = None
    try:
        for stmt in statements:
            print(f"-- {stmt.splitlines()[0][:80]}")
            cur.execute(stmt)
            if cur.with_rows:
                rows = cur.fetchall()
                columns = [d[0] for d in cur.description] if cur.description else []
                for row in rows:
                    if len(columns) == 1:
                        print("   ", row[0])
                    else:
                        print("   ", dict(zip(columns, row)) if columns else row)
                if columns and "range_count" in columns and rows:
                    range_count = int(rows[0][0])
                if columns and "row_count_after_delete" in columns and rows:
                    row_count_after_delete = int(rows[0][0])
    finally:
        cur.close()
        conn.close()

    assert range_count == RANGE_COUNT_EXPECTED, (
        f"InnoDB range count: expected {RANGE_COUNT_EXPECTED}, got {range_count}"
    )
    assert row_count_after_delete == N_ROWS - 1, (
        f"InnoDB row count after delete: expected {N_ROWS - 1}, got {row_count_after_delete}"
    )
    return {
        "range_count": range_count,
        "row_count_after_delete": row_count_after_delete,
    }


def run_postgres_demo() -> dict[str, int]:
    print("\n=== PostgreSQL ===")
    statements = split_sql(POSTGRES_SQL.read_text(encoding="utf-8"))
    conn = psycopg2.connect(**postgres_kwargs())
    conn.autocommit = True
    cur = conn.cursor()
    range_count = None
    row_count_after_delete = None
    hot_upd = None
    try:
        for stmt in statements:
            print(f"-- {stmt.splitlines()[0][:80]}")
            # PG 15+ keeps per-backend counters in local memory. A disconnect
            # forces a flush into shared pg_stat_* (idle wait does not, if
            # pgstat_report_stat skipped due to the 1s min interval).
            if "pg_stat_user_tables" in stmt:
                cur.close()
                conn.close()
                conn = psycopg2.connect(**postgres_kwargs())
                conn.autocommit = True
                cur = conn.cursor()
            cur.execute(stmt)
            if cur.description:
                rows = cur.fetchall()
                columns = [d[0] for d in cur.description]
                for row in rows:
                    if columns == ["QUERY PLAN"] or (
                        len(columns) == 1 and columns[0].lower() in {"query plan", "explain"}
                    ):
                        print(row[0])
                    else:
                        print("   ", dict(zip(columns, row)))
                if "range_count" in columns and rows:
                    range_count = int(rows[0][0])
                if "row_count_after_delete" in columns and rows:
                    row_count_after_delete = int(rows[0][0])
                if "n_tup_hot_upd" in columns and rows:
                    hot_upd = int(rows[0][columns.index("n_tup_hot_upd")])
    finally:
        cur.close()
        conn.close()

    assert range_count == RANGE_COUNT_EXPECTED, (
        f"PostgreSQL range count: expected {RANGE_COUNT_EXPECTED}, got {range_count}"
    )
    assert row_count_after_delete == N_ROWS - 1, (
        f"PostgreSQL row count after delete: expected {N_ROWS - 1}, got {row_count_after_delete}"
    )
    assert hot_upd is not None and hot_upd >= 1, (
        f"PostgreSQL n_tup_hot_upd: expected >= 1 after the non-indexed UPDATE, got {hot_upd}"
    )
    return {
        "range_count": range_count,
        "row_count_after_delete": row_count_after_delete,
        "n_tup_hot_upd": hot_upd,
    }


def main() -> int:
    print("Waiting for MySQL, PostgreSQL, and Redis...")
    wait_for_mysql()
    wait_for_postgres()
    wait_for_redis()

    mysql_stats = run_mysql_demo()
    postgres_stats = run_postgres_demo()

    print("\n=== Redis ===")
    client = redis_lib.Redis(**redis_kwargs())
    redis_stats = run_redis_demo(client)

    print("\n=== assertions passed ===")
    print(f"InnoDB:    {mysql_stats}")
    print(f"Postgres:  {postgres_stats}")
    print(f"Redis:     {redis_stats}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
