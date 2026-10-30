-- =====================================================================
-- customer_value.sql
-- Customer-grain table: one row per customer_unique_id with at least one
-- delivered order in the analysis period (Jan 2017 - Aug 2018).
-- Single source for retention (BQ2) and RFM (notebooks/01_rfm_clv.ipynb).
-- Rules:
--   * purchase_days counts distinct days (same-day orders = one occasion)
--   * eligible_* = full window ends by the cut-off; returned_* are NOT NULL
--   * R and M scores replicate pandas qcut: linear quantile edges,
--     right-inclusive bins (value <= edge)
-- =====================================================================

DROP TABLE IF EXISTS mart.customer_value CASCADE;

CREATE TABLE mart.customer_value AS
WITH params AS (
    SELECT DATE '2018-08-31' AS cutoff,
           DATE '2018-09-01' AS snapshot
),
cust_orders AS (
    SELECT o.customer_unique_id,
           d.full_date AS purchase_date,
           o.order_gmv
    FROM mart.fact_orders o
    JOIN mart.dim_date d ON d.date_key = o.purchase_date_key
    WHERE o.is_delivered
      AND d.in_analysis_period
),
base AS (
    SELECT customer_unique_id,
           MIN(purchase_date)            AS first_purchase_date,
           MAX(purchase_date)            AS last_purchase_date,
           COUNT(*)                      AS orders,
           COUNT(DISTINCT purchase_date) AS purchase_days,
           SUM(order_gmv)                AS gmv
    FROM cust_orders
    GROUP BY customer_unique_id
),
first_return AS (
    SELECT c.customer_unique_id,
           MIN(c.purchase_date) AS return_date
    FROM cust_orders c
    JOIN base b ON b.customer_unique_id = c.customer_unique_id
    WHERE c.purchase_date > b.first_purchase_date
    GROUP BY c.customer_unique_id
),
features AS (
    SELECT b.*,
           r.return_date,
           p.snapshot - b.last_purchase_date AS recency_days
    FROM base b
    LEFT JOIN first_return r ON r.customer_unique_id = b.customer_unique_id
    CROSS JOIN params p
),
edges AS (
    SELECT PERCENTILE_CONT(ARRAY[0.2, 0.4, 0.6, 0.8])
               WITHIN GROUP (ORDER BY recency_days) AS r_edge,
           PERCENTILE_CONT(ARRAY[0.2, 0.4, 0.6, 0.8])
               WITHIN GROUP (ORDER BY gmv)          AS m_edge
    FROM features
),
scored AS (
    SELECT f.*,
           CASE WHEN f.recency_days <= e.r_edge[1] THEN 5
                WHEN f.recency_days <= e.r_edge[2] THEN 4
                WHEN f.recency_days <= e.r_edge[3] THEN 3
                WHEN f.recency_days <= e.r_edge[4] THEN 2
                ELSE 1 END                                   AS r_score,
           CASE WHEN f.gmv <= e.m_edge[1] THEN 1
                WHEN f.gmv <= e.m_edge[2] THEN 2
                WHEN f.gmv <= e.m_edge[3] THEN 3
                WHEN f.gmv <= e.m_edge[4] THEN 4
                ELSE 5 END                                   AS m_score,
           CASE WHEN f.purchase_days >= 2 THEN 2 ELSE 1 END  AS f_score
    FROM features f
    CROSS JOIN edges e
)
SELECT
    s.customer_unique_id,
    s.first_purchase_date,
    DATE_TRUNC('month', s.first_purchase_date)::date             AS cohort_month,
    s.last_purchase_date,
    s.orders,
    s.purchase_days,
    s.gmv,
    (s.purchase_days >= 2)                                       AS is_returner,
    s.return_date,
    s.return_date - s.first_purchase_date                        AS days_to_return,
    (s.first_purchase_date + 90  <= p.cutoff)                    AS eligible_90d,
    COALESCE(s.return_date <= s.first_purchase_date + 90,  FALSE) AS returned_90d,
    (s.first_purchase_date + 180 <= p.cutoff)                    AS eligible_180d,
    COALESCE(s.return_date <= s.first_purchase_date + 180, FALSE) AS returned_180d,
    s.recency_days,
    s.r_score,
    s.f_score,
    s.m_score,
    CASE
        WHEN s.f_score = 2 AND s.r_score >= 4  THEN '1. Repeat, recent'
        WHEN s.f_score = 2                     THEN '2. Repeat, lapsing'
        WHEN s.m_score >= 4 AND s.r_score >= 4 THEN '3. One-time, high value, recent'
        WHEN s.m_score >= 4                    THEN '4. One-time, high value, lapsed'
        WHEN s.r_score >= 4                    THEN '5. One-time, low value, recent'
        ELSE                                        '6. One-time, low value, lapsed'
    END                                                          AS rfm_segment
FROM scored s
CROSS JOIN params p;

ALTER TABLE mart.customer_value
    ADD PRIMARY KEY (customer_unique_id),
    ADD CONSTRAINT fk_cv_customer FOREIGN KEY (customer_unique_id)
        REFERENCES mart.dim_customer (customer_unique_id);