-- =============================================================
-- BQ5. Freight cost by region
-- Scope: delivered orders, analysis period Jan 2017 - Aug 2018
-- Freight share = freight / (item price + freight)
-- Rule: freight share is non-additive -> ratio of sums, never AVG
-- =============================================================

-- -------------------------------------------------------------
-- Q1. Freight share by customer region (business view)
--     avg_of_item_shares_pct is shown ONLY to demonstrate the error
-- -------------------------------------------------------------
SELECT
    COALESCE(i.delivery_region, 'Total')                                   AS customer_region,
    COUNT(*)                                                               AS items,
    COUNT(DISTINCT i.order_id)                                             AS orders,
    ROUND(SUM(i.price), 2)                                                 AS gmv,
    ROUND(SUM(i.freight_value), 2)                                         AS freight,
    ROUND(100.0 * SUM(i.freight_value) / SUM(i.price + i.freight_value), 1) AS freight_share_pct,
    ROUND(100.0 * AVG(i.freight_share), 1)                                 AS avg_of_item_shares_pct,
    ROUND(AVG(i.price), 2)                                                 AS avg_item_price,
    ROUND(AVG(i.freight_value), 2)                                         AS avg_freight_per_item
FROM mart.fact_order_items i
JOIN mart.dim_date d ON d.date_key = i.purchase_date_key
WHERE i.is_delivered
  AND d.in_analysis_period
GROUP BY ROLLUP (i.delivery_region)
ORDER BY GROUPING(i.delivery_region), freight_share_pct DESC;

-- -------------------------------------------------------------
-- Q2. What customers experience: order-level distribution
-- -------------------------------------------------------------
WITH order_share AS (
    SELECT
        r.region,
        o.order_freight / NULLIF(o.order_gmv + o.order_freight, 0) AS freight_share
    FROM mart.fact_orders o
    JOIN mart.dim_date d ON d.date_key = o.purchase_date_key
    LEFT JOIN staging.stg_state_region r ON r.state = o.delivery_state
    WHERE o.is_delivered
      AND d.in_analysis_period
)
SELECT
    COALESCE(region, 'Total')                                              AS customer_region,
    COUNT(*)                                                               AS orders,
    ROUND(100 * PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY freight_share)::numeric, 1)
                                                                           AS median_order_share_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE freight_share > 0.25) / COUNT(*), 1) AS orders_over_25pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE freight_share > 0.40) / COUNT(*), 1) AS orders_over_40pct
FROM order_share
GROUP BY ROLLUP (region)
ORDER BY GROUPING(region), orders_over_25pct DESC;

-- -------------------------------------------------------------
-- Q3. Mix check: freight share by item price band and region
--     (ratio of sums within each cell)
-- -------------------------------------------------------------
WITH items AS (
    SELECT
        i.delivery_region AS region,
        i.price,
        i.freight_value,
        CASE
            WHEN i.price <  50 THEN '1. Under R$ 50'
            WHEN i.price < 100 THEN '2. R$ 50-99'
            WHEN i.price < 200 THEN '3. R$ 100-199'
            ELSE                    '4. R$ 200 and over'
        END AS price_band
    FROM mart.fact_order_items i
    JOIN mart.dim_date d ON d.date_key = i.purchase_date_key
    WHERE i.is_delivered
      AND d.in_analysis_period
)
SELECT
    price_band,
    COUNT(*) AS items,
    ROUND(100.0 * SUM(freight_value) FILTER (WHERE region = 'North')
          / SUM(price + freight_value) FILTER (WHERE region = 'North'), 1)       AS north,
    ROUND(100.0 * SUM(freight_value) FILTER (WHERE region = 'Northeast')
          / SUM(price + freight_value) FILTER (WHERE region = 'Northeast'), 1)   AS northeast,
    ROUND(100.0 * SUM(freight_value) FILTER (WHERE region = 'Center-West')
          / SUM(price + freight_value) FILTER (WHERE region = 'Center-West'), 1) AS center_west,
    ROUND(100.0 * SUM(freight_value) FILTER (WHERE region = 'Southeast')
          / SUM(price + freight_value) FILTER (WHERE region = 'Southeast'), 1)   AS southeast,
    ROUND(100.0 * SUM(freight_value) FILTER (WHERE region = 'South')
          / SUM(price + freight_value) FILTER (WHERE region = 'South'), 1)       AS south,
    ROUND(100.0 * SUM(freight_value) / SUM(price + freight_value), 1)            AS all_regions
FROM items
GROUP BY price_band
ORDER BY price_band;

-- -------------------------------------------------------------
-- Q4. Lanes: seller region -> customer region (lanes with 100+ items)
-- -------------------------------------------------------------
SELECT
    s.region                                                               AS seller_region,
    i.delivery_region                                                      AS customer_region,
    COUNT(*)                                                               AS items,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)                     AS share_of_items_pct,
    ROUND(AVG(i.freight_value), 2)                                         AS avg_freight_per_item,
    ROUND(100.0 * SUM(i.freight_value) / SUM(i.price + i.freight_value), 1) AS freight_share_pct
FROM mart.fact_order_items i
JOIN mart.dim_date   d ON d.date_key  = i.purchase_date_key
JOIN mart.dim_seller s ON s.seller_id = i.seller_id
WHERE i.is_delivered
  AND d.in_analysis_period
GROUP BY s.region, i.delivery_region
HAVING COUNT(*) >= 100
ORDER BY items DESC;