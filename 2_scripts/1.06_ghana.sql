-- ##########################################################
-- # 1. INTRODUCTION & METADATA
-- ##########################################################

-- Author       : Kuba Kowalski
-- Project      : RHI 2026 – IPUMS Africa (Ghana) Preprocessing
-- Script name  : 1.06_ghana.sql
-- Last updated : 05/03/2026
-- Purpose      : Preprocess IPUMS census data (Ghana) for statistical analysis and spatial integration.

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
    -- IPUMS International: Ghana Census Microdata (2012, 2002, 1988)
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

CREATE TABLE public.extract_6ghana (
  "COUNTRY"         text,
  "YEAR"            text,
  "SAMPLE"          text,
  "SERIAL"          text,
  "HHWT"            text,
  "URBAN"           text,
  "REGIONW"         text,
  "GEOLEV1"         text,
  "GEOLEV2"         text,

  "GEO1_GH"         text,
  "GEO1_GH1984"     text,
  "GEO1_GH2000"     text,
  "GEO1_GH2010"     text,

  "GEO2_GH"         text,
  "GEO2_GH1984"     text,
  "GEO2_GH2000"     text,
  "GEO2_GH2010"     text,

  "LOCALGH"         text,
  "DHS_IPUMSI_GH"   text,

  "PERNUM"          text,
  "PERWT"           text,
  "AGE"             text,
  "AGE2"            text,
  "SEX"             text,
  "CHBORN"          text,
  "CHSURV"          text,

  "NATIVITY"        text,
  "BPLCOUNTRY"      text,
  "CITIZEN"         text,
  "NATION"          text,
  "BPLGH"           text,

  "RELIGION"        text,
  "RELIGIOND"       text,
  "ETHNICGH"        text,
  "SPEAKENG"        text,
  "SCHOOL"          text,
  "LIT"             text,
  "EDATTAIN"        text,
  "EDATTAIND"       text,
  "YRSCHOOL"        text,
  "EDUCGH"          text,

  "EMPSECT"         text,
  "OCCISCO"         text,
  "OCC"             text,
  "ISCO68A"         text,
  "INDGEN"          text,
  "IND"             text,

  "MIGRATE5"        text,
  "GEOMIG1_5"       text,
  "MIGYRS1"         text,
  "MIG1_5_GH"       text,
  "MIG2_5_GH"       text,

  "DISABLED"        text
);
-- IMPORTANT --
-- Import CSV here using pgadmin4 import tool MANUALLY using "IMPORT/EXPORT DATA...". Do NOT use COPY command. 

-- 1st row to check proper import of header
SELECT *
FROM extract_6ghana
ORDER BY ctid
LIMIT 1;

-- Get unique values and frequencies for the "COUNTRY" column
SELECT "COUNTRY", COUNT(*) AS frequency
FROM extract_6ghana
GROUP BY "COUNTRY"
ORDER BY frequency DESC;

-- Backup
CREATE TABLE extract_6ghana_backup AS
SELECT * FROM extract_6ghana;

-- Master table for further analysis
CREATE TABLE master_6ghana AS
SELECT * FROM extract_6ghana;

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

-- Create column for birth province
ALTER TABLE public.master_6ghana
ADD COLUMN IF NOT EXISTS birth_province integer;

UPDATE public.master_6ghana
SET birth_province = CASE
    -- Western (288001)
    WHEN TRIM("BPLGH") = '01' THEN 288001

    -- Central (288002)
    WHEN TRIM("BPLGH") = '02' THEN 288002

    -- Greater Accra (288003)
    WHEN TRIM("BPLGH") = '03' THEN 288003

    -- Volta (288004)
    WHEN TRIM("BPLGH") = '04' THEN 288004

    -- Eastern (288005)
    WHEN TRIM("BPLGH") = '05' THEN 288005

    -- Ashanti (288006)
    WHEN TRIM("BPLGH") = '06' THEN 288006

    -- Brong Ahafo (288007)
    WHEN TRIM("BPLGH") = '07' THEN 288007

    -- Northern (288008)
    WHEN TRIM("BPLGH") = '08' THEN 288008

    -- Upper East (288009)
    WHEN TRIM("BPLGH") = '09' THEN 288009

    -- Upper West (288010)
    WHEN TRIM("BPLGH") = '10' THEN 288010

    -- Ghana, region not specified / Foreign country / Unknown
    WHEN TRIM("BPLGH") IN ('20', '97', '98') THEN NULL

    ELSE NULL
END;
-- ----------------------------------------------------------
-- 3.2 Foreign-born labeling
-- ----------------------------------------------------------

ALTER TABLE public.master_6ghana
ADD COLUMN IF NOT EXISTS "FOREIGN" integer;

UPDATE public.master_6ghana
SET "FOREIGN" = CASE
    WHEN TRIM("BPLGH") = '97' THEN 1
    ELSE 0
END;

-- ----------------------------------------------------------
-- 3.3 Age harmonization & cohort labeling
-- ----------------------------------------------------------

-- Clean age column
ALTER TABLE public.master_6ghana
ADD COLUMN IF NOT EXISTS age_clean integer;

-- Remove invalid values
UPDATE public.master_6ghana
SET age_clean = CASE
    WHEN CAST("AGE" AS integer) BETWEEN 0 AND 99 THEN CAST("AGE" AS integer)
    ELSE NULL
END;

-- Birthyear column
ALTER TABLE public.master_6ghana
ADD COLUMN IF NOT EXISTS birth_year integer;

-- Compute birthyear using year of census and age
ALTER TABLE public.master_6ghana
ALTER COLUMN "YEAR" TYPE integer
USING CAST("YEAR" AS integer);

UPDATE public.master_6ghana
SET birth_year = "YEAR" - age_clean;

-- Cohort creation 
ALTER TABLE public.master_6ghana
ADD COLUMN IF NOT EXISTS cohort integer;

UPDATE public.master_6ghana
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
DELETE FROM public.master_6ghana
WHERE cohort IS NULL;

-- Restrict age range to 20-90
DELETE FROM public.master_6ghana
WHERE age_clean < 20
   OR age_clean > 90;

-- ----------------------------------------------------------
-- 3.4 Education variable construction & labeling 
-- ----------------------------------------------------------

-- Cleaning EDATTAIND
DELETE FROM public.master_6ghana
WHERE CAST("EDATTAIND" AS integer) IN (0, 999);

-- Decode EDATTAIND for convenience
ALTER TABLE public.master_6ghana
ADD COLUMN IF NOT EXISTS education text;

UPDATE public.master_6ghana
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
ALTER TABLE public.master_6ghana
ADD COLUMN IF NOT EXISTS primary_educ boolean;

UPDATE public.master_6ghana
SET primary_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (100, 110, 120) THEN FALSE
    ELSE TRUE
END;

-- Binary labeling: lower secondary or higher
ALTER TABLE public.master_6ghana
ADD COLUMN IF NOT EXISTS higher_educ boolean;

UPDATE public.master_6ghana
SET higher_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (221, 222, 311, 312, 321, 322, 400) THEN TRUE
    ELSE FALSE
END;

-- Binary labeling: tertiary or equivalent
ALTER TABLE public.master_6ghana
ADD COLUMN IF NOT EXISTS tertiary_educ boolean;

UPDATE public.master_6ghana
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

DROP TABLE IF EXISTS public.edu_residence_6ghana;

CREATE TABLE public.edu_residence_6ghana AS
SELECT
    cohort,
    "GEO1_GH",

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
    COUNT(primary_educ) AS nc_ghana

FROM public.master_6ghana
WHERE cohort NOT IN (1905, 1985)
GROUP BY cohort, "GEO1_GH";


-- Join
DROP TABLE IF EXISTS public.geom_edu_residence_6ghana;

CREATE TABLE public.geom_edu_residence_6ghana AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_ghana
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_residence_6ghana e
    ON CAST(s."GEOLEVEL1" AS integer) = CAST(e."GEO1_GH" AS integer)
WHERE CAST(s."GEOLEVEL1" AS integer) BETWEEN 288001 AND 288010;
-- ----------------------------------------------------------
-- 4.2 Summary by birthplace region
-- ----------------------------------------------------------

-- Manual fix for upstream error: fucked up mapping of birth province codes.
ALTER TABLE public.master_6ghana
ADD COLUMN IF NOT EXISTS birth_province integer;

UPDATE public.master_6ghana
SET birth_province = CASE
    WHEN NULLIF(TRIM("BPLGH"), '')::integer = 1 THEN 288001
    WHEN NULLIF(TRIM("BPLGH"), '')::integer = 2 THEN 288002
    WHEN NULLIF(TRIM("BPLGH"), '')::integer = 3 THEN 288003
    WHEN NULLIF(TRIM("BPLGH"), '')::integer = 4 THEN 288004
    WHEN NULLIF(TRIM("BPLGH"), '')::integer = 5 THEN 288005
    WHEN NULLIF(TRIM("BPLGH"), '')::integer = 6 THEN 288006
    WHEN NULLIF(TRIM("BPLGH"), '')::integer = 7 THEN 288007
    WHEN NULLIF(TRIM("BPLGH"), '')::integer = 8 THEN 288008
    WHEN NULLIF(TRIM("BPLGH"), '')::integer = 9 THEN 288009
    WHEN NULLIF(TRIM("BPLGH"), '')::integer = 10 THEN 288010
    ELSE NULL
END;

-- Rest of code same as for other countries
DROP TABLE IF EXISTS public.edu_birthplace_6ghana;

CREATE TABLE public.edu_birthplace_6ghana AS
WITH birthplace_harmonized AS (
    SELECT
        cohort,
        birth_province,
        CAST("PERWT" AS numeric) AS perwt_num,
        primary_educ,
        higher_educ,
        tertiary_educ
    FROM public.master_6ghana
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

    COUNT(primary_educ) AS nc_ghana
FROM birthplace_harmonized
GROUP BY cohort, birth_province;

-- join
DROP TABLE IF EXISTS public.geom_edu_birthplace_6ghana;

CREATE TABLE public.geom_edu_birthplace_6ghana AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_ghana
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_birthplace_6ghana e
    ON CAST(s."GEOLEVEL1" AS integer) = e.birth_province
WHERE CAST(s."GEOLEVEL1" AS integer) IN (
    288001, 288002, 288003, 288004,
    288005, 288006, 288007, 288008,
    288009, 288010
);