-- =====================================================================
-- pipeline_checks.sql
-- Automated checks run by run_pipeline.py after every build.
-- Each row: number, layer, check name, expected value, actual value.
-- The pipeline fails if any actual value differs from its expected value.
-- Expected values come from profiling (docs/02_data_quality_findings.md)
-- and the detailed manual tests in this folder.
-- =====================================================================

SELECT n, layer, check_name, expected, actual
FROM (VALUES
  -- Staging
  ( 1, 'staging', 'stg_orders rows',                     99441::numeric,
       (SELECT COUNT(*) FROM staging.stg_orders)::numeric),
  ( 2, 'staging', 'delivered orders',                    96478,
       (SELECT COUNT(*) FROM staging.stg_orders WHERE is_delivered)),
  ( 3, 'staging', 'T1 orders in analysis period',        99092,
       (SELECT COUNT(*) FROM staging.stg_orders WHERE in_analysis_period)),
  ( 4, 'staging', 'T3 delivered without date',           8,
       (SELECT COUNT(*) FROM staging.stg_orders WHERE excl_delivery_time)),
  ( 5, 'staging', 'T4 carrier before purchase',          166,
       (SELECT COUNT(*) FROM staging.stg_orders WHERE excl_carrier_leg)),
  ( 6, 'staging', 'stg_order_items rows',                112650,
       (SELECT COUNT(*) FROM staging.stg_order_items)),
  ( 7, 'staging', 'T6 latest review per order',          98673,
       (SELECT COUNT(*) FROM staging.stg_order_reviews WHERE is_latest_for_order)),
  ( 8, 'staging', 'T2 distinct people',                  96096,
       (SELECT COUNT(DISTINCT customer_unique_id) FROM staging.stg_customers)),
  ( 9, 'staging', 'T8 products in unknown category',     610,
       (SELECT COUNT(*) FROM staging.stg_products WHERE category_name = 'unknown')),
  (10, 'staging', 'T9 products without English name',    0,
       (SELECT COUNT(*) FROM staging.stg_products p
         WHERE NOT EXISTS (SELECT 1 FROM staging.stg_category_translation t
                            WHERE t.category_name = p.category_name))),

  -- Marts: dimensions
  (11, 'mart', 'dim_date days',                          1096,
       (SELECT COUNT(*) FROM mart.dim_date)),
  (12, 'mart', 'dim_customer rows',                      96096,
       (SELECT COUNT(*) FROM mart.dim_customer)),
  (13, 'mart', 'dim_customer orders add up',             99441,
       (SELECT SUM(orders_all) FROM mart.dim_customer)),
  (14, 'mart', 'dim_seller rows',                        3095,
       (SELECT COUNT(*) FROM mart.dim_seller)),
  (15, 'mart', 'dim_product rows',                       32951,
       (SELECT COUNT(*) FROM mart.dim_product)),
  (16, 'mart', 'customers and sellers missing region',   0,
       (SELECT (SELECT COUNT(*) FROM mart.dim_customer WHERE region IS NULL)
             + (SELECT COUNT(*) FROM mart.dim_seller   WHERE region IS NULL))),

  -- Marts: facts
  (17, 'mart', 'fact_order_items rows',                  112650,
       (SELECT COUNT(*) FROM mart.fact_order_items)),
  (18, 'mart', 'T5 items flagged',                       239,
       (SELECT COUNT(*) FROM mart.fact_order_items WHERE excl_handover)),
  (19, 'mart', 'fact_orders rows',                       99441,
       (SELECT COUNT(*) FROM mart.fact_orders)),
  (20, 'mart', 'fact_orders items add up',               112650,
       (SELECT SUM(items_count) FROM mart.fact_orders)),
  (21, 'mart', 'T7 orders with review',                  98673,
       (SELECT COUNT(*) FROM mart.fact_orders WHERE has_review)),
  (22, 'mart', 'GMV gap: staging vs fact_order_items',   0,
       (SELECT (SELECT SUM(price) FROM staging.stg_order_items)
             - (SELECT SUM(price) FROM mart.fact_order_items))),
  (23, 'mart', 'GMV gap: fact_orders vs fact_order_items', 0,
       (SELECT (SELECT SUM(order_gmv) FROM mart.fact_orders)
             - (SELECT SUM(price) FROM mart.fact_order_items))),
  (24, 'mart', 'delivered orders with delivery time',    96470,
       (SELECT COUNT(delivery_days) FROM mart.fact_orders WHERE is_delivered)),
  (25, 'mart', 'negative delivery times',                0,
       (SELECT COUNT(*) FROM mart.fact_orders WHERE delivery_days < 0)),
  (26, 'mart', 'unflagged negative handover times',      0,
       (SELECT COUNT(*) FROM mart.fact_orders
         WHERE seller_handover_days < 0 AND NOT excl_carrier_leg))
) AS checks(n, layer, check_name, expected, actual)
ORDER BY n;