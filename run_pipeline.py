"""
run_pipeline.py
Rebuilds the Olist analytics database end to end and checks the result.

Steps:
  1. Load the raw CSV files into the raw schema (src/load_raw.py)
  2. Build the staging views (sql/staging)
  3. Build the mart tables (sql/marts): dimensions, then facts
  4. Run the automated checks (tests/pipeline_checks.sql)

Usage (from the project folder, with .venv active):
    py run_pipeline.py              full run
    py run_pipeline.py --skip-load  reuse the existing raw tables (faster)

Exit code 0 = success; 1 = a step or check failed.
"""
import argparse
import os
import sys
import time
from pathlib import Path

import psycopg
from dotenv import load_dotenv

PROJECT_DIR = Path(__file__).resolve().parent
SQL_DIR = PROJECT_DIR / "sql"
CHECKS_FILE = PROJECT_DIR / "tests" / "pipeline_checks.sql"

# Build order: each file may depend only on files listed above it.
BUILD_STEPS = [
    "staging/stg_orders.sql",
    "staging/stg_order_items.sql",
    "staging/stg_order_reviews.sql",
    "staging/stg_customers.sql",
    "staging/stg_sellers.sql",
    "staging/stg_products.sql",
    "staging/stg_category_translation.sql",
    "staging/stg_state_region.sql",
    "marts/dim_date.sql",
    "marts/dim_customer.sql",
    "marts/dim_seller.sql",
    "marts/dim_product.sql",
    "marts/fact_order_items.sql",
    "marts/fact_orders.sql",
]


def connect():
    """Open a database connection using the settings in .env."""
    load_dotenv(PROJECT_DIR / ".env")
    return psycopg.connect(
        host=os.environ["PGHOST"],
        port=os.environ["PGPORT"],
        user=os.environ["PGUSER"],
        password=os.environ["PGPASSWORD"],
        dbname=os.environ["PGDATABASE"],
        autocommit=True,
    )


def run_sql_file(conn, relative_path):
    """Execute every statement in one SQL file."""
    path = SQL_DIR / relative_path
    conn.execute(path.read_text(encoding="utf-8-sig"))


def load_raw(conn):
    """Reload the raw tables. Staging views depend on them, so drop staging first."""
    conn.execute("DROP SCHEMA IF EXISTS staging CASCADE")
    sys.path.insert(0, str(PROJECT_DIR / "src"))
    from load_raw import main as load_raw_main
    load_raw_main()


def run_checks(conn):
    """Run the automated checks; return the number of failures."""
    rows = conn.execute(CHECKS_FILE.read_text(encoding="utf-8-sig")).fetchall()
    failures = 0
    print(f"\n{'#':>3}  {'layer':<8}{'check':<42}{'expected':>14}{'actual':>14}  result")
    for n, layer, name, expected, actual in rows:
        ok = expected == actual
        failures += 0 if ok else 1
        print(f"{n:>3}  {layer:<8}{name:<42}{expected:>14,}{actual:>14,}  "
              f"{'PASS' if ok else 'FAIL'}")
    return failures


def main():
    parser = argparse.ArgumentParser(description="Rebuild and check the Olist database.")
    parser.add_argument("--skip-load", action="store_true",
                        help="reuse the existing raw tables")
    args = parser.parse_args()

    start = time.time()
    with connect() as conn:
        step = "connect"
        try:
            if args.skip_load:
                print("[1/4] Load raw data: skipped (--skip-load)")
            else:
                step = "load raw data"
                print("[1/4] Load raw data")
                load_raw(conn)

            for i, relative_path in enumerate(BUILD_STEPS, start=1):
                step = relative_path
                layer = "2/4" if relative_path.startswith("staging") else "3/4"
                t0 = time.time()
                run_sql_file(conn, relative_path)
                print(f"[{layer}] {relative_path:<40} done in {time.time() - t0:5.1f}s")

            step = "checks"
            print("[4/4] Run checks")
            failures = run_checks(conn)

        except Exception as error:
            print(f"\nPIPELINE FAILED at step: {step}\n{error}")
            sys.exit(1)

    elapsed = time.time() - start
    if failures:
        print(f"\nPIPELINE FAILED: {failures} check(s) failed ({elapsed:.0f}s)")
        sys.exit(1)
    print(f"\nPIPELINE OK: all checks passed ({elapsed:.0f}s)")


if __name__ == "__main__":
    main()