"""
Load the raw Olist CSV files into the PostgreSQL 'raw' schema.

Every column is loaded as text, exactly as delivered. Type conversion
and cleaning happen later, in the staging layer.

Usage (from the project folder, with .venv active):
    py src/load_raw.py
"""
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

# Folder locations, worked out from where this script is saved
PROJECT_DIR = Path(__file__).resolve().parents[1]
RAW_DIR = PROJECT_DIR / "data" / "raw"

# CSV file name -> table name in the raw schema
TABLES = {
    "olist_customers_dataset.csv": "customers",
    "olist_geolocation_dataset.csv": "geolocation",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
    "olist_orders_dataset.csv": "orders",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "product_category_name_translation.csv": "category_translation",
}


def get_engine():
    """Build a database connection from the settings in .env."""
    load_dotenv(PROJECT_DIR / ".env")
    url = URL.create(
        drivername="postgresql+psycopg",
        username=os.environ["PGUSER"],
        password=os.environ["PGPASSWORD"],
        host=os.environ["PGHOST"],
        port=int(os.environ["PGPORT"]),
        database=os.environ["PGDATABASE"],
    )
    return create_engine(url)


def main():
    engine = get_engine()

    # Create the raw schema if it does not exist yet
    with engine.begin() as conn:
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw"))

    print(f"{'table':<22}{'csv rows':>12}{'db rows':>12}  check")
    for file_name, table in TABLES.items():
        # Read the CSV with every column as text
        df = pd.read_csv(RAW_DIR / file_name, dtype=str)

        # Write it to raw.<table>, replacing any earlier load
        df.to_sql(table, engine, schema="raw", if_exists="replace",
                  index=False, chunksize=10_000)

        # Count the rows in the database and compare with the CSV
        with engine.connect() as conn:
            db_rows = conn.execute(
                text(f"SELECT COUNT(*) FROM raw.{table}")
            ).scalar_one()
        status = "OK" if db_rows == len(df) else "MISMATCH"
        print(f"{table:<22}{len(df):>12,}{db_rows:>12,}  {status}")


if __name__ == "__main__":
    main()