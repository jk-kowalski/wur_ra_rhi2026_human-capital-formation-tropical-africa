-- ##########################################################
-- # 1. INTRODUCTION & METADATA
-- ##########################################################

-- Author       : Kuba Kowalski
-- Project      : RHI 2026 – IPUMS Africa (Tanzania) Preprocessing
-- Script name  : 1.15_tanzania.sql
-- Last updated : 05/03/2026
-- Purpose      : Preprocess IPUMS census data (Tanzania) for statistical analysis and spatial integration.

-- Description:
  -- This script:
    -- Loads raw census microdata from IPUMS into PostgreSQL.
    -- Filters and harmonizes variables for later integration with other research areas.
    -- Compares source variables and harmonized variables for discrepancies. In case of a discrepancy, value of source variable always used. 
    -- Removes invalid entries and applies cleaning rules.
    -- Adds derived variables for demographic and migration analysis.
    -- Outputs harmonized tables and views for use in downstream statistical and spatial analyses.

  -- Requirements:
    -- PostgreSQL 14+ with PostGIS extension enabled
    -- Raw CSV file from IPUMS International (Note: Do not use .dat files. Inconsistently compatible with PostgreSQL)
    -- Compatible schema: public.master

  -- Source data:
    -- IPUMS International: Tanzania Census Microdata (2012, 2002, 1988)
    -- CSV input assumed to follow IPUMS column format

  -- User Recommendation:
    -- Use this script in pgadmin4 (UI for PostgreSQL). It was not tested using other software. 
    -- View outputs in PostgreSQL (tables), QGIS or ArcGIS Pro (maps)

  -- Notes:
    -- Do **not** change column case or data types before preprocessing.
    -- Replace hardcoded file paths before running.

-- ##########################################################
-- # 2. DATA IMPORT & RAW TABLE CREATION
-- ##########################################################

-- Objective:
  -- Set up a raw data table (`extract`) to hold the unprocessed IPUMS .dat data.
  -- All fields are initially imported as TEXT to avoid type conversion issues.

-- Key Notes:
  -- IPUMS columns contain mixed formatting and special codes (e.g., 9 = unknown).
  -- PostgreSQL treats unquoted column names as lowercase — hence, double quotes used.
  -- Data is imported using COPY from a local .dat file; path must be adjusted before execution.
  -- A backup table `extract_backup` is created immediately after import for safety.

-- ----------------------------------------------------------
-- 2.1 Create the raw extract table
-- ----------------------------------------------------------

--- Creating empty table
  -- All columns explicitly defined as TEXT
  -- This allows flexible import regardless of value formatting
  -- KEY: toggle header option when importing. Otherwise, 1st row is false

/* CREATE TABLE public.extract_15tanzania (
  "COUNTRY"      integer,
  "YEAR"         integer,
  "SAMPLE"       integer,
  "SERIAL"       bigint,
  "PERSONS"      integer,
  "HHWT"         double precision,
  "SUBSAMP"      integer,
  "ENUMMO"       integer,
  "ENUMHH"       integer,
  "URBAN"        integer,
  "REGIONW"      integer,
  "GEOLEV1"      integer,
  "GEOLEV2"      integer,

  "GEO1_TZ"      integer,
  "GEO1_TZ1988"  integer,
  "GEO1_TZ2002"  integer,
  "GEO1_TZ2012"  integer,

  "GEO2_TZ"      integer,
  "GEO2_TZ1988"  integer,
  "GEO2_TZ2002"  integer,
  "GEO2_TZ2012"  integer,

  "PERNUM"       integer,
  "PERWT"        double precision,
  "AGE"          integer,
  "AGE2"         integer,
  "SEX"          integer,
  "MARST"        integer,
  "MARSTD"       integer,

  "CHBORN"       integer,
  "CHSURV"       integer,
  "BIRTHSLYR"    integer,
  "CHDEAD"       integer,
  "MORTMOT"      integer,
  "HOMECHILD"    integer,
  "AWAYCHILD"    integer,

  "NATIVITY"     integer,
  "BPLCOUNTRY"   integer,
  "CITIZEN"      integer,
  "NATION"       integer,
  "BPLTZ"        integer,

  "SPEAKENG"     integer,
  "SCHOOL"       integer,
  "LIT"          integer,
  "EDATTAIN"     integer,
  "EDATTAIND"    integer,
  "YRSCHOOL"     integer,
  "EDUCTZ"       integer,

  "EMPSTAT"      integer,
  "EMPSTATD"     integer,
  "LABFORCE"     integer,
  "CLASSWK"      integer,
  "CLASSWKD"     integer,
  "OCCISCO"      integer,
  "OCC"          integer,

  "GEOMIG1_1"    integer,
  "GEOMIG1_10"   integer,
  "MIG1_1_TZ"    integer,
  "MIG1_10_TZ"   integer,

  "DISABLED"     integer
); */


CREATE TABLE public.extract_15tanzania (
  "COUNTRY"      text,
  "YEAR"         text,
  "SAMPLE"       text,
  "SERIAL"       text,
  "PERSONS"      text,
  "HHWT"         text,
  "SUBSAMP"      text,
  "ENUMMO"       text,
  "ENUMHH"       text,
  "URBAN"        text,
  "REGIONW"      text,
  "GEOLEV1"      text,
  "GEOLEV2"      text,

  "GEO1_TZ"      text,
  "GEO1_TZ1988"  text,
  "GEO1_TZ2002"  text,
  "GEO1_TZ2012"  text,

  "GEO2_TZ"      text,
  "GEO2_TZ1988"  text,
  "GEO2_TZ2002"  text,
  "GEO2_TZ2012"  text,

  "PERNUM"       text,
  "PERWT"        text,
  "AGE"          text,
  "AGE2"         text,
  "SEX"          text,
  "MARST"        text,
  "MARSTD"       text,

  "CHBORN"       text,
  "CHSURV"       text,
  "BIRTHSLYR"    text,
  "CHDEAD"       text,
  "MORTMOT"      text,
  "HOMECHILD"    text,
  "AWAYCHILD"    text,

  "NATIVITY"     text,
  "BPLCOUNTRY"   text,
  "CITIZEN"      text,
  "NATION"       text,
  "BPLTZ"        text,

  "SPEAKENG"     text,
  "SCHOOL"       text,
  "LIT"          text,
  "EDATTAIN"     text,
  "EDATTAIND"    text,
  "YRSCHOOL"     text,
  "EDUCTZ"       text,

  "EMPSTAT"      text,
  "EMPSTATD"     text,
  "LABFORCE"     text,
  "CLASSWK"      text,
  "CLASSWKD"     text,
  "OCCISCO"      text,
  "OCC"          text,

  "GEOMIG1_1"    text,
  "GEOMIG1_10"   text,
  "MIG1_1_TZ"    text,
  "MIG1_10_TZ"   text,

  "DISABLED"     text
);

-- 1st row to check proper import of header
SELECT *
FROM extract_15tanzania
ORDER BY ctid
LIMIT 1;

-- Get unique values and frequencies for the "COUNTRY" column
SELECT "COUNTRY", COUNT(*) AS frequency
FROM extract_15tanzania
GROUP BY "COUNTRY"
ORDER BY frequency DESC;

-- Backup
CREATE TABLE extract_15tanzania_backup AS
SELECT * FROM extract_15tanzania;

-- Master table for further analysis
CREATE TABLE master_15tanzania AS
SELECT * FROM extract_15tanzania;

-- ##########################################################
-- # 3. DATA CLEANING, HARMONIZATION & DERIVED VARIABLE CREATION
-- ##########################################################

-- ----------------------------------------------------------
-- 3.1 Birth province harmonization
-- ----------------------------------------------------------

-- Re-code to allow for cleaner matching with codebook

/* -- Re-code to follow 8340XX format
ALTER TABLE public.master_15tanzania
ADD COLUMN IF NOT EXISTS bpltz_834 integer;

UPDATE public.master_15tanzania
SET bpltz_834 =
    834000 + NULLIF(TRIM(bpltz), '')::integer; */

-- Create column for birth-province with full names
ALTER TABLE public.master_15tanzania
ADD COLUMN IF NOT EXISTS birth_province text;

-- De-code birth province names based on bpltz codes
  -- Note: 7min processing 
UPDATE public.master_15tanzania
SET birth_province = CASE CAST("BPLTZ" AS integer)

    WHEN 1 THEN 'Dodoma'
    WHEN 2 THEN 'Arusha'
    WHEN 3 THEN 'Kilimanjaro'
    WHEN 4 THEN 'Tanga'
    WHEN 5 THEN 'Morogoro'
    WHEN 6 THEN 'Pwani'
    WHEN 7 THEN 'Dar es Salaam'
    WHEN 8 THEN 'Lindi'
    WHEN 9 THEN 'Mtwara'
    WHEN 10 THEN 'Ruvumba'
    WHEN 11 THEN 'Iringa'
    WHEN 12 THEN 'Mbeya'
    WHEN 13 THEN 'Singida'
    WHEN 14 THEN 'Tabora'
    WHEN 15 THEN 'Rukwa'
    WHEN 16 THEN 'Kigoma'
    WHEN 17 THEN 'Shinyanga'
    WHEN 18 THEN 'Kagera'
    WHEN 19 THEN 'Mwanza'
    WHEN 20 THEN 'Mara'
    WHEN 21 THEN 'Manyara'
    WHEN 22 THEN 'Njombe'
    WHEN 23 THEN 'Katavi'
    WHEN 24 THEN 'Simiyu'
    WHEN 25 THEN 'Geita'

    WHEN 51 THEN 'Zanzibar Kaskazini (Zanzibar north)'
    WHEN 52 THEN 'Zanzibar Kati na Kusini (Zanzibar south)'
    WHEN 53 THEN 'Zanzibar Mjini na Magh (Zanzibar town/west)'
    WHEN 54 THEN 'Pemba Kaskazini (Pemba north)'
    WHEN 55 THEN 'Pemba Kusini (Pemba south)'

    WHEN 60 THEN 'Tanzania, unspecified'
    WHEN 90 THEN 'Foreign country'
    WHEN 98 THEN 'Unknown'
    WHEN 99 THEN 'NIU (not in universe)'

    ELSE NULL
END;


-- ----------------------------------------------------------
-- 3.2 Foreign-born labeling
-- ----------------------------------------------------------

ALTER TABLE public.master_15tanzania
ADD COLUMN IF NOT EXISTS "FOREIGN" integer;

UPDATE public.master_15tanzania
SET "FOREIGN" = CASE
    WHEN birth_province = 'Foreign country' THEN 1
    ELSE 0
END;

-- ----------------------------------------------------------
-- 3.3 Age harmonization & cohort labeling
-- ----------------------------------------------------------

-- Clean age column
ALTER TABLE public.master_15tanzania
ADD COLUMN IF NOT EXISTS age_clean integer;

-- Remove invalid values
UPDATE public.master_15tanzania
SET age_clean = CASE
    WHEN CAST("AGE" AS integer) BETWEEN 0 AND 99 THEN CAST("AGE" AS integer)
    ELSE NULL
END;

-- Birthyear column
ALTER TABLE public.master_15tanzania
ADD COLUMN IF NOT EXISTS birth_year integer;

-- Compute birthyear using year of census and age
ALTER TABLE public.master_15tanzania
ALTER COLUMN "YEAR" TYPE integer
USING CAST("YEAR" AS integer);

UPDATE public.master_15tanzania
SET birth_year = "YEAR" - age_clean;

-- Cohort creation 
ALTER TABLE public.master_15tanzania
ADD COLUMN IF NOT EXISTS cohort integer;

UPDATE public.master_15tanzania
SET cohort = CASE
    WHEN birth_year >= 1900 AND birth_year < 1910 THEN 1905
    WHEN birth_year >= 1910 AND birth_year < 1920 THEN 1915
    WHEN birth_year >= 1920 AND birth_year < 1930 THEN 1925
    WHEN birth_year >= 1930 AND birth_year < 1940 THEN 1935
    WHEN birth_year >= 1940 AND birth_year < 1950 THEN 1945
    WHEN birth_year >= 1950 AND birth_year < 1960 THEN 1955
    WHEN birth_year >= 1960 AND birth_year < 1970 THEN 1965
    WHEN birth_year >= 1970 AND birth_year < 1980 THEN 1975
    WHEN birth_year >= 1980 AND birth_year < 1990 THEN 1985
    ELSE NULL
END;

-- Remove invalid rows by age
DELETE FROM public.master_15tanzania
WHERE cohort IS NULL;

-- Restrict age range to 20-90
DELETE FROM public.master_15tanzania
WHERE age_clean < 20
   OR age_clean > 90;

-- ----------------------------------------------------------
-- 3.4 Education variable construction & labeling 
-- ----------------------------------------------------------

-- Cleaning edattaind
DELETE FROM public.master_15tanzania
WHERE CAST("EDATTAIND" AS integer) IN (0, 999);

-- De-code edattaind for convenience 
ALTER TABLE public.master_15tanzania
ADD COLUMN IF NOT EXISTS education text;

UPDATE public.master_15tanzania
SET education = CASE CAST("EDATTAIND" AS integer)

    WHEN 0   THEN 'NIU (not in universe)'
    WHEN 100 THEN 'Less than primary completed (n.s.)'
    WHEN 110 THEN 'No schooling'
    WHEN 120 THEN 'Some primary completed'
    WHEN 130 THEN 'Primary (4 yrs) completed'
    WHEN 211 THEN 'Primary (5 yrs) completed'
    WHEN 212 THEN 'Primary (6 yrs) completed'
    WHEN 221 THEN 'Lower secondary general completed'
    WHEN 222 THEN 'Lower secondary technical completed'
    WHEN 311 THEN 'Secondary, general track completed'
    WHEN 312 THEN 'Some college completed'
    WHEN 320 THEN 'Secondary or post-secondary technical completed'
    WHEN 321 THEN 'Secondary, technical track completed'
    WHEN 322 THEN 'Post-secondary technical education'
    WHEN 400 THEN 'University completed'
    WHEN 999 THEN 'Unknown/missing'

    ELSE NULL
END;

-- Binary labeling "primary or more/otherwise" 
ALTER TABLE public.master_15tanzania
ADD COLUMN IF NOT EXISTS primary_educ boolean;

UPDATE public.master_15tanzania
SET primary_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (100, 110, 120) THEN FALSE
    ELSE TRUE
END;

-- Binary labeling "lower secondary or higher/otherwise"
ALTER TABLE public.master_15tanzania
ADD COLUMN IF NOT EXISTS higher_educ boolean;

UPDATE public.master_15tanzania
SET higher_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (221, 222, 311, 312, 321, 322, 400) THEN TRUE
    ELSE FALSE
END;

-- Binary labeling "some college, post-secondary technical, or university/otherwise"
ALTER TABLE public.master_15tanzania
ADD COLUMN IF NOT EXISTS tertiary_educ boolean;

UPDATE public.master_15tanzania
SET tertiary_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (312, 322, 400) THEN TRUE
    ELSE FALSE
END;

-- ##########################################################
-- # 4. SPATIAL JOIN & SUMMARY STATISTICS
-- ##########################################################

-- ----------------------------------------------------------
-- 4.1 Summary by current residence region
-- ----------------------------------------------------------

DROP TABLE IF EXISTS public.edu_residence_15tanzania;

CREATE TABLE public.edu_residence_15tanzania AS
SELECT
    cohort,
    "GEO1_TZ",

    -- primary/basic
    SUM(CAST("PERWT" AS numeric) * (primary_educ::int)) 
        / NULLIF(SUM(CAST("PERWT" AS numeric)), 0) AS primary_educ,

    -- higher education
    SUM(CAST("PERWT" AS numeric) * (higher_educ::int)) 
        / NULLIF(SUM(CAST("PERWT" AS numeric)), 0) AS higher_educ,

    -- tertiary education
    SUM(CAST("PERWT" AS numeric) * (tertiary_educ::int)) 
        / NULLIF(SUM(CAST("PERWT" AS numeric)), 0) AS tertiary_educ,

    -- counts
    COUNT(primary_educ) AS nc_tanzania

FROM public.master_15tanzania
WHERE cohort NOT IN (1905, 1985)
GROUP BY cohort, "GEO1_TZ";

-- Join
DROP TABLE IF EXISTS public.geom_edu_residence_15tanzania;

CREATE TABLE public.geom_edu_residence_15tanzania AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_tanzania
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_residence_15tanzania e
    ON CAST(s."GEOLEVEL1" AS integer) = CAST(e."GEO1_TZ" AS integer)
WHERE CAST(s."GEOLEVEL1" AS integer) BETWEEN 834001 AND 834055;
-- ----------------------------------------------------------
-- 4.2 Summary by birthplace region
-- ----------------------------------------------------------

-- Recoding birthplace because I have zero foresight -> To do: fix earlier in pipeline

DROP TABLE IF EXISTS public.edu_birthplace_15tanzania;

CREATE TABLE public.edu_birthplace_15tanzania AS
WITH birthplace_harmonized AS (
    SELECT
        cohort,
        CASE
            WHEN birth_province = 'Dodoma' THEN 834001
            WHEN birth_province IN ('Arusha', 'Manyara') THEN 834002
            WHEN birth_province = 'Kilimanjaro' THEN 834003
            WHEN birth_province = 'Tanga' THEN 834004
            WHEN birth_province = 'Morogoro' THEN 834005
            WHEN birth_province = 'Pwani' THEN 834006
            WHEN birth_province = 'Dar es Salaam' THEN 834007
            WHEN birth_province = 'Lindi' THEN 834008
            WHEN birth_province = 'Mtwara' THEN 834009
            WHEN birth_province = 'Ruvumba' THEN 834010
            WHEN birth_province IN ('Iringa', 'Njombe') THEN 834011
            WHEN birth_province = 'Mbeya' THEN 834012
            WHEN birth_province = 'Singida' THEN 834013
            WHEN birth_province = 'Tabora' THEN 834014
            WHEN birth_province IN ('Rukwa', 'Katavi') THEN 834015
            WHEN birth_province = 'Kigoma' THEN 834016
            WHEN birth_province IN ('Shinyanga', 'Kagera', 'Mwanza', 'Simiyu', 'Geita') THEN 834019
            WHEN birth_province = 'Mara' THEN 834020
            WHEN birth_province = 'Zanzibar Kaskazini (Zanzibar north)' THEN 834051
            WHEN birth_province = 'Zanzibar Kati na Kusini (Zanzibar south)' THEN 834052
            WHEN birth_province = 'Zanzibar Mjini na Magh (Zanzibar town/west)' THEN 834053
            WHEN birth_province = 'Pemba Kaskazini (Pemba north)' THEN 834054
            WHEN birth_province = 'Pemba Kusini (Pemba south)' THEN 834055
            ELSE NULL
        END AS "GEO1_TZ",
        CAST("PERWT" AS numeric) AS perwt_num,
        primary_educ,
        higher_educ,
        tertiary_educ
    FROM public.master_15tanzania
    WHERE cohort NOT IN (1905, 1985)
      AND "FOREIGN" = 0
      AND birth_province NOT IN (
          'Foreign country',
          'Unknown',
          'NIU (not in universe)',
          'Tanzania, unspecified'
      )
)
SELECT
    cohort,
    "GEO1_TZ",

    SUM(perwt_num * (primary_educ::int))
        / NULLIF(SUM(perwt_num), 0) AS primary_educ,

    SUM(perwt_num * (higher_educ::int))
        / NULLIF(SUM(perwt_num), 0) AS higher_educ,

    SUM(perwt_num * (tertiary_educ::int))
        / NULLIF(SUM(perwt_num), 0) AS tertiary_educ,

    COUNT(primary_educ) AS nc_tanzania
FROM birthplace_harmonized
WHERE "GEO1_TZ" IS NOT NULL
GROUP BY cohort, "GEO1_TZ";

-- join
DROP TABLE IF EXISTS public.geom_edu_birthplace_15tanzania;

CREATE TABLE public.geom_edu_birthplace_15tanzania AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_tanzania
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_birthplace_15tanzania e
    ON CAST(s."GEOLEVEL1" AS integer) = CAST(e."GEO1_TZ" AS integer)
WHERE CAST(s."GEOLEVEL1" AS integer) BETWEEN 834001 AND 834055;