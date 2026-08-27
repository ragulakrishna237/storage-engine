"""Sorted-set CRUD against a real Redis process (dict + skiplist internally).

This script does not reimplement Redis. It issues ZADD / ZSCORE /
ZRANGEBYSCORE / ZREM on a live server so the same (user_id, score) dataset
used by the SQL demos can be observed on a skip list + hash table.

Key: users:scores
  member = str(user_id), score = (user_id * 37) % 100
"""

from __future__ import annotations

import os
import sys

import redis


N_ROWS = 10_000
ZSET_KEY = "users:scores"


def connect(host: str | None = None, port: int | None = None) -> redis.Redis:
    host = host or os.environ.get("REDIS_HOST", "localhost")
    port = int(os.environ.get("REDIS_PORT", str(port or 6379)))
    return redis.Redis(host=host, port=port, decode_responses=True)


def run(client: redis.Redis | None = None) -> dict[str, int]:
    r = client or connect()
    r.delete(ZSET_KEY)

    pipe = r.pipeline(transaction=False)
    for user_id in range(1, N_ROWS + 1):
        pipe.zadd(ZSET_KEY, {str(user_id): (user_id * 37) % 100})
    pipe.execute()

    card_after_insert = int(r.zcard(ZSET_KEY))
    print(f"ZCARD after insert: {card_after_insert}")
    assert card_after_insert == N_ROWS, (
        f"expected ZCARD {N_ROWS} after insert, got {card_after_insert}"
    )

    # Point UPDATE: ZADD on an existing member overwrites the score.
    r.zadd(ZSET_KEY, {"1": 42})
    updated_score = r.zscore(ZSET_KEY, "1")
    print(f"ZSCORE user_id=1 after update: {updated_score}")

    range_members = r.zrangebyscore(ZSET_KEY, 50, 60)
    print(f"ZRANGEBYSCORE 50..60 count: {len(range_members)}")

    r.zrem(ZSET_KEY, "2")
    card_after_delete = int(r.zcard(ZSET_KEY))
    print(f"ZCARD after ZREM: {card_after_delete}")
    assert card_after_delete == N_ROWS - 1, (
        f"expected ZCARD {N_ROWS - 1} after one ZREM, got {card_after_delete}"
    )

    encoding = r.object("encoding", ZSET_KEY)
    print(f"OBJECT ENCODING {ZSET_KEY}: {encoding}")

    return {
        "card_after_insert": card_after_insert,
        "range_count": len(range_members),
        "card_after_delete": card_after_delete,
    }


def main() -> int:
    run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
