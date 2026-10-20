-- =====================================================================
-- stg_orders.sql
-- Staging view for raw.orders: typed columns, consistent names, and
-- flags for decision-log treatments T1, T3 and T4
-- (see docs/02_data_quality_findings.md).
-- Olist timestamps carry no time zone, so cast with ::timestamp.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS staging;

DROP VIEW IF EXISTS staging.stg_orders CASCADE;

CREATE VIEW staging.stg_orders AS
SELECT
    -- Keys and status
    order_id,
    customer_id,
    order_status,

    -- Timestamps (text -> timestamp / date)
    order_purchase_timestamp::timestamp            AS purchase_ts,
    order_approved_at::timestamp                   AS approved_ts,
    order_delivered_carrier_date::timestamp        AS carrier_handover_ts,
    order_delivered_customer_date::timestamp       AS delivered_ts,
    order_estimated_delivery_date::timestamp::date AS estimated_delivery_date,

    -- Status flag
    (order_status = 'delivered')                   AS is_delivered,

    -- T1: analysis period Jan 2017 - Aug 2018
    (order_purchase_timestamp::timestamp >= '2017-01-01'
     AND order_purchase_timestamp::timestamp <  '2018-09-01')
                                                   AS in_analysis_period,

    -- T3: delivered but no delivery date -> exclude from delivery-time analysis
    (order_status = 'delivered'
     AND order_delivered_customer_date IS NULL)    AS excl_delivery_time,

    -- T4: carrier pickup before purchase -> exclude from seller-vs-carrier split
    COALESCE(order_delivered_carrier_date::timestamp
             < order_purchase_timestamp::timestamp, FALSE)
                                                   AS excl_carrier_leg
FROM raw.orders;