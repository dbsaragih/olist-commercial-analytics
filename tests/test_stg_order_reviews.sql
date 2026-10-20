-- =====================================================================
-- test_stg_order_reviews.sql
-- Checks staging.stg_order_reviews against the profiling results.
-- =====================================================================

-- 1. Rows, reviews, orders. Expect: 99224 | 98410 | 98673
SELECT COUNT(*)                  AS total_rows,
       COUNT(DISTINCT review_id) AS distinct_reviews,
       COUNT(DISTINCT order_id)  AS distinct_orders
FROM staging.stg_order_reviews;

-- 2. T6 flag. Expect: 98673 latest rows | 551 earlier rows
--    (one latest per reviewed order; 99224 - 98673 = 551)
SELECT COUNT(*) FILTER (WHERE is_latest_for_order)     AS latest_rows,
       COUNT(*) FILTER (WHERE NOT is_latest_for_order) AS earlier_rows
FROM staging.stg_order_reviews;

-- 3. Exactly one latest review per order. Expect: 0
SELECT COUNT(*) AS orders_with_wrong_latest_count
FROM (
    SELECT order_id
    FROM staging.stg_order_reviews
    GROUP BY order_id
    HAVING COUNT(*) FILTER (WHERE is_latest_for_order) <> 1
) AS t;

-- 4. Score distribution, all rows. Expect: 11424 | 3151 | 8179 | 19142 | 57328
SELECT review_score, COUNT(*) AS reviews
FROM staging.stg_order_reviews
GROUP BY review_score
ORDER BY review_score;

-- 5. Missing timestamps (not profiled before: record the result)
SELECT COUNT(*) - COUNT(review_created_ts)  AS null_created,
       COUNT(*) - COUNT(review_answered_ts) AS null_answered
FROM staging.stg_order_reviews;

-- 6. Data types. Expect: text, text, integer, text, text,
--    timestamp x2, boolean
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'staging' AND table_name = 'stg_order_reviews'
ORDER BY ordinal_position;