-- ##########################################################
-- # 1. INTRODUCTION & METADATA
-- ##########################################################

-- Author       : Kuba Kowalski
-- Project      : RHI 2026 – IPUMS Africa (Zambia) Preprocessing
-- Script name  : 1.99_all.sql
-- Last updated : 03/05/2026
-- Purpose      : Combines all country tables into a single harmonized dataset, applies cleaning rules, and generates summary tables for spatial analysis.

-- ##########################################################
-- # 2. Standardization of column names
-- ##########################################################

-- Birthplace tables
ALTER TABLE public.geom_edu_birthplace_1benin        RENAME COLUMN nc_benin        TO n;
ALTER TABLE public.geom_edu_birthplace_2botswana     RENAME COLUMN nc_botswana     TO n;
ALTER TABLE public.geom_edu_birthplace_3burkina      RENAME COLUMN nc_burkina      TO n;
ALTER TABLE public.geom_edu_birthplace_4cote         RENAME COLUMN nc_cote         TO n;
--ALTER TABLE public.geom_edu_birthplace_5ethiopia     RENAME COLUMN nc_ethiopia     TO n; -- Birthplace does not exist for Ethiopia
ALTER TABLE public.geom_edu_birthplace_6ghana        RENAME COLUMN nc_ghana        TO n;
ALTER TABLE public.geom_edu_birthplace_7guinea       RENAME COLUMN nc_guinea       TO n;
ALTER TABLE public.geom_edu_birthplace_8kenya        RENAME COLUMN nc_kenya        TO n;
ALTER TABLE public.geom_edu_birthplace_9malawi       RENAME COLUMN nc_malawi       TO n;
ALTER TABLE public.geom_edu_birthplace_10mali        RENAME COLUMN nc_mali         TO n;
ALTER TABLE public.geom_edu_birthplace_11mozambique  RENAME COLUMN nc_mozambique   TO n;
--ALTER TABLE public.geom_edu_birthplace_12rwanda2012  RENAME COLUMN nc_rwanda       TO n;
ALTER TABLE public.geom_edu_birthplace_13senegal     RENAME COLUMN nc_senegal      TO n;
ALTER TABLE public.geom_edu_birthplace_14sierra      RENAME COLUMN nc_sierra       TO n;
ALTER TABLE public.geom_edu_birthplace_15tanzania    RENAME COLUMN nc_tanzania     TO n;
ALTER TABLE public.geom_edu_birthplace_16togo        RENAME COLUMN nc_togo         TO n;
ALTER TABLE public.geom_edu_birthplace_17uganda      RENAME COLUMN nc_uganda       TO n;
ALTER TABLE public.geom_edu_birthplace_18zambia      RENAME COLUMN nc_zambia       TO n;
ALTER TABLE public.geom_edu_birthplace_19liberia     RENAME COLUMN nc_liberia      TO n;
ALTER TABLE public.geom_edu_birthplace_20cameroon    RENAME COLUMN nc_cameroon     TO n;
ALTER TABLE public.geom_edu_birthplace_21southsudan  RENAME COLUMN nc_southsudan   TO n;
ALTER TABLE public.geom_edu_birthplace_22sudan       RENAME COLUMN nc_sudan        TO n;
ALTER TABLE public.geom_edu_birthplace_23zimbabwe    RENAME COLUMN nc_zimbabwe     TO n;

-- Residence tables
ALTER TABLE public.geom_edu_residence_1benin        RENAME COLUMN nc_benin        TO n;
ALTER TABLE public.geom_edu_residence_2botswana     RENAME COLUMN nc_botswana     TO n;
ALTER TABLE public.geom_edu_residence_3burkina      RENAME COLUMN nc_burkina      TO n;
ALTER TABLE public.geom_edu_residence_4cote         RENAME COLUMN nc_cote         TO n;
ALTER TABLE public.geom_edu_residence_5ethiopia     RENAME COLUMN nc_ethiopia     TO n;
ALTER TABLE public.geom_edu_residence_6ghana        RENAME COLUMN nc_ghana        TO n;
ALTER TABLE public.geom_edu_residence_7guinea       RENAME COLUMN nc_guinea       TO n;
ALTER TABLE public.geom_edu_residence_8kenya        RENAME COLUMN nc_tanzania     TO n; -- nc variable naming is inconsistent due to sloppy coding
ALTER TABLE public.geom_edu_residence_9malawi       RENAME COLUMN nc_malawi       TO n;
ALTER TABLE public.geom_edu_residence_10mali        RENAME COLUMN nc_mali         TO n;
ALTER TABLE public.geom_edu_residence_11mozambique  RENAME COLUMN nc_mozambique   TO n;
--ALTER TABLE public.geom_edu_residence_12rwanda2012  RENAME COLUMN nc_rwanda       TO n;
ALTER TABLE public.geom_edu_residence_13senegal     RENAME COLUMN nc_senegal      TO n;
ALTER TABLE public.geom_edu_residence_14sierra      RENAME COLUMN nc_sierra       TO n;
ALTER TABLE public.geom_edu_residence_15tanzania    RENAME COLUMN nc_tanzania     TO n;
ALTER TABLE public.geom_edu_residence_16togo        RENAME COLUMN nc_togo         TO n;
ALTER TABLE public.geom_edu_residence_17uganda      RENAME COLUMN nc_uganda       TO n;
ALTER TABLE public.geom_edu_residence_18zambia      RENAME COLUMN nc_zambia       TO n;
ALTER TABLE public.geom_edu_residence_19liberia     RENAME COLUMN nc_liberia      TO n;
ALTER TABLE public.geom_edu_residence_20cameroon    RENAME COLUMN nc_cameroon     TO n;
ALTER TABLE public.geom_edu_residence_21southsudan  RENAME COLUMN nc_southsudan   TO n;
ALTER TABLE public.geom_edu_residence_22sudan       RENAME COLUMN nc_sudan        TO n;
ALTER TABLE public.geom_edu_residence_23zimbabwe    RENAME COLUMN nc_zimbabwe     TO n;

-- ##########################################################
-- # 3. Combine as single view 
-- ##########################################################

-- Birthplace
CREATE OR REPLACE VIEW public.geom_edu_birthplace_all AS

SELECT 1  AS country_id, 'benin'          AS country, t.* FROM public.geom_edu_birthplace_1benin t
UNION ALL
SELECT 2  AS country_id, 'botswana',      t.* FROM public.geom_edu_birthplace_2botswana t
UNION ALL
SELECT 3  AS country_id, 'burkina_faso',  t.* FROM public.geom_edu_birthplace_3burkina t
UNION ALL
SELECT 4  AS country_id, 'cote_divoire',  t.* FROM public.geom_edu_birthplace_4cote t
UNION ALL
--SELECT 5  AS country_id, 'ethiopia',      t.* FROM public.geom_edu_birthplace_5ethiopia t
--UNION ALL
SELECT 6  AS country_id, 'ghana',         t.* FROM public.geom_edu_birthplace_6ghana t
UNION ALL
SELECT 7  AS country_id, 'guinea',        t.* FROM public.geom_edu_birthplace_7guinea t
UNION ALL
SELECT 8  AS country_id, 'kenya',         t.* FROM public.geom_edu_birthplace_8kenya t
UNION ALL
SELECT 9  AS country_id, 'malawi',        t.* FROM public.geom_edu_birthplace_9malawi t
UNION ALL
SELECT 10 AS country_id, 'mali',          t.* FROM public.geom_edu_birthplace_10mali t
UNION ALL
SELECT 11 AS country_id, 'mozambique',    t.* FROM public.geom_edu_birthplace_11mozambique t
UNION ALL
--SELECT 12 AS country_id, 'rwanda',        t.* FROM public.geom_edu_birthplace_12rwanda2012 t
--UNION ALL
SELECT 13 AS country_id, 'senegal',       t.* FROM public.geom_edu_birthplace_13senegal t
UNION ALL
SELECT 14 AS country_id, 'sierra_leone',  t.* FROM public.geom_edu_birthplace_14sierra t
UNION ALL
SELECT 15 AS country_id, 'tanzania',      t.* FROM public.geom_edu_birthplace_15tanzania t
UNION ALL
SELECT 16 AS country_id, 'togo',          t.* FROM public.geom_edu_birthplace_16togo t
UNION ALL
SELECT 17 AS country_id, 'uganda',        t.* FROM public.geom_edu_birthplace_17uganda t
UNION ALL
SELECT 18 AS country_id, 'zambia',        t.* FROM public.geom_edu_birthplace_18zambia t;

-- Residence
CREATE OR REPLACE VIEW public.geom_edu_residence_all AS

SELECT 1  AS country_id, 'benin'          AS country, t.* FROM public.geom_edu_residence_1benin t
UNION ALL
SELECT 2  AS country_id, 'botswana',      t.* FROM public.geom_edu_residence_2botswana t
UNION ALL
SELECT 3  AS country_id, 'burkina_faso',  t.* FROM public.geom_edu_residence_3burkina t
UNION ALL
--SELECT 4  AS country_id, 'cote_divoire',  t.* FROM public.geom_edu_residence_4cote t -- Won't work due to inconsistency in number of variables. Probably caused by use of different shapefile from the world one
--UNION ALL
--SELECT 5  AS country_id, 'ethiopia',      t.* FROM public.geom_edu_residence_5ethiopia t
--UNION ALL
SELECT 6  AS country_id, 'ghana',         t.* FROM public.geom_edu_residence_6ghana t
UNION ALL
SELECT 7  AS country_id, 'guinea',        t.* FROM public.geom_edu_residence_7guinea t
UNION ALL
SELECT 8  AS country_id, 'kenya',         t.* FROM public.geom_edu_residence_8kenya t
UNION ALL
SELECT 9  AS country_id, 'malawi',        t.* FROM public.geom_edu_residence_9malawi t
UNION ALL
SELECT 10 AS country_id, 'mali',          t.* FROM public.geom_edu_residence_10mali t
UNION ALL
SELECT 11 AS country_id, 'mozambique',    t.* FROM public.geom_edu_residence_11mozambique t
UNION ALL
--SELECT 12 AS country_id, 'rwanda',        t.* FROM public.geom_edu_residence_12rwanda2012 t
--UNION ALL
SELECT 13 AS country_id, 'senegal',       t.* FROM public.geom_edu_residence_13senegal t
UNION ALL
SELECT 14 AS country_id, 'sierra_leone',  t.* FROM public.geom_edu_residence_14sierra t
UNION ALL
SELECT 15 AS country_id, 'tanzania',      t.* FROM public.geom_edu_residence_15tanzania t
UNION ALL
SELECT 16 AS country_id, 'togo',          t.* FROM public.geom_edu_residence_16togo t
UNION ALL
SELECT 17 AS country_id, 'uganda',        t.* FROM public.geom_edu_residence_17uganda t
UNION ALL
SELECT 18 AS country_id, 'zambia',        t.* FROM public.geom_edu_residence_18zambia t;

------------------

-- birthplace
DROP TABLE IF EXISTS public.geom_edu_birthplace_all;

CREATE TABLE public.geom_edu_birthplace_all AS
SELECT
    ROW_NUMBER() OVER ()::integer AS uid,
    *
FROM (
    SELECT 1 AS country_id, 'benin' AS country, t.* FROM public.geom_edu_birthplace_1benin t
    UNION ALL
    SELECT 2, 'botswana', t.* FROM public.geom_edu_birthplace_2botswana t
    UNION ALL
    SELECT 3, 'burkina_faso', t.* FROM public.geom_edu_birthplace_3burkina t
    UNION ALL
    --SELECT 4, 'cote_divoire', t.* FROM public.geom_edu_birthplace_4cote t
    --UNION ALL
    --SELECT 5, 'ethiopia', t.* FROM public.geom_edu_birthplace_5ethiopia t
    --UNION ALL
    SELECT 6, 'ghana', t.* FROM public.geom_edu_birthplace_6ghana t
    UNION ALL
    SELECT 7, 'guinea', t.* FROM public.geom_edu_birthplace_7guinea t
    UNION ALL
    SELECT 8, 'kenya', t.* FROM public.geom_edu_birthplace_8kenya t
    UNION ALL
    SELECT 9, 'malawi', t.* FROM public.geom_edu_birthplace_9malawi t
    UNION ALL
    SELECT 10, 'mali', t.* FROM public.geom_edu_birthplace_10mali t
    UNION ALL
    SELECT 11, 'mozambique', t.* FROM public.geom_edu_birthplace_11mozambique t
    UNION ALL
    --SELECT 12, 'rwanda', t.* FROM public.geom_edu_birthplace_12rwanda2012 t
    --UNION ALL
    SELECT 13, 'senegal', t.* FROM public.geom_edu_birthplace_13senegal t
    UNION ALL
    SELECT 14, 'sierra_leone', t.* FROM public.geom_edu_birthplace_14sierra t
    UNION ALL
    SELECT 15, 'tanzania', t.* FROM public.geom_edu_birthplace_15tanzania t
    UNION ALL
    SELECT 16, 'togo', t.* FROM public.geom_edu_birthplace_16togo t
    UNION ALL
    SELECT 17, 'uganda', t.* FROM public.geom_edu_birthplace_17uganda t
    UNION ALL
    SELECT 18, 'zambia', t.* FROM public.geom_edu_birthplace_18zambia t
) x;

ALTER TABLE public.geom_edu_birthplace_all
ADD PRIMARY KEY (uid);

-- Residence
DROP TABLE IF EXISTS public.geom_edu_residence_all;

CREATE TABLE public.geom_edu_residence_all AS
SELECT
    ROW_NUMBER() OVER ()::integer AS uid,
    *
FROM (
    SELECT 1 AS country_id, 'benin' AS country, t.* FROM public.geom_edu_residence_1benin t
    UNION ALL
    SELECT 2, 'botswana', t.* FROM public.geom_edu_residence_2botswana t
    UNION ALL
    SELECT 3, 'burkina_faso', t.* FROM public.geom_edu_residence_3burkina t
    UNION ALL
    --SELECT 4, 'cote_divoire', t.* FROM public.geom_edu_residence_4cote t
    --UNION ALL
    --SELECT 5, 'ethiopia', t.* FROM public.geom_edu_residence_5ethiopia t
    --UNION ALL
    SELECT 6, 'ghana', t.* FROM public.geom_edu_residence_6ghana t
    UNION ALL
    SELECT 7, 'guinea', t.* FROM public.geom_edu_residence_7guinea t
    UNION ALL
    SELECT 8, 'kenya', t.* FROM public.geom_edu_residence_8kenya t
    UNION ALL
    SELECT 9, 'malawi', t.* FROM public.geom_edu_residence_9malawi t
    UNION ALL
    SELECT 10, 'mali', t.* FROM public.geom_edu_residence_10mali t
    UNION ALL
    SELECT 11, 'mozambique', t.* FROM public.geom_edu_residence_11mozambique t
    UNION ALL
    --SELECT 12, 'rwanda', t.* FROM public.geom_edu_residence_12rwanda2012 t
    --UNION ALL
    SELECT 13, 'senegal', t.* FROM public.geom_edu_residence_13senegal t
    UNION ALL
    SELECT 14, 'sierra_leone', t.* FROM public.geom_edu_residence_14sierra t
    UNION ALL
    SELECT 15, 'tanzania', t.* FROM public.geom_edu_residence_15tanzania t
    UNION ALL
    SELECT 16, 'togo', t.* FROM public.geom_edu_residence_16togo t
    UNION ALL
    SELECT 17, 'uganda', t.* FROM public.geom_edu_residence_17uganda t
    UNION ALL
    SELECT 18, 'zambia', t.* FROM public.geom_edu_residence_18zambia t
) x;

ALTER TABLE public.geom_edu_residence_all
ADD PRIMARY KEY (uid);