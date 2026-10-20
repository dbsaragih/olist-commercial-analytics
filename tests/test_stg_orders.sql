-- =====================================================================
-- test_stg_orders.sql
-- Checks staging.stg_orders against the profiling results.
-- Expected values are noted above each query.
-- =====================================================================

-- 1. Rows and key. Expect: 99441 | 99441
SELECT COUNT(*)                 AS total_rows,
       COUNT(DISTINCT order_id) AS distinct_orders
FROM staging.stg_orders;

-- 2. Flags. Expect: 96478 | 99092 | 8 | 166
SELECT COUNT(*) FILTER (WHERE is_delivered)       AS delivered,
       COUNT(*) FILTER (WHERE in_analysis_period) AS in_period,
       COUNT(*) FILTER (WHERE excl_delivery_time) AS excl_delivery_time,
       COUNT(*) FILTER (WHERE excl_carrier_leg)   AS excl_carrier_leg
FROM staging.stg_orders;

-- 3. NULLs preserved from raw. Expect: 160 | 1783 | 2965
SELECT COUNT(*) - COUNT(approved_ts)         AS null_approved,
       COUNT(*) - COUNT(carrier_handover_ts) AS null_carrier,
       COUNT(*) - COUNT(delivered_ts)        AS null_delivered
FROM staging.stg_orders;

-- 4. Data types. Expect: text x3, timestamp without time zone x4, date x1, boolean x4
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'staging' AND table_name = 'stg_orders'
ORDER BY ordinal_position;