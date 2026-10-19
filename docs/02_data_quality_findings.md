# 02 — Data Quality Findings

## Summary

**The Olist data is fit for the five business questions, provided the analysis
is limited to January 2017 – August 2018 and nine small treatments are applied.**
All table keys are unique, every join between tables is complete, and customer
payments reconcile with item values for 99.75% of delivered orders. Every data
issue found affects less than 2% of orders or sales value; none changes the
answer to a business question once treated as described below.

## Scope and method

- **Tables profiled:** orders, order_items, customers, order_reviews,
  order_payments, products, category_translation, sellers.
- **Not profiled:** geolocation. Customer and seller states are available
  directly in the customers and sellers tables, so it is not needed.
- **Checks applied:** row counts, key uniqueness, missing values, value
  distributions, date ranges, logical consistency, links between tables, and
  cross-table reconciliation.
- **Queries:** `sql/01_profile_orders.sql`, `sql/02_profile_order_items.sql`,
  `sql/03_profile_remaining_tables.sql`.

## 1. Keys and links between tables are reliable

Every table has a unique key, and every relationship tested is complete:

| Check | Result |
|---|---|
| Unique keys (orders, line items, products, sellers) | No duplicates |
| Line items → orders, products, sellers | 0 unmatched rows |
| Orders ↔ customers | 0 unmatched rows in either direction |
| Payments vs item values (delivered orders) | 99.75% match within R$ 1; net gap 0.02% |

The payment reconciliation confirms that GMV calculated from item prices is
reliable. Payments are therefore used as a cross-check only, not to measure
revenue.

## 2. The analysis period must be January 2017 – August 2018

Monthly orders show two data artefacts that would distort any trend:

- **2016 is incomplete:** 4 orders in September, none in November and 1 in
  December, indicating gaps in the dataset rather than business activity.
- **September–October 2018 is the extract cut-off:** orders fall from 6,512 in
  August to 16 and 4. Over 1,700 orders were still in progress (shipped,
  invoiced, processing) when the data was extracted.

Within the 20-month window, January–August orders grew from 22,968 (2017) to
53,991 (2018), +135% like-for-like, with growth flattening during 2018.

## 3. Nine treatments are applied before analysis

**Materiality threshold:** issues affecting less than 1% of the relevant rows
or value are treated as immaterial and excluded or documented; issues between
1% and 5% are kept and labelled rather than excluded; no issue exceeded 5%.
Exclusions that could bias a regional or seller comparison (T4, T5, T7) are
re-checked by segment during the analysis.

| # | Issue | Size | Treatment | Affects |
|---|---|---|---|---|
| T1 | Incomplete 2016 and cut-off 2018 months | Sep–Dec 2016, Sep–Oct 2018 | Analyse Jan 2017 – Aug 2018 only | All |
| T2 | `customer_id` is unique per order, not per person | 99,441 IDs for 96,096 people | Identify customers by `customer_unique_id` | BQ2 |
| T3 | Delivered orders with no delivery date | 8 orders (0.01%) | Exclude from delivery-time analysis | BQ3 |
| T4 | Carrier pickup recorded before purchase | 166 orders (0.17%) | Exclude from seller-vs-carrier analysis | BQ3 |
| T5 | Shipping deadline over 30 days after purchase (up to 2020) | 239 items (0.21%) | Exclude from seller-handover analysis | BQ3 |
| T6 | Orders with more than one review | 547 orders (0.55%) | Keep the most recent review per order | BQ3–BQ5 |
| T7 | Orders without a review | 768 orders (0.77%) | Exclude from rating analyses; no imputation | BQ3–BQ5 |
| T8 | Products without a category | 610 products; 1.32% of value | Label as "unknown"; keep in totals | BQ1, BQ2 |
| T9 | Categories without English translation | 2 categories | Add translations manually | BQ1, BQ2 |

**Documented without treatment** (immaterial and outside GMV, which uses
delivered orders only): 775 orders without items (0.78%; none delivered),
6 non-delivered orders with a delivery date, 1 order without a payment record,
and 246 orders whose payments differ from item values by more than R$ 1.

## 4. Early business signals to test in the analysis

Profiling also surfaced patterns that bear directly on the hypotheses. These are
signals, not conclusions: they are tested on the treated data in the analysis.

| Signal | Evidence | Question |
|---|---|---|
| Single-item orders dominate | 90.1% of orders contain one item | BQ1 |
| Few customers return | 3.1% of people placed more than one order | BQ2 |
| Ratings are polarised | 1-star reviews (11.5%) outnumber 2- and 3-star combined (11.4%) | BQ3 |
| Freight can exceed item value | 3.7% of items cost more to ship than to buy | BQ5 |
| Sellers are more concentrated than customers | SP holds 59.7% of sellers but 42.0% of customers | BQ3, BQ5 |

## Appendix: Detailed findings by table

### Orders (99,441 rows)
- `order_id` unique; 97.0% of orders delivered.
- Missing approval, carrier and delivery dates (160 / 1,783 / 2,965) are
  explained by order status; the delivery-date count reconciles exactly.
- 8 delivered orders without a delivery date; 6 non-delivered orders with one;
  166 carrier pickups before purchase.

### Order items (112,650 rows)
- Key (`order_id`, `order_item_id`) unique; no missing values.
- 1.14 items per order on average; every product and seller appears at least once.
- Prices right-skewed: median R$ 74.99, mean R$ 120.65, maximum R$ 6,735.
- 383 items (0.34%) with zero freight; 4,124 items (3.66%) with freight above price.
- 239 items with shipping deadlines over 30 days after purchase.

### Customers (99,441 rows)
- 96,096 distinct people; 2,997 (3.1%) with more than one order.
- 27 states; SP 42.0%, RJ 12.9%, MG 11.7%; the North region 1.9%.

### Order reviews (99,224 rows)
- Grain is (review, order): one review can cover several orders bought together.
- 547 orders with several reviews; 768 orders without a review.
- Scores: 5 stars 57.8%, 4 stars 19.3%, 3 stars 8.2%, 2 stars 3.2%, 1 star 11.5%.

### Order payments (103,886 rows)
- 99,440 orders paid; several rows per order where payments are split.
- Credit card 73.9% of payments, boleto 19.0%, voucher 5.6%, debit card 1.5%.

### Products and categories (32,951 products)
- `product_id` unique; 73 categories; 610 products without a category.
- 2 categories missing from the translation table.

### Sellers (3,095 rows)
- `seller_id` unique; 23 states; SP 59.7%, South region (PR, SC, RS) 21.6%.