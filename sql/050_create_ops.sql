CREATE TABLE IF NOT EXISTS ops.pipeline_runs (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    run_id           TEXT NOT NULL,
    step_name        TEXT NOT NULL,
    status           TEXT NOT NULL CHECK (status IN ('success', 'failed')),
    started_at       TIMESTAMPTZ NOT NULL,
    finished_at      TIMESTAMPTZ NOT NULL,
    duration_seconds NUMERIC(10,2) NOT NULL,
    error_message    TEXT
);