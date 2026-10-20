-- =====================================================================
-- stg_order_reviews.sql
-- Staging view for raw.order_reviews: typed columns, consistent names.
-- Grain: one row per (review, order) pair. One review can cover several
-- orders, and some orders have several reviews.
-- T6: flag the most recent review per order (is_latest_for_order).
--     All rows are kept; the mart uses only the flagged review.
-- T7 (orders without a review) is handled in the mart (has_review).
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS staging;

DROP VIEW IF EXISTS staging.stg_order_reviews CASCADE;

CREATE VIEW staging.stg_order_reviews AS
SELECT
    review_id,
    order_id,
    review_score::int                         AS review_score,
    review_comment_title                      AS comment_title,
    review_comment_message                    AS comment_message,
    review_creation_date::timestamp           AS review_created_ts,
    review_answer_timestamp::timestamp        AS review_answered_ts,

    -- T6: most recent review per order = TRUE
    ROW_NUMBER() OVER (
        PARTITION BY order_id
        ORDER BY review_answer_timestamp::timestamp DESC NULLS LAST,
                 review_creation_date::timestamp    DESC NULLS LAST,
                 review_id                          DESC
    ) = 1                                     AS is_latest_for_order
FROM raw.order_reviews;