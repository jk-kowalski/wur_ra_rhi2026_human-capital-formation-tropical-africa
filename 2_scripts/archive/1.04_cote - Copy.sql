-- ##########################################################
-- # 1. INTRODUCTION & METADATA
-- ##########################################################

-- Author       : Kuba Kowalski
-- Project      : RHI 2026 – IPUMS Africa (Cote d'Ivoire) Preprocessing
-- Script name  : 1.04_cote.sql
-- Last updated : 05/03/2026
-- Purpose      : Preprocess IPUMS census data (Cote d'Ivoire) for statistical analysis and spatial integration.

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
    -- IPUMS International: Senegal Census Microdata (2012, 2002, 1988)
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

CREATE TABLE public.extract_4cote (
  "COUNTRY"         text,
  "YEAR"            text,
  "SAMPLE"          text,
  "SERIAL"          text,
  "HHWT"            text,
  "URBAN"           text,
  "REGIONW"         text,
  "GEOLEV1"         text,
  "GEOLEV2"         text,

  "GEO1_CI"         text,
  "GEO1_CI1988"     text,
  "GEO1_CI1998"     text,

  "GEO2_CI"         text,
  "GEO2_CI1988"     text,
  "GEO2_CI1998"     text,

  "DHS_IPUMSI_CI"   text,

  "PERNUM"          text,
  "PERWT"           text,
  "RESIDENT"        text,
  "AGE"             text,
  "AGE2"            text,
  "SEX"             text,
  "MARST"           text,
  "MARSTD"          text,

  "BIRTHYR"         text,
  "BIRTHMO"         text,
  "CHBORN"          text,
  "CHSURV"          text,
  "BIRTHSLYR"       text,

  "NATIVITY"        text,
  "BPLCOUNTRY"      text,
  "CITIZEN"         text,
  "NATION"          text,
  "BPL1_CI"         text,
  "BPL2_CI"         text,

  "RELIGION"        text,
  "RELIGIOND"       text,
  "ETHNICCI"        text,
  "LIT"             text,
  "EDATTAIN"        text,
  "EDATTAIND"       text,
  "YRSCHOOL"        text,
  "EDUCCI"          text,

  "OCCISCO"         text,
  "OCC"             text,
  "INDGEN"          text,
  "IND"             text,

  "MIGRATE1"        text,
  "MIGCTRY1"        text,
  "GEOMIG1_1"       text,
  "MIG1_1_CI"       text,
  "MIG2_1_CI"       text,

  "DISABLED"        text
);

-- IMPORTANT --
-- Import CSV here using pgadmin4 import tool MANUALLY using "IMPORT/EXPORT DATA...". Do NOT use COPY command. 

-- 1st row to check proper import of header
SELECT *
FROM extract_4cote
ORDER BY ctid
LIMIT 1;

-- Get unique values and frequencies for the "COUNTRY" column
SELECT "COUNTRY", COUNT(*) AS frequency
FROM extract_4cote
GROUP BY "COUNTRY"
ORDER BY frequency DESC;

-- Backup
CREATE TABLE extract_4cote_backup AS
SELECT * FROM extract_4cote;

-- Master table for further analysis
CREATE TABLE master_4cote AS
SELECT * FROM extract_4cote;

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
ALTER TABLE public.master_4cote
ADD COLUMN IF NOT EXISTS birth_province integer;

UPDATE public.master_4cote
SET birth_province = CASE
    WHEN CAST("BPL1_CI" AS integer) = 384001 THEN 384001
    WHEN CAST("BPL1_CI" AS integer) = 384002 THEN 384002
    WHEN CAST("BPL1_CI" AS integer) = 384003 THEN 384003
    WHEN CAST("BPL1_CI" AS integer) = 384004 THEN 384004
    WHEN CAST("BPL1_CI" AS integer) = 384005 THEN 384005
    WHEN CAST("BPL1_CI" AS integer) = 384006 THEN 384006
    WHEN CAST("BPL1_CI" AS integer) = 384008 THEN 384008
    WHEN CAST("BPL1_CI" AS integer) = 384009 THEN 384009
    WHEN CAST("BPL1_CI" AS integer) = 384010 THEN 384010
    ELSE NULL
END;
-- ----------------------------------------------------------
-- 3.2 Foreign-born labeling
-- ----------------------------------------------------------

ALTER TABLE public.master_4cote
ADD COLUMN IF NOT EXISTS "FOREIGN" integer;

UPDATE public.master_4cote
SET "FOREIGN" = CASE
    WHEN CAST("BPLCOUNTRY" AS integer) != 384 THEN 1
    ELSE 0
END;

-- ----------------------------------------------------------
-- 3.3 Age harmonization & cohort labeling
-- ----------------------------------------------------------

-- Clean age column
ALTER TABLE public.master_4cote
ADD COLUMN IF NOT EXISTS age_clean integer;

-- Remove invalid values
UPDATE public.master_4cote
SET age_clean = CASE
    WHEN CAST("AGE" AS integer) BETWEEN 0 AND 99 THEN CAST("AGE" AS integer)
    ELSE NULL
END;

-- Birthyear column
ALTER TABLE public.master_4cote
ADD COLUMN IF NOT EXISTS birth_year integer;

-- Compute birthyear using year of census and age
ALTER TABLE public.master_4cote
ALTER COLUMN "YEAR" TYPE integer
USING CAST("YEAR" AS integer);

UPDATE public.master_4cote
SET birth_year = "YEAR" - age_clean;

-- Cohort creation 
ALTER TABLE public.master_4cote
ADD COLUMN IF NOT EXISTS cohort integer;

UPDATE public.master_4cote
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
DELETE FROM public.master_4cote
WHERE cohort IS NULL;

-- Restrict age range to 20-90
DELETE FROM public.master_4cote
WHERE age_clean < 20
   OR age_clean > 90;

-- ----------------------------------------------------------
-- 3.4 Education variable construction & labeling 
-- ----------------------------------------------------------

-- Cleaning EDATTAIND
DELETE FROM public.master_4cote
WHERE CAST("EDATTAIND" AS integer) IN (0, 999);

-- Decode EDATTAIND for convenience
ALTER TABLE public.master_4cote
ADD COLUMN IF NOT EXISTS education text;

UPDATE public.master_4cote
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
ALTER TABLE public.master_4cote
ADD COLUMN IF NOT EXISTS primary_educ boolean;

UPDATE public.master_4cote
SET primary_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (100, 110, 120) THEN FALSE
    ELSE TRUE
END;

-- Binary labeling: lower secondary or higher
ALTER TABLE public.master_4cote
ADD COLUMN IF NOT EXISTS higher_educ boolean;

UPDATE public.master_4cote
SET higher_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (221, 222, 311, 312, 321, 322, 400) THEN TRUE
    ELSE FALSE
END;

-- Binary labeling: tertiary or equivalent
ALTER TABLE public.master_4cote
ADD COLUMN IF NOT EXISTS tertiary_educ boolean;

UPDATE public.master_4cote
SET tertiary_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (312, 322, 400) THEN TRUE
    ELSE FALSE
END;

-- ##########################################################
-- # 4. SPATIAL JOIN & SUMMARY STATISTICS
-- ##########################################################

-- ----------------------------------------------------------
-- 4.0 Recoding & merging 1998 geolev1 Cote d'Ivoire objects to fit codebook GEO1_CI & BPL1_CI
-- ----------------------------------------------------------
SELECT DISTINCT "IPUM1998", "ADMIN_NAME"
FROM public.geo1_ci1998
ORDER BY "IPUM1998", "ADMIN_NAME";

DROP TABLE IF EXISTS public.geo1_ci1998_dissolved;

CREATE TABLE public.geo1_ci1998_dissolved AS
WITH recoded AS (
    SELECT
        CASE
            WHEN TRIM("IPUM1998") IN ('001', '013', '015', '016') THEN 384001
            WHEN TRIM("IPUM1998") IN ('002', '012', '017') THEN 384002
            WHEN TRIM("IPUM1998") = '003' THEN 384003
            WHEN TRIM("IPUM1998") IN ('004', '007', '011') THEN 384004
            WHEN TRIM("IPUM1998") = '005' THEN 384005
            WHEN TRIM("IPUM1998") IN ('006', '018') THEN 384006
            WHEN TRIM("IPUM1998") = '008' THEN 384008
            WHEN TRIM("IPUM1998") = '009' THEN 384009
            WHEN TRIM("IPUM1998") IN ('010', '014', '019') THEN 384010
            ELSE NULL
        END AS "GEOLEVEL1",
        ST_SnapToGrid(ST_MakeValid(geom), 0.000001) AS geom
    FROM public.geo1_ci1998
),
dissolved AS (
    SELECT
        "GEOLEVEL1",
        ST_UnaryUnion(ST_Collect(geom)) AS geom
    FROM recoded
    WHERE "GEOLEVEL1" IS NOT NULL
    GROUP BY "GEOLEVEL1"
)
SELECT
    "GEOLEVEL1",
    ST_Multi(ST_CollectionExtract(geom, 3)) AS geom
FROM dissolved;

ALTER TABLE public.geo1_ci1998_dissolved
ADD COLUMN gid serial PRIMARY KEY;

CREATE INDEX geo1_ci1998_dissolved_geom_idx
ON public.geo1_ci1998_dissolved
USING GIST (geom);

SELECT "GEOLEVEL1", COUNT(*)
FROM public.geo1_ci1998_dissolved
GROUP BY "GEOLEVEL1"
ORDER BY "GEOLEVEL1";

-- birthprov matchign still fails, no clue why
ALTER TABLE public.master_4cote
DROP COLUMN IF EXISTS "FOREIGN";

ALTER TABLE public.master_4cote
ADD COLUMN "FOREIGN" integer;

UPDATE public.master_4cote
SET "FOREIGN" = CASE
    WHEN TRIM("BPL1_CI") = '384097' THEN 1
    WHEN TRIM("BPL1_CI") IN (
        '384001', '384002', '384003', '384004',
        '384005', '384006', '384008', '384009', '384010'
    ) THEN 0
    ELSE NULL
END;

-- ----------------------------------------------------------
-- 4.1 Summary by current residence region
-- ----------------------------------------------------------

DROP TABLE IF EXISTS public.edu_residence_4cote;

CREATE TABLE public.edu_residence_4cote AS
SELECT
    cohort,
    "GEO1_CI",

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
    COUNT(primary_educ) AS nc_cote

FROM public.master_4cote
WHERE cohort NOT IN (1905, 1985)
GROUP BY cohort, "GEO1_CI";


-- Join
DROP TABLE IF EXISTS public.geom_edu_residence_4cote;

CREATE TABLE public.geom_edu_residence_4cote AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_cote
FROM public.geo1_ci1998_dissolved s
LEFT JOIN public.edu_residence_4cote e
    ON CAST(s."GEOLEVEL1" AS integer) = CAST(e."GEO1_CI" AS integer)
WHERE CAST(s."GEOLEVEL1" AS integer) IN (
    384001, 384002, 384003, 384004,
    384005, 384006, 384008, 384009, 384010
);
-- ----------------------------------------------------------
-- 4.2 Summary by birthplace region
-- ----------------------------------------------------------

DROP TABLE IF EXISTS public.edu_birthplace_4cote;

CREATE TABLE public.edu_birthplace_4cote AS
WITH birthplace_harmonized AS (
    SELECT
        cohort,
        birth_province,
        CAST("PERWT" AS numeric) AS perwt_num,
        primary_educ,
        higher_educ,
        tertiary_educ
    FROM public.master_4cote
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

    COUNT(primary_educ) AS nc_cote
FROM birthplace_harmonized
GROUP BY cohort, birth_province;

-- join
DROP TABLE IF EXISTS public.geom_edu_birthplace_4cote;

CREATE TABLE public.geom_edu_birthplace_4cote AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_cote
FROM public.geo1_ci1998_dissolved s
LEFT JOIN public.edu_birthplace_4cote e
    ON CAST(s."GEOLEVEL1" AS integer) = e.birth_province
WHERE CAST(s."GEOLEVEL1" AS integer) IN (
    384001, 384002, 384003, 384004,
    384005, 384006, 384008, 384009, 384010
);