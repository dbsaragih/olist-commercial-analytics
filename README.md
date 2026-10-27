# E-commerce Commercial Performance & Customer Value Analysis

**End-to-end analytics project on the Olist Brazilian e-commerce dataset: from raw data to business recommendations.**

> **Status: in progress.** Data foundation and automated ETL pipeline complete: one command rebuilds a tested star schema in PostgreSQL. Analysis, dashboard and recommendations are next.
---

## 1. Business context

Olist is a Brazilian marketplace connecting small sellers to major e-commerce channels. Leadership wants to understand commercial performance and decide where to focus next year.

The project answers five business questions, each tied to a stakeholder and a decision:

| # | Business question | Stakeholder | Decision it informs |
|---|---|---|---|
| BQ1 | Which product categories drove GMV growth, and was growth driven by more orders or higher spend per order? | Chief Commercial Officer | Where to focus assortment and marketing; acquisition vs. basket size |
| BQ2 | What share of customers buy a second time, how long do they take, and what do they buy? | Chief Commercial Officer | Whether retention programmes justify investment |
| BQ3 | Where do late deliveries originate (seller vs. carrier), and how much do they lower review scores? | Chief Operating Officer | Seller SLAs vs. carrier contracts and routing |
| BQ4 | Which sellers generate the most GMV, and does their service quality keep up? | Head of Marketplace | Which sellers to support vs. which need intervention |
| BQ5 | How does freight cost burden vary by category and region, and does it affect reviews? | Chief Commercial Officer | Shipping rate rules and targeted freight subsidies |

Full definitions, hypotheses and scope: [docs/01_problem_statement.md](docs/01_problem_statement.md)

## 2. Dataset

- **Source:** [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Size:** ~99k orders across 9 related tables (orders, order items, payments, reviews, customers, sellers, products, geolocation, category translation)
- **Analysis period:** Jan 2017 – Aug 2018 (2016 is incomplete; Sep–Oct 2018 is the extract cut-off, confirmed during profiling)
- Raw data is **not** stored in this repo. See *How to run* below.

## 3. ETL pipeline

A reproducible ETL pipeline (ELT pattern) loads 1.55 million rows from 9 source files into PostgreSQL and transforms them through three layers:

| Layer | Contents | Built by |
|---|---|---|
| `raw` | Exact copy of the 9 source files, validated by row counts | `src/load_raw.py` |
| `staging` | 8 views: correct types, consistent names, data-quality flags | `sql/staging/` |
| `mart` | Star schema: 4 dimensions, 2 fact tables, enforced primary and foreign keys | `sql/marts/` |

One command (`py run_pipeline.py`) rebuilds every layer in dependency order and runs 26 automated checks against independently verified numbers, stopping with a clear message if any step or check fails.
Details: [docs/04_etl_pipeline.md](docs/04_etl_pipeline.md)

## 4. Progress

| Stage | Output | Status |
|---|---|---|
| 1. Project setup | Folder structure, `.gitignore`, `requirements.txt`, virtual environment | ✅ Done |
| 2. Version control | Git history on GitHub | ✅ Done |
| 3. Problem framing | [docs/01_problem_statement.md](docs/01_problem_statement.md) | ✅ Done |
| 4. Raw data load | `src/load_raw.py` → `raw` schema in PostgreSQL | ✅ Done |
| 5. Data profiling | `sql/01–03_profile_*.sql` | ✅ Done |
| 6. Data quality findings | [docs/02_data_quality_findings.md](docs/02_data_quality_findings.md) | ✅ Done |
| 7. Data model | [docs/03_data_model.md](docs/03_data_model.md) (star schema design) | ✅ Done |
| 8. Staging layer | 8 views in `sql/staging/`, with tests | ✅ Done |
| 9. Mart layer | 4 dimensions and 2 fact tables in `sql/marts/`, with tests | ✅ Done |
| 10. Pipeline automation | `run_pipeline.py`: one command rebuilds all layers and runs 26 checks | ✅ Done |
| 11. Analysis | SQL + Python analysis answering BQ1–BQ5 | ✅ Done |
| 12. Dashboard | Power BI executive dashboard | ⏳ Planned |
| 13. Recommendations | Findings, recommendations and presentation deck | ⏳ Planned |

## 5. Documentation

| Document | Contents |
|---|---|
| [01 Problem statement](docs/01_problem_statement.md) | Business questions, hypotheses, definitions |
| [02 Data quality findings](docs/02_data_quality_findings.md) | Profiling results and decision log |
| [03 Data model](docs/03_data_model.md) | Star schema design |
| [04 ETL pipeline](docs/04_etl_pipeline.md) | Layers, data quality controls, how to run |
| [05 — Findings](docs/05_findings.md) | Executive summary and findings for BQ1–BQ5 |
| [RFM and CLV notebook](notebooks/01_rfm_clv.ipynb) | Python customer segmentation and lifetime value |

## 6. Repository structure

```
olist-commercial-analytics/
├── docs/          # problem statement, data quality, data model, ETL pipeline
├── sql/           # data profiling queries
│   ├── staging/   # staging views
│   └── marts/     # star schema tables
├── src/           # Python loader (load_raw.py)
├── tests/         # data quality and reconciliation tests
├── notebooks/     # analysis (coming)
├── dashboard/     # Power BI file (coming)
├── deck/          # presentation (coming)
├── requirements.txt
└── README.md
```
## 7. How to run

1. Clone this repo and create a virtual environment: run `py -m venv .venv`, then `.venv\Scripts\activate`, then `pip install -r requirements.txt`.
2. Download the dataset from the Kaggle link above and place the 9 CSV files in `data/raw/`.
3. Create a `.env` file with your PostgreSQL connection details (not included in the repo).
4. Run the pipeline with the virtual environment active: `py run_pipeline.py`. This loads the raw data, builds the staging views and the star schema, and runs 26 automated checks. It ends with `PIPELINE OK`, or names the step or check that failed.
5. To rebuild only the SQL layers after changing a query, run `py run_pipeline.py --skip-load`.

## 8. Tools

Python (pandas, SQLAlchemy) · PostgreSQL · SQL · Power BI · Git & GitHub

---

**Author:** Daniel Saragih, data and risk analytics professional with 20+ years in banking and lending.
[LinkedIn](https://www.linkedin.com/in/danielsaragih-8a82a528)