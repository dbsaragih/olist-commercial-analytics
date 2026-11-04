-- =====================================================================
-- seller_value.sql
-- Seller-grain table: one row per seller with delivered GMV in the
-- analysis period (Jan 2017 - Aug 2018). Single source for BQ4.
-- Rules:
--   * gmv_rank / gmv_decile rank all sellers (decile 1 = top 10%),
--     seller_id breaks ties so ranks are deterministic
--   * service counts are item-weighted and exclude T3; Power BI divides
--     the counts (ratio of sums), never averages rates
-- =====================================================================

DROP TABLE IF EXISTS mart.seller_value CASCADE;

CREATE TABLE mart.seller_value AS
WITH items AS (
    SELECT i.seller_id,
           i.order_id,
           i.price,
           o.is_late,
           o.is_handover_late,
           o.excl_delivery_time
    FROM mart.fact_order_items i
    JOIN mart.dim_date d    ON d.date_key = i.purchase_date_key
    JOIN mart.fact_orders o ON o.order_id = i.order_id
    WHERE i.is_delivered
      AND d.in_analysis_period
),
agg AS (
    SELECT seller_id,
           SUM(price)                                                  AS gmv,
           COUNT(DISTINCT order_id)                                    AS orders,
           COUNT(*)                                                    AS items,
           COUNT(*) FILTER (WHERE NOT excl_delivery_time)              AS timed_items,
           COUNT(*) FILTER (WHERE NOT excl_delivery_time AND is_late)  AS late_items,
           COUNT(*) FILTER (WHERE NOT excl_delivery_time
                              AND is_handover_late)                    AS handover_late_items
    FROM items
    GROUP BY seller_id
)
SELECT
    seller_id,
    gmv,
    orders,
    items,
    timed_items,
    late_items,
    handover_late_items,
    ROW_NUMBER() OVER (ORDER BY gmv DESC, seller_id) AS gmv_rank,
    NTILE(10)    OVER (ORDER BY gmv DESC, seller_id) AS gmv_decile,
    CASE
        WHEN gmv <  1000 THEN '1. Under R$ 1k'
        WHEN gmv < 10000 THEN '2. R$ 1k-10k'
        WHEN gmv < 50000 THEN '3. R$ 10k-50k'
        ELSE                  '4. R$ 50k and over'
    END                                              AS gmv_band,
    (orders = 1)                                     AS is_one_order_seller
FROM agg;

ALTER TABLE mart.seller_value
    ADD PRIMARY KEY (seller_id),
    ADD CONSTRAINT fk_sv_seller FOREIGN KEY (seller_id)
        REFERENCES mart.dim_seller (seller_id);