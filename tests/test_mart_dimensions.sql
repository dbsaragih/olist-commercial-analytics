-- =====================================================================
-- test_mart_dimensions.sql
-- Checks the four dimension tables.
-- =====================================================================

-- 1. dim_date. Expect: 1096 | 2016-01-01 | 2018-12-31 | 608
SELECT COUNT(*)                                     AS days,
       MIN(full_date)                               AS first_day,
       MAX(full_date)                               AS last_day,
       COUNT(*) FILTER (WHERE in_analysis_period)   AS analysis_days
FROM mart.dim_date;

-- 2. Every order date falls inside dim_date. Expect: 0 | 0 | 0
SELECT
    COUNT(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM mart.dim_date d
                      WHERE d.full_date = o.purchase_ts::date))            AS purchase_outside,
    COUNT(*) FILTER (WHERE o.delivered_ts IS NOT NULL AND NOT EXISTS
                     (SELECT 1 FROM mart.dim_date d
                      WHERE d.full_date = o.delivered_ts::date))           AS delivered_outside,
    COUNT(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM mart.dim_date d
                      WHERE d.full_date = o.estimated_delivery_date))      AS estimated_outside
FROM staging.stg_orders o;


-- 3. dim_customer. Expect: 96096 | 99441 | 0
SELECT COUNT(*)                                   AS people,
       SUM(orders_all)                            AS total_orders,
       COUNT(*) FILTER (WHERE region IS NULL)     AS missing_region
FROM mart.dim_customer;

-- 4. BQ2 first look (no expected value: record it)
SELECT COUNT(*) FILTER (WHERE delivered_orders_in_period >= 1) AS buyers_in_period,
       COUNT(*) FILTER (WHERE is_repeat_customer)              AS repeat_buyers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_repeat_customer)
             / COUNT(*) FILTER (WHERE delivered_orders_in_period >= 1), 2)
                                                               AS repeat_rate_pct
FROM mart.dim_customer;

-- 5. dim_seller. Expect: 3095 | 1849 | 0
SELECT COUNT(*)                                   AS sellers,
       COUNT(*) FILTER (WHERE state = 'SP')       AS sp_sellers,
       COUNT(*) FILTER (WHERE region IS NULL)     AS missing_region
FROM mart.dim_seller;

-- 6. dim_product. Expect: 32951 | 610 | 0
SELECT COUNT(*)                                         AS products,
       COUNT(*) FILTER (WHERE category_name = 'unknown') AS unknown_category,
       COUNT(*) FILTER (WHERE category_name_en IS NULL)  AS missing_english_name
FROM mart.dim_product;