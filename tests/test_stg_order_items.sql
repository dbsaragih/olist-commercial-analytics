-- =====================================================================
-- test_stg_order_items.sql
-- Checks staging.stg_order_items against the profiling results.
-- =====================================================================

-- 1. Rows and composite key. Expect: 112650 | 112650 | 98666
SELECT COUNT(*)                                   AS total_rows,
       COUNT(DISTINCT (order_id, order_item_id))  AS distinct_pairs,
       COUNT(DISTINCT order_id)                   AS distinct_orders
FROM staging.stg_order_items;

-- 2. Item positions now numeric. Expect: 1 | 21
SELECT MIN(order_item_id) AS min_item_id,
       MAX(order_item_id) AS max_item_id
FROM staging.stg_order_items;

-- 3. Price and freight. Expect: 0.85 | 6735.00 | 120.65 | 0.00 | 409.68 | 383 | 4124
SELECT MIN(price)                                     AS min_price,
       MAX(price)                                     AS max_price,
       ROUND(AVG(price), 2)                           AS avg_price,
       MIN(freight_value)                             AS min_freight,
       MAX(freight_value)                             AS max_freight,
       COUNT(*) FILTER (WHERE freight_value = 0)      AS zero_freight,
       COUNT(*) FILTER (WHERE freight_value > price)  AS freight_gt_price
FROM staging.stg_order_items;

-- 4. Shipping deadline range. Expect: 2016-09-19 00:15:34 | 2020-04-09 22:35:08
SELECT MIN(shipping_limit_ts) AS min_deadline,
       MAX(shipping_limit_ts) AS max_deadline
FROM staging.stg_order_items;

-- 5. Data types. Expect: text, integer, text, text,
--    timestamp without time zone, numeric, numeric
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'staging' AND table_name = 'stg_order_items'
ORDER BY ordinal_position;