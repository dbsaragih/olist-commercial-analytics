-- =====================================================================
-- 01_profile_order_items.sql
-- Data profiling of raw.orders_items (all columns stored as text in raw)
-- =====================================================================

-- 1.a Row count and key uniqueness
SELECT
    COUNT(*)                    AS total_rows,
    COUNT(DISTINCT order_id)    AS distinct_order_ids,
    COUNT(DISTINCT oi.product_id ) AS distinct_product_ids,
    count(distinct seller_id)	as seller_ids
FROM raw.order_items oi ;


-- 1.b Duplicate composite key (order_id, order_item_id)
select order_id, btrim(order_item_id), 
count(*) as cnt
from raw.order_items oi 
group by order_id, btrim(order_item_id) 
having count(*) > 1
order by cnt desc; 


-- 1.c How many duplicate group in total?
select count(*) as duplicate_key_group
from (
	select order_id, order_item_id
	from raw.order_items oi 
	group by order_id, oi.order_item_id 
	having count(*)>1
);



-- 2. Missing values (NULLs) per column
SELECT
    COUNT(*) - COUNT(order_id)             AS null_order_id,
    COUNT(*) - COUNT(order_item_id)        AS null_order_item_id,
    COUNT(*) - COUNT(product_id)           AS null_product_id,
    COUNT(*) - COUNT(seller_id)            AS null_seller_id,
    COUNT(*) - COUNT(shipping_limit_date)  AS null_shipping_limit_id,
    COUNT(*) - COUNT(price)                AS null_price,
    COUNT(*) - COUNT(freight_value)        AS null_freight_value
from raw.order_items oi 


-- 3. Order_item_id distribution
SELECT
    order_item_id,
    COUNT(*) AS order_item,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM raw.order_items oi 
GROUP BY oi.order_item_id 
ORDER BY pct_of_total   desc;


-- 4. Numeric conversion validation (price, freight_value)
--4.1 How many rows fail numeric cast (non numeric characters like ',' or '$')
select 
	count(*) filter (where price !~ '^[0-9]+(\.[0-9]+)?$')  as price_non_numeric,
	count(*) filter (where freight_value !~ '^[0-9]+(\.[0-9]+)?$') as freight_non_numeric
from raw.order_items;

-- 4.2 Sample offending rows
SELECT order_id, order_item_id, price, freight_value
FROM raw.order_items
WHERE price !~ '^[0-9]+(\.[0-9]+)?$'
   OR freight_value !~ '^[0-9]+(\.[0-9]+)?$'
LIMIT 20;

-- 4.3 Numeric statistics (safe cast via NULLIF + regex filter)
WITH cleaned AS (
    SELECT
        price::numeric         AS price,
        freight_value::numeric AS freight
    FROM raw.order_items
    WHERE price         ~ '^[0-9]+(\.[0-9]+)?$'
      AND freight_value ~ '^[0-9]+(\.[0-9]+)?$'
)
SELECT
    COUNT(*)                                   AS n,
    MIN(price)                                 AS price_min,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS price_p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price) AS price_p50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS price_p75,
    MAX(price)                                 AS price_max,
    AVG(price)                                 AS price_avg,
    MIN(freight)                               AS freight_min,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY freight) AS freight_p50,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY freight) AS freight_p95,
    MAX(freight)                               AS freight_max,
    AVG(freight)                               AS freight_avg
FROM cleaned;

-- 4.4 Zero / negative checks
WITH cleaned AS (
    SELECT price::numeric AS price, freight_value::numeric AS freight
    FROM raw.order_items
    WHERE price         ~ '^[0-9]+(\.[0-9]+)?$'
      AND freight_value ~ '^[0-9]+(\.[0-9]+)?$'
)
SELECT
    COUNT(*) FILTER (WHERE price   =  0) AS price_zero,
    COUNT(*) FILTER (WHERE price   <  0) AS price_negative,
    COUNT(*) FILTER (WHERE freight =  0) AS freight_zero,
    COUNT(*) FILTER (WHERE freight >  price) AS freight_greater_than_price,
    COUNT(*) FILTER (WHERE freight >  0 AND price > 0) AS freight_ratio_denominator
FROM cleaned;


--5. Date format validation (shipping_limit_date)
-- 5.1 Rows that fail timestamp cast
SELECT COUNT(*) AS shipping_limit_date_unparseable
FROM raw.order_items
WHERE shipping_limit_date !~ '^\d{4}-\d{2}-\d{2}( \d{2}:\d{2}:\d{2})?$';

-- 5.2 Sample offending rows
SELECT order_id, order_item_id, shipping_limit_date
FROM raw.order_items
WHERE shipping_limit_date !~ '^\d{4}-\d{2}-\d{2}( \d{2}:\d{2}:\d{2})?$'
LIMIT 20;

-- 5.3 Date range
-- Olist timestamps carry no time zone, so cast with ::timestamp
-- (not ::timestamptz, which would apply the session time zone).
SELECT
    MIN(shipping_limit_date::timestamp) AS min_ts,
    MAX(shipping_limit_date::timestamp) AS max_ts
FROM raw.order_items
WHERE shipping_limit_date ~ '^\d{4}-\d{2}-\d{2}( \d{2}:\d{2}:\d{2})?$';


--6. Referential integrity 
-- 6.1 Orphan order_items (order_id not in raw.orders)
SELECT COUNT(*) AS orphan_rows_by_order,
       COUNT(DISTINCT oi.order_id) AS orphan_distinct_orders,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM raw.order_items), 2) AS pct_of_table
FROM raw.order_items oi
LEFT JOIN raw.orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 6.2 Orphan products
SELECT COUNT(*) AS orphan_rows_by_product
FROM raw.order_items oi
LEFT JOIN raw.products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 6.3 Orphan sellers
SELECT COUNT(*) AS orphan_rows_by_seller
FROM raw.order_items oi
LEFT JOIN raw.sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


--7. Seller & product concentration
-- 7.1 Top 20 sellers by number of line items
SELECT seller_id, COUNT(*) AS line_items, SUM(price::numeric) AS revenue
FROM raw.order_items
WHERE price ~ '^[0-9]+(\.[0-9]+)?$'
GROUP BY seller_id
ORDER BY line_items DESC
LIMIT 20; 


-- 7.2 Seller revenue share from top N sellers (concentration ratio)
WITH seller_rev AS (
    SELECT seller_id, SUM(price::numeric) AS revenue
    FROM raw.order_items
    WHERE price ~ '^[0-9]+(\.[0-9]+)?$'
    GROUP BY seller_id
),
ranked AS (
    SELECT seller_id, revenue,
           ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rn,
           SUM(revenue) OVER ()                      AS total
    FROM seller_rev
)
SELECT
    ROUND(100.0 * SUM(revenue) FILTER (WHERE rn <=  10) / MAX(total), 2) AS top10_pct,
    ROUND(100.0 * SUM(revenue) FILTER (WHERE rn <=  50) / MAX(total), 2) AS top50_pct,
    ROUND(100.0 * SUM(revenue) FILTER (WHERE rn <= 100) / MAX(total), 2) AS top100_pct
FROM ranked;



-- 7x. Follow-up checks

-- 7a. Orders without any items, by status
SELECT
    o.order_status,
    COUNT(*) AS orders_without_items
FROM raw.orders o
WHERE NOT EXISTS (SELECT 1 FROM raw.order_items i
                   WHERE i.order_id = o.order_id)
GROUP BY o.order_status
ORDER BY orders_without_items DESC;

-- 7b. Items per order (true order-level distribution)
SELECT
    items_in_order,
    COUNT(*) AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM (
    SELECT order_id, COUNT(*) AS items_in_order
    FROM raw.order_items
    GROUP BY order_id
) AS per_order
GROUP BY items_in_order
ORDER BY items_in_order;

-- 7c. Shipping deadline anomalies (compared with purchase date)
SELECT
    COUNT(*) AS total_items,
    COUNT(*) FILTER (WHERE i.shipping_limit_date::timestamp
                         < o.order_purchase_timestamp::timestamp)            AS limit_before_purchase,
    COUNT(*) FILTER (WHERE i.shipping_limit_date::timestamp
                         > o.order_purchase_timestamp::timestamp
                           + INTERVAL '30 days')                            AS limit_over_30d_after_purchase,
    COUNT(*) FILTER (WHERE i.shipping_limit_date::timestamp > '2018-12-31') AS limit_after_2018
FROM raw.order_items i
JOIN raw.orders o ON o.order_id = i.order_id;



















