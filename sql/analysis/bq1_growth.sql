-- =====================================================================
-- bq1_growth.sql
-- BQ1: Which categories drove GMV growth, and was growth driven by
--      more orders (volume) or higher spend per order (AOV)?
-- GMV = item price, excluding freight, delivered orders only.
-- Growth compares Jan-Aug 2017 with Jan-Aug 2018 (like-for-like).
-- =====================================================================


-- ---------------------------------------------------------------------
-- Q1. Monthly trend: orders, GMV, AOV, items per order
--     Analysis period Jan 2017 - Aug 2018, delivered orders
-- ---------------------------------------------------------------------
SELECT
    d.year_month,
    COUNT(*)                                                  AS orders,
    ROUND(SUM(f.order_gmv), 2)                                AS gmv,
    ROUND(SUM(f.order_gmv) / COUNT(*), 2)                     AS aov,
    ROUND(SUM(f.items_count)::numeric / COUNT(*), 3)          AS items_per_order,
    ROUND(100.0 * (SUM(f.order_gmv)
          / LAG(SUM(f.order_gmv)) OVER (ORDER BY d.year_month) - 1), 1)
                                                              AS gmv_mom_pct
FROM mart.fact_orders f
JOIN mart.dim_date d ON d.date_key = f.purchase_date_key
WHERE f.is_delivered
  AND d.in_analysis_period
GROUP BY d.year_month
ORDER BY d.year_month;


-- ---------------------------------------------------------------------
-- Q2. Growth decomposition: Jan-Aug 2017 vs Jan-Aug 2018
--     GMV change = volume effect + basket (AOV) effect + interaction
-- ---------------------------------------------------------------------
WITH by_year AS (
    SELECT
        d.year,
        COUNT(*)            AS orders,
        SUM(f.order_gmv)    AS gmv,
        SUM(f.items_count)  AS items
    FROM mart.fact_orders f
    JOIN mart.dim_date d ON d.date_key = f.purchase_date_key
    WHERE f.is_delivered
      AND d.year IN (2017, 2018)
      AND d.month BETWEEN 1 AND 8
    GROUP BY d.year
),
p AS (
    -- Pivot: one row with 2017 and 2018 side by side
    SELECT
        MAX(orders) FILTER (WHERE year = 2017) AS o0,
        MAX(orders) FILTER (WHERE year = 2018) AS o1,
        MAX(gmv)    FILTER (WHERE year = 2017) AS g0,
        MAX(gmv)    FILTER (WHERE year = 2018) AS g1,
        MAX(items)  FILTER (WHERE year = 2017) AS i0,
        MAX(items)  FILTER (WHERE year = 2018) AS i1
    FROM by_year
)
SELECT
    o0                                                AS orders_2017,
    o1                                                AS orders_2018,
    ROUND(g0, 2)                                      AS gmv_2017,
    ROUND(g1, 2)                                      AS gmv_2018,
    ROUND(g1 - g0, 2)                                 AS gmv_change,
    ROUND(100 * (g1 / g0 - 1), 1)                     AS gmv_growth_pct,
    ROUND(g0 / o0, 2)                                 AS aov_2017,
    ROUND(g1 / o1, 2)                                 AS aov_2018,
    ROUND((o1 - o0) * (g0 / o0), 2)                   AS volume_effect,
    ROUND(o0 * (g1 / o1 - g0 / o0), 2)                AS basket_effect,
    ROUND((o1 - o0) * (g1 / o1 - g0 / o0), 2)         AS interaction,
    ROUND(100 * (o1 - o0) * (g0 / o0) / (g1 - g0), 1) AS volume_share_pct,
    ROUND(i0::numeric / o0, 3)                        AS items_per_order_2017,
    ROUND(i1::numeric / o1, 3)                        AS items_per_order_2018,
    ROUND(g0 / i0, 2)                                 AS avg_item_price_2017,
    ROUND(g1 / i1, 2)                                 AS avg_item_price_2018
FROM p;


-- ---------------------------------------------------------------------
-- Q3. Category contribution to growth: Jan-Aug 2017 vs Jan-Aug 2018
--     Sorted by GMV change, with cumulative share of total growth
-- ---------------------------------------------------------------------
WITH cat AS (
    SELECT
        p.category_name_en                                        AS category,
        COALESCE(SUM(i.price) FILTER (WHERE d.year = 2017), 0)    AS gmv_2017,
        COALESCE(SUM(i.price) FILTER (WHERE d.year = 2018), 0)    AS gmv_2018
    FROM mart.fact_order_items i
    JOIN mart.dim_date    d ON d.date_key   = i.purchase_date_key
    JOIN mart.dim_product p ON p.product_id = i.product_id
    WHERE i.is_delivered
      AND d.year IN (2017, 2018)
      AND d.month BETWEEN 1 AND 8
    GROUP BY p.category_name_en
),
change AS (
    SELECT
        category,
        gmv_2017,
        gmv_2018,
        gmv_2018 - gmv_2017                                       AS gmv_change,
        100 * (gmv_2018 - gmv_2017) / SUM(gmv_2018 - gmv_2017) OVER ()
                                                                  AS share_of_growth
    FROM cat
)
SELECT
    RANK() OVER (ORDER BY gmv_change DESC)                        AS rnk,
    category,
    ROUND(gmv_2017, 2)                                            AS gmv_2017,
    ROUND(gmv_2018, 2)                                            AS gmv_2018,
    ROUND(gmv_change, 2)                                          AS gmv_change,
    ROUND(100 * gmv_2018 / NULLIF(gmv_2017, 0) - 100, 1)          AS category_growth_pct,
    ROUND(share_of_growth, 1)                                     AS share_of_growth_pct,
    ROUND(SUM(share_of_growth) OVER (ORDER BY gmv_change DESC
                                     ROWS UNBOUNDED PRECEDING), 1) AS cumulative_share_pct
FROM change
ORDER BY gmv_change DESC
LIMIT 15;