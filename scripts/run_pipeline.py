import logging
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

from sqlalchemy import text

import load_raw

SQL_DIR = Path("sql")

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("pipeline")


def run_sql_file(engine, filename):
    sql = (SQL_DIR / filename).read_text(encoding="utf-8")
    conn = engine.raw_connection()
    try:
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit()
    finally:
        conn.close()


def record(engine, run_id, step, status, started, finished, error=None):
    duration = round((finished - started).total_seconds(), 2)
    with engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO ops.pipeline_runs "
                "(run_id, step_name, status, started_at, finished_at, duration_seconds, error_message) "
                "VALUES (:run_id, :step, :status, :started, :finished, :duration, :error)"
            ),
            {
                "run_id": run_id, "step": step, "status": status,
                "started": started, "finished": finished,
                "duration": duration, "error": error,
            },
        )


def main():
    engine = load_raw.get_engine()
    run_sql_file(engine, "050_create_ops.sql")
    run_id = uuid.uuid4().hex[:8]

    steps = [
        ("load_raw", load_raw.main),
        ("build_staging", lambda: run_sql_file(engine, "020_create_staging.sql")),
        ("build_analytics", lambda: run_sql_file(engine, "030_create_analytics.sql")),
        ("build_metrics", lambda: run_sql_file(engine, "040_create_metrics.sql")),
    ]

    log.info("Pipeline run %s started", run_id)
    for name, func in steps:
        started = datetime.now(timezone.utc)
        log.info("Step %s: start", name)
        try:
            func()
        except Exception as exc:
            finished = datetime.now(timezone.utc)
            log.exception("Step %s: FAILED", name)
            record(engine, run_id, name, "failed", started, finished, str(exc)[:1000])
            sys.exit(1)
        finished = datetime.now(timezone.utc)
        record(engine, run_id, name, "success", started, finished)
        log.info("Step %s: success", name)
    log.info("Pipeline run %s finished", run_id)


if __name__ == "__main__":
    main()