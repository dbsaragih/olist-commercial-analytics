
-- =====================================================================
-- 01_profile_orders.sql
-- Data profiling of raw.orders (all columns stored as text in raw)
-- =====================================================================

-- 1. Row count and key uniqueness
SELECT
    COUNT(*)                    AS total_rows,
    COUNT(DISTINCT order_id)    AS distinct_order_ids,
    COUNT(DISTINCT customer_id) AS distinct_customer_ids
FROM raw.orders;

-- 2. Missing values (NULLs) per column
SELECT
    COUNT(*) - COUNT(order_id)                      AS null_order_id,
    COUNT(*) - COUNT(customer_id)                   AS null_customer_id,
    COUNT(*) - COUNT(order_status)                  AS null_status,
    COUNT(*) - COUNT(order_purchase_timestamp)      AS null_purchase_ts,
    COUNT(*) - COUNT(order_approved_at)             AS null_approved_at,
    COUNT(*) - COUNT(order_delivered_carrier_date)  AS null_carrier_date,
    COUNT(*) - COUNT(order_delivered_customer_date) AS null_customer_date,
    COUNT(*) - COUNT(order_estimated_delivery_date) AS null_estimated_date
FROM raw.orders;

-- 3. Order status distribution
SELECT
    order_status,
    COUNT(*) AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM raw.orders
GROUP BY order_status
ORDER BY orders DESC;

-- 4. Orders per month (actual date coverage)
SELECT
    DATE_TRUNC('month', order_purchase_timestamp::timestamp)::date AS purchase_month,
    COUNT(*) AS orders
FROM raw.orders
GROUP BY 1
ORDER BY 1;

-- 5. Logical consistency checks
SELECT
    COUNT(*) FILTER (WHERE order_status = 'delivered'
                       AND order_delivered_customer_date IS NULL)  AS delivered_without_date,
    COUNT(*) FILTER (WHERE order_status <> 'delivered'
                       AND order_delivered_customer_date IS NOT NULL) AS not_delivered_but_dated,
    COUNT(*) FILTER (WHERE order_delivered_customer_date::timestamp
                         < order_purchase_timestamp::timestamp)    AS delivered_before_purchase,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date::timestamp
                         < order_purchase_timestamp::timestamp)    AS carrier_before_purchase
FROM raw.orders;