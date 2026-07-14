-- ##########################################################
-- # 1. INTRODUCTION & METADATA
-- ##########################################################

-- Author       : Kuba Kowalski
-- Project      : RHI 2026 – IPUMS Africa (Sudan) Preprocessing
-- Script name  : 1.22_sudan.sql
-- Last updated : 16/04/2026
-- Purpose      : Preprocess IPUMS census data (Sudan) for statistical analysis and spatial integration.

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
    -- IPUMS International: Sudan Census Microdata (2012, 2002, 1988)
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

--- Example expression for LLM input if adjusting script for other datasets. 
  -- For prompting, request that table name and variables are adjusted based on the attached DDI (see input data folder for PDF or download DDI from IPUMS when requesting data.)
  -- Note: when importing data, the match between column names in empty table and input CSV must be exact. Otherwise, import will fail.
  
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
CREATE TABLE public.extract_22sudan (
  "COUNTRY"          text,
  "YEAR"             text,
  "SAMPLE"           text,
  "SERIAL"           text,
  "HHWT"             text,
  "URBAN"            text,
  "REGIONW"          text,
  "GEOLEV1"          text,
  "GEOLEV2"          text,

  "DHS_IPUMSI_SD"    text,

  "PERNUM"           text,
  "PERWT"            text,
  "RELATE"           text,
  "RELATED"          text,
  "AGE"              text,
  "AGE2"             text,
  "SEX"              text,
  "MARST"            text,
  "MARSTD"           text,
  "AGEMARR"          text,

  "CHBORN"           text,
  "CHSURV"           text,
  "BIRTHSLYR"        text,
  "BIRTHSURV"        text,
  "CHDEAD"           text,
  "HOMECHILD"        text,
  "AWAYCHILD"        text,

  "NATIVITY"         text,
  "CITIZEN"          text,
  "NATION"           text,
  "BPLSD"            text,

  "SCHOOL"           text,
  "LIT"              text,
  "EDATTAIN"         text,
  "EDATTAIND"        text,
  "EDUCSD"           text,

  "EMPSTAT"          text,
  "EMPSTATD"         text,
  "OCCISCO"          text,
  "OCC"              text,
  "INDGEN"           text,
  "IND"              text,

  "MIGRATE1"         text,
  "GEOMIG1_1"        text,
  "MIGYRS1"          text,
  "MIG1_1_SD"        text,

  "DISABLED"         text
);
-- *IMPORTANT* --
-- Import CSV here using pgadmin4 import tool MANUALLY using "IMPORT/EXPORT DATA...". Do NOT use COPY command. 

-- 1st row to check proper import of header
SELECT *
FROM extract_22sudan
ORDER BY ctid
LIMIT 1;

-- Get unique values and frequencies for the "COUNTRY" column
SELECT "COUNTRY", COUNT(*) AS frequency
FROM extract_22sudan
GROUP BY "COUNTRY"
ORDER BY frequency DESC;

-- Backup
CREATE TABLE extract_22sudan_backup AS
SELECT * FROM extract_22sudan;

-- Master table for further analysis
CREATE TABLE master_22sudan AS
SELECT * FROM extract_22sudan;

-- ##########################################################
-- # 3. DATA CLEANING, HARMONIZATION & DERIVED VARIABLE CREATION
-- ##########################################################

-- ----------------------------------------------------------
-- 3.1 Birth province harmonization
-- ----------------------------------------------------------

-- Re-code needed. Birthplace comes at geolvl1 but as individual objects. IPUMS geolvl1 dataset and residence data comes with combined geolvl1 entities

-- Create column for birth province
ALTER TABLE public.master_22sudan
ADD COLUMN IF NOT EXISTS birth_province integer;

-- Recodes BPLLR to follow GEO1_LR
-- Recodes BPLSD to follow GEOLEV1
UPDATE public.master_22sudan
SET birth_province = CASE

    -- Northern
    WHEN CAST("BPLSD" AS integer) = 11 THEN 729011

    -- Nahr El Nil
    WHEN CAST("BPLSD" AS integer) = 12 THEN 729012

    -- Red Sea
    WHEN CAST("BPLSD" AS integer) = 21 THEN 729021

    -- Kassala
    WHEN CAST("BPLSD" AS integer) = 22 THEN 729022

    -- Al Gedarif
    WHEN CAST("BPLSD" AS integer) = 23 THEN 729023

    -- Khartoum
    WHEN CAST("BPLSD" AS integer) = 31 THEN 729031

    -- Al Gezira
    WHEN CAST("BPLSD" AS integer) = 41 THEN 729041

    -- White Nile
    WHEN CAST("BPLSD" AS integer) = 42 THEN 729042

    -- Sinnar
    WHEN CAST("BPLSD" AS integer) = 43 THEN 729043

    -- Blue Nile
    WHEN CAST("BPLSD" AS integer) = 44 THEN 729044

    -- North Kordofan
    WHEN CAST("BPLSD" AS integer) = 51 THEN 729051

    -- South Kordofan
    WHEN CAST("BPLSD" AS integer) = 52 THEN 729052

    -- North Darfur
    WHEN CAST("BPLSD" AS integer) = 61 THEN 729061

    -- West Darfur
    WHEN CAST("BPLSD" AS integer) = 62 THEN 729062

    -- South Darfur
    WHEN CAST("BPLSD" AS integer) = 63 THEN 729063

    -- South Sudan states / Abroad
    WHEN CAST("BPLSD" AS integer) IN (
        71, 72, 73,
        81, 82, 83, 84,
        91, 92, 93,
        99
    ) THEN NULL

    ELSE NULL
END;
-- ----------------------------------------------------------
-- 3.2 Foreign-born labeling
-- ----------------------------------------------------------

ALTER TABLE public.master_22sudan
ADD COLUMN IF NOT EXISTS "FOREIGN" integer;

UPDATE public.master_22sudan
SET "FOREIGN" = CASE
    -- Abroad
    WHEN CAST("BPLSD" AS integer) = 99 THEN 1

    -- South Sudan states
    WHEN CAST("BPLSD" AS integer) IN (
        71, 72, 73,
        81, 82, 83, 84,
        91, 92, 93
    ) THEN 1

    -- Sudan states
    WHEN CAST("BPLSD" AS integer) IN (
        11, 12, 21, 22, 23,
        31,
        41, 42, 43, 44,
        51, 52,
        61, 62, 63
    ) THEN 0

    ELSE NULL
END;
-- ----------------------------------------------------------
-- 3.3 Age harmonization & cohort labeling
-- ----------------------------------------------------------

-- Clean age column
ALTER TABLE public.master_22sudan
ADD COLUMN IF NOT EXISTS age_clean integer;

-- Remove invalid values
UPDATE public.master_22sudan
SET age_clean = CASE
    WHEN CAST("AGE" AS integer) BETWEEN 0 AND 99 THEN CAST("AGE" AS integer)
    ELSE NULL
END;

-- Birthyear column
ALTER TABLE public.master_22sudan
ADD COLUMN IF NOT EXISTS birth_year integer;

-- Compute birthyear using year of census and age
ALTER TABLE public.master_22sudan
ALTER COLUMN "YEAR" TYPE integer
USING CAST("YEAR" AS integer);

UPDATE public.master_22sudan
SET birth_year = "YEAR" - age_clean;

-- Cohort creation 
ALTER TABLE public.master_22sudan
ADD COLUMN IF NOT EXISTS cohort integer;

UPDATE public.master_22sudan
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
DELETE FROM public.master_22sudan
WHERE cohort IS NULL;

-- Restrict age range to 20-90
DELETE FROM public.master_22sudan
WHERE age_clean < 20
   OR age_clean > 90;

-- ----------------------------------------------------------
-- 3.4 Education variable construction & labeling 
-- ----------------------------------------------------------

-- Cleaning EDATTAIND
DELETE FROM public.master_22sudan
WHERE CAST("EDATTAIND" AS integer) IN (0, 999);

-- Decode EDATTAIND for convenience
ALTER TABLE public.master_22sudan
ADD COLUMN IF NOT EXISTS education text;

UPDATE public.master_22sudan
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

-- Binary labeling: primary completed or more
ALTER TABLE public.master_22sudan
ADD COLUMN IF NOT EXISTS primary_educ boolean;

UPDATE public.master_22sudan
SET primary_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (100, 110, 120) THEN FALSE
    ELSE TRUE
END;

-- Binary labeling: lower secondary or higher
ALTER TABLE public.master_22sudan
ADD COLUMN IF NOT EXISTS higher_educ boolean;

UPDATE public.master_22sudan
SET higher_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (221, 222, 311, 312, 321, 322, 400) THEN TRUE
    ELSE FALSE
END;

-- Binary labeling: tertiary or equivalent
ALTER TABLE public.master_22sudan
ADD COLUMN IF NOT EXISTS tertiary_educ boolean;

UPDATE public.master_22sudan
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

DROP TABLE IF EXISTS public.edu_residence_22sudan;

CREATE TABLE public.edu_residence_22sudan AS
SELECT
    cohort,
    "GEOLEV1",

    SUM(CAST("PERWT" AS numeric) * (primary_educ::int)) 
        / NULLIF(SUM(CAST("PERWT" AS numeric)), 0) AS primary_educ,

    SUM(CAST("PERWT" AS numeric) * (higher_educ::int)) 
        / NULLIF(SUM(CAST("PERWT" AS numeric)), 0) AS higher_educ,

    SUM(CAST("PERWT" AS numeric) * (tertiary_educ::int)) 
        / NULLIF(SUM(CAST("PERWT" AS numeric)), 0) AS tertiary_educ,

    COUNT(primary_educ) AS nc_sudan

FROM public.master_22sudan
WHERE cohort NOT IN (1905, 1985)
GROUP BY cohort, "GEOLEV1";


-- Join
DROP TABLE IF EXISTS public.geom_edu_residence_22sudan;

CREATE TABLE public.geom_edu_residence_22sudan AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_sudan
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_residence_22sudan e
    ON CAST(s."GEOLEVEL1" AS integer) = CAST(e."GEOLEV1" AS integer)
WHERE CAST(s."GEOLEVEL1" AS integer) IN (
    729011,
    729012,
    729021,
    729022,
    729023,
    729031,
    729041,
    729042,
    729043,
    729044,
    729051,
    729052,
    729061,
    729062,
    729063
);

-- ----------------------------------------------------------
-- 4.2 Summary by birthplace region
-- ----------------------------------------------------------

DROP TABLE IF EXISTS public.edu_birthplace_22sudan;

CREATE TABLE public.edu_birthplace_22sudan AS
WITH birthplace_harmonized AS (
    SELECT
        cohort,
        birth_province,
        CAST("PERWT" AS numeric) AS perwt_num,
        primary_educ,
        higher_educ,
        tertiary_educ
    FROM public.master_22sudan
    WHERE cohort NOT IN (1905, 1985)
      AND "FOREIGN" = 0
      AND birth_province IS NOT NULL
)
SELECT
    cohort,
    birth_province,

    SUM(perwt_num * (primary_educ::int))
        / NULLIF(SUM(perwt_num), 0) AS primary_educ,

    SUM(perwt_num * (higher_educ::int))
        / NULLIF(SUM(perwt_num), 0) AS higher_educ,

    SUM(perwt_num * (tertiary_educ::int))
        / NULLIF(SUM(perwt_num), 0) AS tertiary_educ,

    COUNT(primary_educ) AS nc_sudan
FROM birthplace_harmonized
GROUP BY cohort, birth_province;


-- Join
DROP TABLE IF EXISTS public.geom_edu_birthplace_22sudan;

CREATE TABLE public.geom_edu_birthplace_22sudan AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_sudan
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_birthplace_22sudan e
    ON CAST(s."GEOLEVEL1" AS integer) = e.birth_province
WHERE CAST(s."GEOLEVEL1" AS integer) IN (
    729011,
    729012,
    729021,
    729022,
    729023,
    729031,
    729041,
    729042,
    729043,
    729044,
    729051,
    729052,
    729061,
    729062,
    729063
);