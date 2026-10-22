-- =====================================================================
-- dim_date.sql
-- Date dimension: one row per calendar day, 2016-01-01 to 2018-12-31.
-- Full calendar years with no gaps, as Power BI time intelligence requires.
-- date_key is a smart key (YYYYMMDD).
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.dim_date CASCADE;

CREATE TABLE mart.dim_date AS
SELECT
    TO_CHAR(d, 'YYYYMMDD')::int           AS date_key,
    d::date                               AS full_date,
    EXTRACT(YEAR    FROM d)::int          AS year,
    EXTRACT(QUARTER FROM d)::int          AS quarter,
    EXTRACT(MONTH   FROM d)::int          AS month,
    TO_CHAR(d, 'Mon')                     AS month_short,
    TO_CHAR(d, 'YYYY-MM')                 AS year_month,
    DATE_TRUNC('month', d)::date          AS month_start,
    EXTRACT(ISODOW  FROM d)::int          AS weekday_number,   -- 1 = Monday
    TO_CHAR(d, 'Dy')                      AS weekday_short,
    (EXTRACT(ISODOW FROM d) >= 6)         AS is_weekend,
    (d >= '2017-01-01' AND d < '2018-09-01') AS in_analysis_period   -- T1
FROM generate_series('2016-01-01'::timestamp,
                     '2018-12-31'::timestamp,
                     INTERVAL '1 day') AS d;

ALTER TABLE mart.dim_date ADD PRIMARY KEY (date_key);