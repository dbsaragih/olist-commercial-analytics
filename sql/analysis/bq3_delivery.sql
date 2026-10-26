-- =============================================================
-- BQ3. Delivery performance and customer ratings
-- Scope: delivered orders, analysis period Jan 2017 - Aug 2018,
--        excluding delivered orders without a delivery date (T3)
-- =============================================================

-- -------------------------------------------------------------
-- Q1. Late rate and rating gap
-- -------------------------------------------------------------
SELECT
    CASE WHEN o.is_late THEN '2. Late' ELSE '1. On time' END          AS delivery,
    COUNT(*)                                                          AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)                AS share_pct,
    COUNT(*) FILTER (WHERE o.has_review)                              AS reviewed,
    ROUND(AVG(o.review_score), 2)                                     AS avg_score,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.review_score <= 2)
          / NULLIF(COUNT(*) FILTER (WHERE o.has_review), 0), 1)       AS low_score_pct
FROM mart.fact_orders o
JOIN mart.dim_date d ON d.date_key = o.purchase_date_key
WHERE o.is_delivered
  AND d.in_analysis_period
  AND NOT o.excl_delivery_time
GROUP BY 1
ORDER BY 1;

-- -------------------------------------------------------------
-- Q2. Dose-response: rating by days early / late vs the estimate
--     days_vs_estimate > 0 = late, < 0 = early
-- -------------------------------------------------------------
SELECT
    CASE
        WHEN o.days_vs_estimate <= -10 THEN '1. 10+ days early'
        WHEN o.days_vs_estimate <   0  THEN '2. 1-9 days early'
        WHEN o.days_vs_estimate =   0  THEN '3. On the estimated day'
        WHEN o.days_vs_estimate <=  3  THEN '4. 1-3 days late'
        WHEN o.days_vs_estimate <=  7  THEN '5. 4-7 days late'
        WHEN o.days_vs_estimate <= 14  THEN '6. 8-14 days late'
        ELSE                                '7. 15+ days late'
    END                                                               AS timing,
    COUNT(*)                                                          AS orders,
    ROUND(AVG(o.review_score), 2)                                     AS avg_score,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.review_score <= 2)
          / NULLIF(COUNT(*) FILTER (WHERE o.has_review), 0), 1)       AS low_score_pct
FROM mart.fact_orders o
JOIN mart.dim_date d ON d.date_key = o.purchase_date_key
WHERE o.is_delivered
  AND d.in_analysis_period
  AND NOT o.excl_delivery_time
GROUP BY 1
ORDER BY 1;

-- -------------------------------------------------------------
-- Q3. Which leg is slow: seller handover vs carrier transit
--     Also excludes T4 (carrier before purchase) and T5 (handover deadline > 30 days)
-- -------------------------------------------------------------
SELECT
    CASE WHEN o.is_late THEN '2. Late' ELSE '1. On time' END          AS delivery,
    COUNT(*)                                                          AS orders,
    ROUND(AVG(o.seller_handover_days), 1)                             AS avg_handover_days,
    ROUND(AVG(o.carrier_transit_days), 1)                             AS avg_transit_days,
    ROUND(AVG(o.delivery_days), 1)                                    AS avg_total_days,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.is_handover_late) / COUNT(*), 1) AS handover_late_pct
FROM mart.fact_orders o
JOIN mart.dim_date d ON d.date_key = o.purchase_date_key
WHERE o.is_delivered
  AND d.in_analysis_period
  AND NOT o.excl_delivery_time
  AND NOT o.excl_carrier_leg
  AND NOT o.excl_handover
GROUP BY 1
ORDER BY 1;

-- -------------------------------------------------------------
-- Q4. Late rate and transit time by delivery state
-- -------------------------------------------------------------
SELECT
    o.delivery_state,
    r.region,
    COUNT(*)                                                          AS orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.is_late) / COUNT(*), 1)    AS late_pct,
    ROUND(AVG(o.carrier_transit_days)
          FILTER (WHERE NOT o.excl_carrier_leg), 1)                   AS avg_transit_days,
    ROUND(AVG(o.delivery_days), 1)                                    AS avg_total_days,
    ROUND(AVG(o.review_score), 2)                                     AS avg_score
FROM mart.fact_orders o
JOIN mart.dim_date d ON d.date_key = o.purchase_date_key
LEFT JOIN staging.stg_state_region r ON r.state = o.delivery_state
WHERE o.is_delivered
  AND d.in_analysis_period
  AND NOT o.excl_delivery_time
GROUP BY o.delivery_state, r.region
ORDER BY late_pct DESC;

-- -------------------------------------------------------------
-- Q5. Does a late first order reduce the 180-day return rate?
--     Same customer logic as BQ2; eligible cohorts only
-- -------------------------------------------------------------
WITH cust_orders AS (
    SELECT
        o.customer_unique_id,
        o.is_late,
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
        BOOL_OR(is_late) FILTER (WHERE purchase_date = first_date)   AS first_order_late,
        MIN(purchase_date) FILTER (WHERE purchase_date > first_date) AS return_date
    FROM cust_orders
    GROUP BY customer_unique_id, first_date
)
SELECT
    CASE
        WHEN first_order_late         THEN '2. Late first order'
        WHEN NOT first_order_late     THEN '1. On-time first order'
        ELSE                               '3. Unknown (no delivery date)'
    END                                                              AS first_order,
    COUNT(*)                                                         AS customers,
    COUNT(*) FILTER (WHERE return_date <= first_date + 180)          AS returned_180d,
    ROUND(100.0 * COUNT(*) FILTER (WHERE return_date <= first_date + 180)
          / COUNT(*), 2)                                             AS return_180d_pct
FROM customers
WHERE first_date + 180 <= DATE '2018-08-31'
GROUP BY 1
ORDER BY 1;

-- -------------------------------------------------------------
-- Q4b. Region roll-up: late rate vs share of all late orders,
--      and how far ahead of the promised date orders arrive
--      (avg_days_vs_estimate < 0 = early on average)
-- -------------------------------------------------------------
SELECT
    r.region,
    COUNT(*)                                                          AS orders,
    COUNT(*) FILTER (WHERE o.is_late)                                 AS late_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.is_late) / COUNT(*), 1)    AS late_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.is_late)
          / SUM(COUNT(*) FILTER (WHERE o.is_late)) OVER (), 1)        AS share_of_late_pct,
    ROUND(AVG(o.carrier_transit_days)
          FILTER (WHERE NOT o.excl_carrier_leg), 1)                   AS avg_transit_days,
    ROUND(AVG(o.days_vs_estimate), 1)                                 AS avg_days_vs_estimate,
    ROUND(AVG(o.review_score), 2)                                     AS avg_score
FROM mart.fact_orders o
JOIN mart.dim_date d ON d.date_key = o.purchase_date_key
LEFT JOIN staging.stg_state_region r ON r.state = o.delivery_state
WHERE o.is_delivered
  AND d.in_analysis_period
  AND NOT o.excl_delivery_time
GROUP BY r.region
ORDER BY late_pct DESC;