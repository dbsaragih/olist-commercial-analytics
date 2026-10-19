-- =====================================================================
-- 03_profile_remaining_tables.sql
-- Focused profiling of customers, order_reviews, order_payments,
-- products, category_translation and sellers.
-- Scope: only checks required by the five business questions.
-- geolocation is not profiled: not needed (customer and seller states
-- are available directly in customers and sellers).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. CUSTOMERS  (Q2 repeat buyers; Q3/Q5 regions)
-- ---------------------------------------------------------------------

-- 1a. Rows, order-level IDs and real people
SELECT
    COUNT(*)                           AS total_rows,
    COUNT(DISTINCT customer_id)        AS distinct_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS distinct_people
FROM raw.customers;

-- 1b. How many orders does each person have?
SELECT
    orders_per_person,
    COUNT(*) AS people,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_people
FROM (
    SELECT customer_unique_id, COUNT(*) AS orders_per_person
    FROM raw.customers
    GROUP BY customer_unique_id
) AS per_person
GROUP BY orders_per_person
ORDER BY orders_per_person;

-- 1c. Customers by state
SELECT
    customer_state,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM raw.customers
GROUP BY customer_state
ORDER BY customers DESC;

-- 1d. Link between orders and customers (both directions)
SELECT
    (SELECT COUNT(*) FROM raw.orders o
      WHERE NOT EXISTS (SELECT 1 FROM raw.customers c
                         WHERE c.customer_id = o.customer_id)) AS orders_without_customer,
    (SELECT COUNT(*) FROM raw.customers c
      WHERE NOT EXISTS (SELECT 1 FROM raw.orders o
                         WHERE o.customer_id = c.customer_id)) AS customers_without_order;


-- ---------------------------------------------------------------------
-- 2. ORDER_REVIEWS  (Q3, Q4, Q5 ratings)
-- ---------------------------------------------------------------------

-- 2a. Rows, reviews and orders covered
SELECT
    COUNT(*)                  AS total_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(DISTINCT order_id)  AS distinct_orders_reviewed
FROM raw.order_reviews;

-- 2b. Review score distribution
SELECT
    review_score,
    COUNT(*) AS reviews,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_reviews
FROM raw.order_reviews
GROUP BY review_score
ORDER BY review_score;


-- 2c. Orders with more than one review, and review IDs reused across orders
SELECT
    (SELECT COUNT(*) FROM (
         SELECT order_id FROM raw.order_reviews
         GROUP BY order_id HAVING COUNT(*) > 1) AS t)  AS orders_with_multiple_reviews,
    (SELECT COUNT(*) FROM (
         SELECT review_id FROM raw.order_reviews
         GROUP BY review_id HAVING COUNT(DISTINCT order_id) > 1) AS t) AS review_ids_on_multiple_orders,
    (SELECT COUNT(*) FROM raw.orders o
      WHERE NOT EXISTS (SELECT 1 FROM raw.order_reviews r
                         WHERE r.order_id = o.order_id))             AS orders_without_review;


-- ---------------------------------------------------------------------
-- 3. ORDER_PAYMENTS  (GMV cross-check)
-- ---------------------------------------------------------------------

-- 3a. Rows and orders covered
SELECT
    COUNT(*)                 AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders_paid
FROM raw.order_payments;

-- 3b. Payment types
SELECT
    payment_type,
    COUNT(*) AS payments,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_payments,
    ROUND(SUM(payment_value::numeric), 2) AS total_value
FROM raw.order_payments
GROUP BY payment_type
ORDER BY payments DESC;

-- 3c. Reconciliation: payments vs item totals (price + freight), delivered orders
WITH items AS (
    SELECT order_id,
           SUM(price::numeric + freight_value::numeric) AS item_total
    FROM raw.order_items
    GROUP BY order_id
),
pays AS (
    SELECT order_id,
           SUM(payment_value::numeric) AS paid_total
    FROM raw.order_payments
    GROUP BY order_id
)
SELECT
    COUNT(*)                                                       AS delivered_orders_compared,
    COUNT(*) FILTER (WHERE ABS(p.paid_total - i.item_total) <= 1)  AS match_within_1_brl,
    COUNT(*) FILTER (WHERE ABS(p.paid_total - i.item_total) > 1)   AS differ_by_more_than_1_brl,
    ROUND(SUM(i.item_total), 2)                                    AS sum_item_total,
    ROUND(SUM(p.paid_total), 2)                                    AS sum_paid_total
FROM raw.orders o
JOIN items i ON i.order_id = o.order_id
JOIN pays  p ON p.order_id = o.order_id
WHERE o.order_status = 'delivered';


-- ---------------------------------------------------------------------
-- 4. PRODUCTS + CATEGORY_TRANSLATION  (Q1, Q2 categories)
-- ---------------------------------------------------------------------

-- 4a. Products, missing categories, number of categories
SELECT
    COUNT(*)                                            AS total_products,
    COUNT(DISTINCT product_id)                          AS distinct_product_ids,
    COUNT(*) - COUNT(product_category_name)             AS products_without_category,
    COUNT(DISTINCT product_category_name)               AS distinct_categories
FROM raw.products;

-- 4b. Categories with no English translation
SELECT DISTINCT p.product_category_name
FROM raw.products p
WHERE p.product_category_name IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM raw.category_translation t
                   WHERE t.product_category_name = p.product_category_name)
ORDER BY 1;

-- 4c. How much of the item sales have no category? (materiality check)
SELECT
    COUNT(*) AS total_items,
    COUNT(*) FILTER (WHERE p.product_category_name IS NULL) AS items_without_category,
    ROUND(100.0 * COUNT(*) FILTER (WHERE p.product_category_name IS NULL)
          / COUNT(*), 2) AS pct_items_without_category,
    ROUND(100.0 * SUM(i.price::numeric) FILTER (WHERE p.product_category_name IS NULL)
          / SUM(i.price::numeric), 2) AS pct_value_without_category
FROM raw.order_items i
JOIN raw.products p ON p.product_id = i.product_id;


-- ---------------------------------------------------------------------
-- 5. SELLERS  (Q3, Q4 seller states)
-- ---------------------------------------------------------------------

-- 5a. Rows and key uniqueness
SELECT
    COUNT(*)                  AS total_rows,
    COUNT(DISTINCT seller_id) AS distinct_sellers
FROM raw.sellers;

-- 5b. Sellers by state
SELECT
    seller_state,
    COUNT(*) AS sellers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_sellers
FROM raw.sellers
GROUP BY seller_state
ORDER BY sellers DESC;