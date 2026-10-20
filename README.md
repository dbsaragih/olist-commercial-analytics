# E-commerce Commercial Performance & Customer Value Analysis

**End-to-end analytics project on the Olist Brazilian e-commerce dataset: from raw data to business recommendations.**

> **Status: in progress.** Data foundation complete (setup, raw data load, profiling, data quality review). Analysis, dashboard and recommendations are next.

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

## 3. Progress

| Stage | Output | Status |
|---|---|---|
| 1. Project setup | Folder structure, `.gitignore`, `requirements.txt`, virtual environment | ✅ Done |
| 2. Version control | Git history on GitHub | ✅ Done |
| 3. Problem framing | [docs/01_problem_statement.md](docs/01_problem_statement.md) | ✅ Done |
| 4. Raw data load | `src/load_raw.py` → `raw` schema in PostgreSQL | ✅ Done |
| 5. Data profiling | `sql/01–03_profile_*.sql` | ✅ Done |
| 6. Data quality findings | [docs/02_data_quality_findings.md](docs/02_data_quality_findings.md) | ✅ Done |
| 7. Data model | `docs/03_data_model.md` (star schema design) | ✅ Done |
| 8. Analysis | SQL + Python analysis answering BQ1–BQ5 | ⏳ Next |
| 9. Dashboard | Power BI executive dashboard | ⏳ Planned |
| 10. Recommendations | Findings, recommendations and presentation deck | ⏳ Planned |

## 4. Repository structure

```
olist-commercial-analytics/
├── docs/          # problem statement, data quality findings, data model
├── sql/           # data profiling queries
├── src/           # Python ETL (load_raw.py)
├── notebooks/     # analysis (coming)
├── tests/         # data checks (coming)
├── dashboard/     # Power BI file (coming)
├── deck/          # presentation (coming)
├── requirements.txt
└── README.md
```

## 5. How to run

1. Clone this repo and create a virtual environment:
   ```
   py -m venv .venv
   .venv\Scripts\activate
   pip install -r requirements.txt
   ```
2. Download the dataset from the Kaggle link above and place the 9 CSV files in `data/raw/`.
3. Create a `.env` file with your PostgreSQL connection details (not included in the repo).
4. Load the raw data (with the virtual environment active): `py src/load_raw.py`
5. Run the profiling queries in `sql/` in numbered order.

## 6. Tools

Python (pandas) · PostgreSQL · SQL · Power BI · Git & GitHub

---

**Author:** Daniel Saragih, data and risk analytics professional with 20+ years in banking and lending.
[LinkedIn](https://www.linkedin.com/in/danielsaragih-8a82a528)
