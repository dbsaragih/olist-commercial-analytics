-- =====================================================================
-- stg_category_translation.sql
-- Staging view for raw.category_translation (Portuguese -> English).
-- T9: two categories have no translation in the source; added manually.
-- 'unknown' added so products labelled by T8 still find a match.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS staging;

DROP VIEW IF EXISTS staging.stg_category_translation CASCADE;

CREATE VIEW staging.stg_category_translation AS
SELECT
    product_category_name           AS category_name,
    product_category_name_english   AS category_name_en
FROM raw.category_translation

UNION ALL

-- Manual additions (T9 and T8)
SELECT category_name, category_name_en
FROM (VALUES
    ('pc_gamer',                                       'pc_gamer'),
    ('portateis_cozinha_e_preparadores_de_alimentos',  'portable_kitchen_and_food_preparers'),
    ('unknown',                                        'unknown')
) AS manual(category_name, category_name_en);