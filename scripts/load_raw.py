import os
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

RAW_DIR = Path("data/raw")
CHUNK_SIZE = 50_000

# CSV file name -> raw table name
TABLES = {
    "olist_customers_dataset.csv": "customers",
    "olist_geolocation_dataset.csv": "geolocation",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
    "olist_orders_dataset.csv": "orders",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "product_category_name_translation.csv": "product_category_translation",
}


def get_engine():
    load_dotenv()
    url = URL.create(
        "postgresql+psycopg2",
        username=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
        host="localhost",
        port=int(os.environ["POSTGRES_PORT"]),
        database=os.environ["POSTGRES_DB"],
    )
    return create_engine(url)


def load_table(engine, csv_name, table):
    path = RAW_DIR / csv_name
    if not path.exists():
        raise FileNotFoundError(f"Missing source file: {path}")

    loaded_at = datetime.now(timezone.utc)
    first_chunk = True
    total = 0

    for chunk in pd.read_csv(path, dtype=str, chunksize=CHUNK_SIZE):
        chunk["_source_file"] = csv_name
        chunk["_loaded_at"] = loaded_at
        chunk.to_sql(
            table,
            engine,
            schema="raw",
            if_exists="replace" if first_chunk else "append",
            index=False,
        )
        first_chunk = False
        total += len(chunk)

    return total


def main():
    engine = get_engine()
    for csv_name, table in TABLES.items():
        rows = load_table(engine, csv_name, table)
        with engine.connect() as conn:
            in_db = conn.execute(text(f"SELECT COUNT(*) FROM raw.{table}")).scalar()
        status = "OK" if rows == in_db else "MISMATCH"
        print(f"{status} raw.{table}: csv={rows} db={in_db}")


if __name__ == "__main__":
    main()