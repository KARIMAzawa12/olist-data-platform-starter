import pytest
from sqlalchemy import text

import load_raw


@pytest.fixture(scope="session")
def engine():
    eng = load_raw.get_engine()
    try:
        with eng.connect() as conn:
            conn.execute(text("SELECT 1"))
    except Exception as exc:
        pytest.skip(f"Database unavailable: {exc}")
    return eng


@pytest.fixture
def scalar(engine):
    def run(sql):
        with engine.connect() as conn:
            return conn.execute(text(sql)).scalar()
    return run