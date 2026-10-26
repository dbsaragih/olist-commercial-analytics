-- =============================================================
-- BQ4. Seller concentration
-- Scope: delivered orders, analysis period Jan 2017 - Aug 2018
-- GMV = item price excluding freight (BRL)
-- =============================================================

-- -------------------------------------------------------------
-- Q1. GMV by seller decile (decile 1 = top 10% of sellers)
-- -------------------------------------------------------------
WITH seller_gmv AS (
    SELECT
        i.seller_id,
        SUM(i.price)               AS gmv,
        COUNT(DISTINCT i.order_id) AS orders
    FROM mart.fact_order_items i
    JOIN mart.dim_date d ON d.date_key = i.purchase_date_key
    WHERE i.is_delivered
      AND d.in_analysis_period
    GROUP BY i.seller_id
),
ranked AS (
    SELECT *,
        NTILE(10)    OVER (ORDER BY gmv DESC, seller_id) AS decile,
        ROW_NUMBER() OVER (ORDER BY gmv DESC, seller_id) AS seller_rank
    FROM seller_gmv
)
SELECT
    decile,
    COUNT(*)                                                     AS sellers,
    SUM(orders)                                                  AS seller_orders,
    ROUND(SUM(gmv), 2)                                           AS gmv,
    ROUND(100.0 * SUM(gmv) / SUM(SUM(gmv)) OVER (), 1)           AS gmv_share_pct,
    ROUND(100.0 * SUM(SUM(gmv)) OVER (ORDER BY decile ROWS UNBOUNDED PRECEDING)
          / SUM(SUM(gmv)) OVER (), 1)                            AS cumulative_share_pct,
    ROUND(MIN(gmv), 2)                                           AS smallest_seller_gmv,
    ROUND(MAX(gmv), 2)                                           AS largest_seller_gmv
FROM ranked
GROUP BY decile
ORDER BY decile;

-- -------------------------------------------------------------
-- Q2. Concentration summary: top-N shares, HHI, equivalent sellers
--     HHI = sum of squared % shares (0 to 10,000)
-- -------------------------------------------------------------
WITH seller_gmv AS (
    SELECT
        i.seller_id,
        SUM(i.price)               AS gmv,
        COUNT(DISTINCT i.order_id) AS orders
    FROM mart.fact_order_items i
    JOIN mart.dim_date d ON d.date_key = i.purchase_date_key
    WHERE i.is_delivered
      AND d.in_analysis_period
    GROUP BY i.seller_id
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY gmv DESC, seller_id) AS seller_rank,
        100.0 * gmv / SUM(gmv) OVER ()                   AS share_pct
    FROM seller_gmv
)
SELECT
    COUNT(*)                                                           AS active_sellers,
    ROUND(SUM(gmv), 2)                                                 AS total_gmv,
    ROUND(SUM(share_pct) FILTER (WHERE seller_rank <= 10), 1)          AS top_10_sellers_pct,
    ROUND(SUM(share_pct) FILTER (WHERE seller_rank <= 50), 1)          AS top_50_sellers_pct,
    ROUND(SUM(share_pct) FILTER (WHERE seller_rank <= 100), 1)         AS top_100_sellers_pct,
    ROUND(SUM(share_pct * share_pct), 1)                               AS hhi,
    ROUND(10000 / SUM(share_pct * share_pct), 0)                       AS equivalent_sellers
FROM ranked;

-- -------------------------------------------------------------
-- Q3. The long tail: sellers by GMV band
-- -------------------------------------------------------------
WITH seller_gmv AS (
    SELECT
        i.seller_id,
        SUM(i.price)               AS gmv,
        COUNT(DISTINCT i.order_id) AS orders
    FROM mart.fact_order_items i
    JOIN mart.dim_date d ON d.date_key = i.purchase_date_key
    WHERE i.is_delivered
      AND d.in_analysis_period
    GROUP BY i.seller_id
)
SELECT
    CASE
        WHEN gmv <  1000  THEN '1. Under R$ 1k'
        WHEN gmv < 10000  THEN '2. R$ 1k-10k'
        WHEN gmv < 50000  THEN '3. R$ 10k-50k'
        ELSE                   '4. R$ 50k and over'
    END                                                    AS gmv_band,
    COUNT(*)                                               AS sellers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)     AS seller_share_pct,
    ROUND(SUM(gmv), 2)                                     AS gmv,
    ROUND(100.0 * SUM(gmv) / SUM(SUM(gmv)) OVER (), 1)     AS gmv_share_pct,
    ROUND(AVG(orders), 1)                                  AS avg_orders_per_seller,
    COUNT(*) FILTER (WHERE orders = 1)                     AS one_order_sellers
FROM seller_gmv
GROUP BY 1
ORDER BY 1;

-- -------------------------------------------------------------
-- Q4. Like-for-like Jan-Aug 2017 vs 2018: more sellers or bigger sellers?
-- -------------------------------------------------------------
WITH seller_year AS (
    SELECT
        d.year,
        i.seller_id,
        SUM(i.price) AS gmv
    FROM mart.fact_order_items i
    JOIN mart.dim_date d ON d.date_key = i.purchase_date_key
    WHERE i.is_delivered
      AND d.year IN (2017, 2018)
      AND d.month <= 8
    GROUP BY d.year, i.seller_id
),
ranked AS (
    SELECT *,
        NTILE(10) OVER (PARTITION BY year ORDER BY gmv DESC, seller_id) AS decile
    FROM seller_year
)
SELECT
    year,
    COUNT(*)                                                         AS active_sellers,
    ROUND(SUM(gmv), 2)                                               AS gmv,
    ROUND(SUM(gmv) / COUNT(*), 2)                                    AS gmv_per_seller,
    ROUND(100.0 * SUM(gmv) FILTER (WHERE decile = 1) / SUM(gmv), 1)  AS top_decile_share_pct
FROM ranked
GROUP BY year
ORDER BY year;

-- -------------------------------------------------------------
-- Q5. Service quality by seller decile (item-weighted rates)
--     Joins the two facts at item grain: rates only, never sum order measures
-- -------------------------------------------------------------
WITH seller_gmv AS (
    SELECT
        i.seller_id,
        SUM(i.price) AS gmv
    FROM mart.fact_order_items i
    JOIN mart.dim_date d ON d.date_key = i.purchase_date_key
    WHERE i.is_delivered
      AND d.in_analysis_period
    GROUP BY i.seller_id
),
ranked AS (
    SELECT seller_id,
        NTILE(10) OVER (ORDER BY gmv DESC, seller_id) AS decile
    FROM seller_gmv
)
SELECT
    r.decile,
    COUNT(*)                                                               AS items,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.is_late) / COUNT(*), 1)         AS late_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.is_handover_late) / COUNT(*), 1) AS handover_late_pct,
    ROUND(AVG(o.review_score), 2)                                          AS avg_score
FROM mart.fact_order_items i
JOIN mart.dim_date d   ON d.date_key  = i.purchase_date_key
JOIN mart.fact_orders o ON o.order_id = i.order_id
JOIN ranked r          ON r.seller_id = i.seller_id
WHERE i.is_delivered
  AND d.in_analysis_period
  AND NOT o.excl_delivery_time
GROUP BY r.decile
ORDER BY r.decile;