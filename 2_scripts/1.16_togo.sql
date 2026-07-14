-- ##########################################################
-- # 1. INTRODUCTION & METADATA
-- ##########################################################

-- Author       : Kuba Kowalski
-- Project      : RHI 2026 – IPUMS Africa (Togo) Preprocessing
-- Script name  : 1.16_togo.sql
-- Last updated : 16/04/2026
-- Purpose      : Preprocess IPUMS census data (Togo) for statistical analysis and spatial integration.

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
    -- IPUMS International: STogo Census Microdata (2012, 2002, 1988)
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
DROP TABLE IF EXISTS public.extract_16togo;

CREATE TABLE public.extract_16togo (
  "COUNTRY"            text,
  "YEAR"               text,
  "SAMPLE"             text,
  "SERIAL"             text,
  "HHWT"               text,
  "URBAN"              text,
  "REGIONW"            text,
  "GEOLEV1"            text,
  "GEOLEV2"            text,

  "GEO1_TG"            text,
  "GEO1_TG1960"        text,
  "GEO1_TG1970"        text,
  "GEO1_TG2010"        text,

  "GEO2_TG"            text,
  "GEO2_TG1970"        text,
  "GEO2_TG2010"        text,

  "DHS_IPUMSI_TG"      text,

  "PERNUM"             text,
  "PERWT"              text,
  "RESIDENT"           text,
  "AGE"                text,
  "AGE2"               text,
  "SEX"                text,
  "MARST"              text,
  "MARSTD"             text,

  "BIRTHYR"            text,
  "CHBORN"             text,
  "CHSURV"             text,
  "BIRTHSLYR"          text,

  "NATIVITY"           text,
  "BPLCOUNTRY"         text,
  "CITIZEN"            text,
  "NATION"             text,
  "BTHCERT"            text,

  "RELIGION"           text,
  "RELIGIOND"          text,
  "ETHNICTG"           text,
  "SPEAKENG"           text,

  "SCHOOL"             text,
  "LIT"                text,
  "EDATTAIN"           text,
  "EDATTAIND"          text,
  "YRSCHOOL"           text,
  "EDUCTG"             text,

  "EMPSTAT"            text,
  "EMPSTATD"           text,
  "LABFORCE"           text,
  "CLASSWK"            text,
  "CLASSWKD"           text,
  "OCCISCO"            text,
  "OCC"                text,
  "ISCO68A"            text,
  "INDGEN"             text,
  "IND"                text,

  "MIGRATEP"           text,
  "MIGCTRYP"           text,
  "GEOMIG1_P"          text,
  "MIGYRS1"            text,
  "MIG1_P_TG"          text,
  "MIG2_P_TG"          text,

  "DISABLED"           text,

  "TG1960A_BPLCNTRY"   text,
  "TG1960A_NATION"     text,
  "TG1960A_NATION2"    text,
  "TG1970A_BPL"        text,
  "TG2010A_BPLREG"     text,
  "TG2010A_BPLPREF"    text,
  "TG2010A_BPLURBAN"   text
);

-- *IMPORTANT* --
-- Import CSV here using pgadmin4 import tool MANUALLY using "IMPORT/EXPORT DATA...". Do NOT use COPY command. 

-- 1st row to check proper import of header
SELECT *
FROM extract_16togo
ORDER BY ctid
LIMIT 1;

-- Get unique values and frequencies for the "COUNTRY" column
SELECT "COUNTRY", COUNT(*) AS frequency
FROM extract_16togo
GROUP BY "COUNTRY"
ORDER BY frequency DESC;

-- Backup
CREATE TABLE extract_16togo_backup AS
SELECT * FROM extract_16togo;

-- Master table for further analysis
CREATE TABLE master_16togo AS
SELECT * FROM extract_16togo;

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
ALTER TABLE public.master_16togo
ADD COLUMN IF NOT EXISTS birth_province integer;

-- Manual recording 
    -- Complicated sich.
        -- 1960 lacks data for birthplace altogether, so NULL
        -- 1970 has birthplace but only recorded as "born in this village", "born in another village in the same region", "born in another region of the country", "born in another country", "unknown". Only the first two categories can be reliably matched to a province, so I will code them as the province of residence and all other categories as NULL.
        -- 2010 is nice and simple. Just copy & paste following harmonization rules:
            -- Lomé + Maritime = 768001
            -- Plateaux + Centrale + Kara = 768002
            -- Savanes = 768003
            -- Foreign born / unknown = NULL

UPDATE public.master_16togo
SET birth_province = CASE

    -- 1970: birthplace only usable when born in this village
    -- or another village in the same region
    WHEN CAST("YEAR" AS integer) = 1970
         AND CAST("TG1970A_BPL" AS integer) IN (1, 2)
    THEN CAST("GEO1_TG" AS integer)

    -- 1970: other region, other country, unknown
    WHEN CAST("YEAR" AS integer) = 1970
         AND CAST("TG1970A_BPL" AS integer) IN (3, 4, 9)
    THEN NULL

    -- 2010: Lomé + Maritime
    WHEN CAST("YEAR" AS integer) = 2010
         AND CAST("TG2010A_BPLREG" AS integer) IN (0, 1)
    THEN 768001

    -- 2010: Plateaux + Centrale + Kara
    WHEN CAST("YEAR" AS integer) = 2010
         AND CAST("TG2010A_BPLREG" AS integer) IN (2, 3, 4)
    THEN 768002

    -- 2010: Savanes
    WHEN CAST("YEAR" AS integer) = 2010
         AND CAST("TG2010A_BPLREG" AS integer) = 5
    THEN 768003

    -- 2010: foreign born / unknown
    WHEN CAST("YEAR" AS integer) = 2010
         AND CAST("TG2010A_BPLREG" AS integer) IN (7, 9)
    THEN NULL

    -- 1960 and all other unresolved cases
    ELSE NULL
END;

-- No clue what to do for 2012 since it comes only at department level in a completely different format that cannot be cleanly aggregated to 1991-2001 boundaries. Shit's fucked. 

-- ----------------------------------------------------------
-- 3.2 Foreign-born labeling
-- ----------------------------------------------------------

ALTER TABLE public.master_16togo
ADD COLUMN IF NOT EXISTS "FOREIGN" integer;

UPDATE public.master_16togo
SET "FOREIGN" = CASE

    -- 1970
    WHEN CAST("YEAR" AS integer) = 1970
         AND CAST("TG1970A_BPL" AS integer) = 4
    THEN 1

    WHEN CAST("YEAR" AS integer) = 1970
         AND CAST("TG1970A_BPL" AS integer) = 9
    THEN NULL

    WHEN CAST("YEAR" AS integer) = 1970
         AND CAST("TG1970A_BPL" AS integer) IN (1, 2, 3)
    THEN 0


    -- 2010
    WHEN CAST("YEAR" AS integer) = 2010
         AND CAST("TG2010A_BPLREG" AS integer) = 7
    THEN 1

    WHEN CAST("YEAR" AS integer) = 2010
         AND CAST("TG2010A_BPLREG" AS integer) = 9
    THEN NULL

    WHEN CAST("YEAR" AS integer) = 2010
         AND CAST("TG2010A_BPLREG" AS integer) BETWEEN 0 AND 5
    THEN 0


    -- 1960 (no info)
    WHEN CAST("YEAR" AS integer) = 1960
    THEN NULL

    ELSE NULL
END;

-- ----------------------------------------------------------
-- 3.3 Age harmonization & cohort labeling
-- ----------------------------------------------------------

-- Clean age column
ALTER TABLE public.master_16togo
ADD COLUMN IF NOT EXISTS age_clean integer;

-- Remove invalid values
UPDATE public.master_16togo
SET age_clean = CASE
    WHEN CAST("AGE" AS integer) BETWEEN 0 AND 99 THEN CAST("AGE" AS integer)
    ELSE NULL
END;

-- Birthyear column
ALTER TABLE public.master_16togo
ADD COLUMN IF NOT EXISTS birth_year integer;

-- Compute birthyear using year of census and age
ALTER TABLE public.master_16togo
ALTER COLUMN "YEAR" TYPE integer
USING CAST("YEAR" AS integer);

UPDATE public.master_16togo
SET birth_year = "YEAR" - age_clean;

-- Cohort creation 
ALTER TABLE public.master_16togo
ADD COLUMN IF NOT EXISTS cohort integer;

UPDATE public.master_16togo
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
DELETE FROM public.master_16togo
WHERE cohort IS NULL;

-- Restrict age range to 20-90
DELETE FROM public.master_16togo
WHERE age_clean < 20
   OR age_clean > 90;

-- ----------------------------------------------------------
-- 3.4 Education variable construction & labeling 
-- ----------------------------------------------------------

-- Cleaning EDATTAIND
DELETE FROM public.master_16togo
WHERE CAST("EDATTAIND" AS integer) IN (0, 999);

-- Decode EDATTAIND for convenience
ALTER TABLE public.master_16togo
ADD COLUMN IF NOT EXISTS education text;

UPDATE public.master_16togo
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
ALTER TABLE public.master_16togo
ADD COLUMN IF NOT EXISTS primary_educ boolean;

UPDATE public.master_16togo
SET primary_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (100, 110, 120) THEN FALSE
    ELSE TRUE
END;

-- Binary labeling: lower secondary or higher
ALTER TABLE public.master_16togo
ADD COLUMN IF NOT EXISTS higher_educ boolean;

UPDATE public.master_16togo
SET higher_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (221, 222, 311, 312, 321, 322, 400) THEN TRUE
    ELSE FALSE
END;

-- Binary labeling: tertiary or equivalent
ALTER TABLE public.master_16togo
ADD COLUMN IF NOT EXISTS tertiary_educ boolean;

UPDATE public.master_16togo
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

DROP TABLE IF EXISTS public.edu_residence_16togo;

CREATE TABLE public.edu_residence_16togo AS
SELECT
    cohort,
    "GEO1_TG",

    SUM(CAST("PERWT" AS numeric) * (primary_educ::int)) 
        / NULLIF(SUM(CAST("PERWT" AS numeric)), 0) AS primary_educ,

    SUM(CAST("PERWT" AS numeric) * (higher_educ::int)) 
        / NULLIF(SUM(CAST("PERWT" AS numeric)), 0) AS higher_educ,

    SUM(CAST("PERWT" AS numeric) * (tertiary_educ::int)) 
        / NULLIF(SUM(CAST("PERWT" AS numeric)), 0) AS tertiary_educ,

    COUNT(primary_educ) AS nc_togo

FROM public.master_16togo
WHERE cohort NOT IN (1905, 1985)
GROUP BY cohort, "GEO1_TG";


-- Join
DROP TABLE IF EXISTS public.geom_edu_residence_16togo;

CREATE TABLE public.geom_edu_residence_16togo AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_togo
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_residence_16togo e
    ON CAST(s."GEOLEVEL1" AS integer) = CAST(e."GEO1_TG" AS integer)
WHERE CAST(s."GEOLEVEL1" AS integer) IN (
    768001, 768002, 768003
);

-- ----------------------------------------------------------
-- 4.2 Summary by birthplace region
-- ----------------------------------------------------------

DROP TABLE IF EXISTS public.edu_birthplace_16togo;

CREATE TABLE public.edu_birthplace_16togo AS
WITH birthplace_harmonized AS (
    SELECT
        cohort,
        birth_province,
        CAST("PERWT" AS numeric) AS perwt_num,
        primary_educ,
        higher_educ,
        tertiary_educ
    FROM public.master_16togo
    WHERE cohort NOT IN (1905, 1985)
      AND "FOREIGN" = 0
      AND birth_province IS NOT NULL
      AND CAST("YEAR" AS integer) != 1960
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

    COUNT(primary_educ) AS nc_togo
FROM birthplace_harmonized
GROUP BY cohort, birth_province;


-- Join
DROP TABLE IF EXISTS public.geom_edu_birthplace_16togo;

CREATE TABLE public.geom_edu_birthplace_16togo AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_togo
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_birthplace_16togo e
    ON CAST(s."GEOLEVEL1" AS integer) = e.birth_province
WHERE CAST(s."GEOLEVEL1" AS integer) IN (
    768001, 768002, 768003
);