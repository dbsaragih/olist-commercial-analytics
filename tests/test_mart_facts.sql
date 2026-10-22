-- =====================================================================
-- test_mart_facts.sql
-- Checks fact_order_items and fact_orders.
-- =====================================================================

-- 1. fact_order_items: rows, T5, regions. Expect: 112650 | 239 | 0
SELECT COUNT(*)                                     AS item_rows,
       COUNT(*) FILTER (WHERE excl_handover)        AS t5_items,
       COUNT(*) FILTER (WHERE delivery_region IS NULL) AS missing_region
FROM mart.fact_order_items;

-- 2. No value lost from staging. Expect: the two sums are equal
SELECT (SELECT SUM(price) FROM staging.stg_order_items) AS staging_price,
       (SELECT SUM(price) FROM mart.fact_order_items)   AS fact_price;

-- 3. fact_orders: rows and item reconciliation.
--    Expect: 99441 | 112650 | 775 | 96478
SELECT COUNT(*)                                     AS order_rows,
       SUM(items_count)                             AS total_items,
       COUNT(*) FILTER (WHERE items_count = 0)      AS orders_without_items,
       COUNT(*) FILTER (WHERE is_delivered)         AS delivered
FROM mart.fact_orders;

-- 4. GMV reconciles between the two facts. Expect: the two sums are equal
SELECT (SELECT SUM(order_gmv) FROM mart.fact_orders)  AS gmv_from_orders,
       (SELECT SUM(price)     FROM mart.fact_order_items) AS gmv_from_items;

-- 5. Treatments. Expect: 98673 | 768 | 8 | 166
SELECT COUNT(*) FILTER (WHERE has_review)           AS with_review,
       COUNT(*) FILTER (WHERE NOT has_review)       AS without_review,
       COUNT(*) FILTER (WHERE excl_delivery_time)   AS t3,
       COUNT(*) FILTER (WHERE excl_carrier_leg)     AS t4
FROM mart.fact_orders;


-- 6. Logic checks. Expect: 96470 | 6 | 0 | 0
--    a) delivered orders with a delivery time = 96478 delivered - 8 (T3)
--    b) non-delivered orders that still have a delivery time (finding O6)
--    c) no negative delivery time
--    d) every negative seller-handover time is already flagged by T4
SELECT COUNT(delivery_days) FILTER (WHERE is_delivered)            AS delivered_with_days,
       COUNT(delivery_days) FILTER (WHERE NOT is_delivered)        AS not_delivered_with_days,
       COUNT(*) FILTER (WHERE delivery_days < 0)                   AS negative_delivery,
       COUNT(*) FILTER (WHERE seller_handover_days < 0
                          AND NOT excl_carrier_leg)                AS unflagged_negative_handover
FROM mart.fact_orders;








-- 7. Orders affected by T5 (no expected value: record it)
SELECT COUNT(*) FILTER (WHERE excl_handover) AS t5_orders
FROM mart.fact_orders;

-- 8. First look at BQ1 and BQ3 (no expected values: record them)
--    Scope: delivered orders in the analysis period
SELECT
    ROUND(SUM(order_gmv), 2)                                        AS gmv_brl,
    COUNT(*)                                                        AS orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_late)
          / COUNT(*) FILTER (WHERE NOT excl_delivery_time), 2)      AS late_rate_pct,
    ROUND(AVG(review_score) FILTER (WHERE NOT is_late), 2)          AS avg_score_on_time,
    ROUND(AVG(review_score) FILTER (WHERE is_late), 2)              AS avg_score_late
FROM mart.fact_orders
WHERE is_delivered
  AND in_analysis_period;