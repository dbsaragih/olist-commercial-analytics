-- =============================================================
-- BQ2. Customer repeat and retention
-- Scope: delivered orders, analysis period Jan 2017 - Aug 2018
-- Customer = customer_unique_id; data cut-off = 2018-08-31
-- =============================================================

-- -------------------------------------------------------------
-- Q1. Repeat rate: any second order vs a real return (later date)
-- -------------------------------------------------------------
WITH cust_orders AS (
    SELECT
        o.customer_unique_id,
        o.order_id,
        o.order_gmv,
        d.full_date                                              AS purchase_date,
        MIN(d.full_date) OVER (PARTITION BY o.customer_unique_id) AS first_date
    FROM mart.fact_orders o
    JOIN mart.dim_date d ON d.date_key = o.purchase_date_key
    WHERE o.is_delivered
      AND d.in_analysis_period
),
customers AS (
    SELECT
        customer_unique_id,
        first_date,
        COUNT(*)                                                   AS orders,
        SUM(order_gmv)                                             AS gmv,
        MIN(purchase_date) FILTER (WHERE purchase_date > first_date) AS return_date
    FROM cust_orders
    GROUP BY customer_unique_id, first_date
)
SELECT
    COUNT(*)                                                        AS customers,
    COUNT(*) FILTER (WHERE orders >= 2)                             AS multi_order_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE orders >= 2) / COUNT(*), 2) AS multi_order_pct,
    COUNT(*) FILTER (WHERE orders >= 2 AND return_date IS NULL)     AS same_day_only,
    COUNT(*) FILTER (WHERE return_date IS NOT NULL)                 AS returned_later,
    ROUND(100.0 * COUNT(*) FILTER (WHERE return_date IS NOT NULL) / COUNT(*), 2) AS return_rate_pct
FROM customers;

-- -------------------------------------------------------------
-- Q2a. Cohort return rate within 90 and 180 days of first purchase
--      NULL = cohort not yet fully observed (unknown, not zero)
-- -------------------------------------------------------------
WITH cust_orders AS (
    SELECT
        o.customer_unique_id,
        o.order_id,
        o.order_gmv,
        d.full_date                                              AS purchase_date,
        MIN(d.full_date) OVER (PARTITION BY o.customer_unique_id) AS first_date
    FROM mart.fact_orders o
    JOIN mart.dim_date d ON d.date_key = o.purchase_date_key
    WHERE o.is_delivered
      AND d.in_analysis_period
),
customers AS (
    SELECT
        customer_unique_id,
        first_date,
        COUNT(*)                                                   AS orders,
        SUM(order_gmv)                                             AS gmv,
        MIN(purchase_date) FILTER (WHERE purchase_date > first_date) AS return_date
    FROM cust_orders
    GROUP BY customer_unique_id, first_date
)
SELECT
    DATE_TRUNC('month', first_date)::date AS cohort_month,
    COUNT(*)                              AS new_customers,
    CASE WHEN MAX(first_date) + 90 <= DATE '2018-08-31' THEN
        ROUND(100.0 * COUNT(*) FILTER (WHERE return_date <= first_date + 90) / COUNT(*), 2)
    END                                   AS return_90d_pct,
    CASE WHEN MAX(first_date) + 180 <= DATE '2018-08-31' THEN
        ROUND(100.0 * COUNT(*) FILTER (WHERE return_date <= first_date + 180) / COUNT(*), 2)
    END                                   AS return_180d_pct
FROM customers
GROUP BY 1
ORDER BY 1;

-- -------------------------------------------------------------
-- Q2b. Pooled fixed-window return rates (eligible customers only)
-- -------------------------------------------------------------
WITH cust_orders AS (
    SELECT
        o.customer_unique_id,
        o.order_id,
        o.order_gmv,
        d.full_date                                              AS purchase_date,
        MIN(d.full_date) OVER (PARTITION BY o.customer_unique_id) AS first_date
    FROM mart.fact_orders o
    JOIN mart.dim_date d ON d.date_key = o.purchase_date_key
    WHERE o.is_delivered
      AND d.in_analysis_period
),
customers AS (
    SELECT
        customer_unique_id,
        first_date,
        COUNT(*)                                                   AS orders,
        SUM(order_gmv)                                             AS gmv,
        MIN(purchase_date) FILTER (WHERE purchase_date > first_date) AS return_date
    FROM cust_orders
    GROUP BY customer_unique_id, first_date
)
SELECT '90 days' AS window_length,
       COUNT(*)  AS eligible_customers,
       COUNT(*) FILTER (WHERE return_date <= first_date + 90) AS returned,
       ROUND(100.0 * COUNT(*) FILTER (WHERE return_date <= first_date + 90) / COUNT(*), 2) AS return_pct
FROM customers
WHERE first_date + 90 <= DATE '2018-08-31'
UNION ALL
SELECT '180 days',
       COUNT(*),
       COUNT(*) FILTER (WHERE return_date <= first_date + 180),
       ROUND(100.0 * COUNT(*) FILTER (WHERE return_date <= first_date + 180) / COUNT(*), 2)
FROM customers
WHERE first_date + 180 <= DATE '2018-08-31';

-- -------------------------------------------------------------
-- Q3. Time to return (customers who returned on a later date)
-- -------------------------------------------------------------
WITH cust_orders AS (
    SELECT
        o.customer_unique_id,
        o.order_id,
        o.order_gmv,
        d.full_date                                              AS purchase_date,
        MIN(d.full_date) OVER (PARTITION BY o.customer_unique_id) AS first_date
    FROM mart.fact_orders o
    JOIN mart.dim_date d ON d.date_key = o.purchase_date_key
    WHERE o.is_delivered
      AND d.in_analysis_period
),
customers AS (
    SELECT
        customer_unique_id,
        first_date,
        COUNT(*)                                                   AS orders,
        SUM(order_gmv)                                             AS gmv,
        MIN(purchase_date) FILTER (WHERE purchase_date > first_date) AS return_date
    FROM cust_orders
    GROUP BY customer_unique_id, first_date
),
returners AS (
    SELECT return_date - first_date AS days_to_return
    FROM customers
    WHERE return_date IS NOT NULL
)
SELECT
    CASE
        WHEN days_to_return <= 30  THEN '1. 1-30 days'
        WHEN days_to_return <= 90  THEN '2. 31-90 days'
        WHEN days_to_return <= 180 THEN '3. 91-180 days'
        WHEN days_to_return <= 365 THEN '4. 181-365 days'
        ELSE                            '5. Over 365 days'
    END                                                  AS time_bucket,
    COUNT(*)                                             AS returners,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)   AS share_pct,
    ROUND(100.0 * SUM(COUNT(*)) OVER (ORDER BY MIN(days_to_return)
          ROWS UNBOUNDED PRECEDING) / SUM(COUNT(*)) OVER (), 1) AS cumulative_pct,
    (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_to_return)
       FROM returners)                                   AS median_days_all
FROM returners
GROUP BY 1
ORDER BY 1;

-- -------------------------------------------------------------
-- Q4. Value of returners: share of customers vs share of GMV
-- -------------------------------------------------------------
WITH cust_orders AS (
    SELECT
        o.customer_unique_id,
        o.order_id,
        o.order_gmv,
        d.full_date                                              AS purchase_date,
        MIN(d.full_date) OVER (PARTITION BY o.customer_unique_id) AS first_date
    FROM mart.fact_orders o
    JOIN mart.dim_date d ON d.date_key = o.purchase_date_key
    WHERE o.is_delivered
      AND d.in_analysis_period
),
customers AS (
    SELECT
        customer_unique_id,
        first_date,
        COUNT(*)                                                   AS orders,
        SUM(order_gmv)                                             AS gmv,
        MIN(purchase_date) FILTER (WHERE purchase_date > first_date) AS return_date
    FROM cust_orders
    GROUP BY customer_unique_id, first_date
),
segmented AS (
    SELECT *,
        CASE
            WHEN return_date IS NOT NULL THEN '1. Returned (later date)'
            WHEN orders >= 2             THEN '2. Same-day multi-order only'
            ELSE                              '3. One-time'
        END AS segment
    FROM customers
)
SELECT
    segment,
    COUNT(*)                                                  AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)        AS customer_share_pct,
    SUM(orders)                                               AS orders,
    SUM(gmv)                                                  AS gmv,
    ROUND(100.0 * SUM(gmv) / SUM(SUM(gmv)) OVER (), 2)        AS gmv_share_pct,
    ROUND(SUM(gmv) / COUNT(*), 2)                             AS gmv_per_customer
FROM segmented
GROUP BY segment
ORDER BY segment;