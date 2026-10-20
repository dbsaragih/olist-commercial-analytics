-- =====================================================================
-- test_stg_reference_tables.sql
-- Checks stg_customers, stg_sellers, stg_products and
-- stg_category_translation against the profiling results.
-- =====================================================================

-- 1. Customers. Expect: 99441 | 99441 | 96096 | 27 | 41746
SELECT COUNT(*)                            AS total_rows,
       COUNT(DISTINCT customer_id)         AS distinct_customer_ids,
       COUNT(DISTINCT customer_unique_id)  AS distinct_people,
       COUNT(DISTINCT state)               AS states,
       COUNT(*) FILTER (WHERE state = 'SP') AS sp_customers
FROM staging.stg_customers;

-- 2. Leading zeros kept. Expect: a number greater than 0
SELECT COUNT(*) AS zips_starting_with_zero
FROM staging.stg_customers
WHERE zip_code_prefix LIKE '0%';

-- 3. Sellers. Expect: 3095 | 3095 | 23 | 1849
SELECT COUNT(*)                             AS total_rows,
       COUNT(DISTINCT seller_id)            AS distinct_sellers,
       COUNT(DISTINCT state)                AS states,
       COUNT(*) FILTER (WHERE state = 'SP') AS sp_sellers
FROM staging.stg_sellers;

-- 4. Products. Expect: 32951 | 32951 | 610 | 74
SELECT COUNT(*)                                        AS total_rows,
       COUNT(DISTINCT product_id)                      AS distinct_products,
       COUNT(*) FILTER (WHERE category_name = 'unknown') AS unknown_category,
       COUNT(DISTINCT category_name)                   AS categories
FROM staging.stg_products;

-- 5. Translation table. Expect: 74 | 74
SELECT COUNT(*)                       AS total_rows,
       COUNT(DISTINCT category_name)  AS distinct_categories
FROM staging.stg_category_translation;

-- 6. Every product category has a translation. Expect: 0
SELECT COUNT(*) AS products_without_translation
FROM staging.stg_products p
WHERE NOT EXISTS (SELECT 1 FROM staging.stg_category_translation t
                   WHERE t.category_name = p.category_name);