-- ##########################################################
-- # 1. INTRODUCTION & METADATA
-- ##########################################################

-- Author       : Kuba Kowalski
-- Project      : RHI 2026 – IPUMS Africa (Kenya) Preprocessing
-- Script name  : 1_Kenya.sql
-- Last updated : 05/03/2026
-- Purpose      : Preprocess IPUMS census data (Kenya) for statistical analysis and spatial integration.

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
    -- IPUMS International: Kenya Census Microdata (2012, 2002, 1988)
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

/* CREATE TABLE public.extract_15Kenya (
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


CREATE TABLE public.extract_8kenya (
  "COUNTRY"         text,
  "YEAR"            text,
  "SAMPLE"          text,
  "SERIAL"          text,
  "PERSONS"         text,
  "HHWT"            text,
  "SUBSAMP"         text,
  "ENUMMO"          text,
  "ENUMHH"          text,
  "URBAN"           text,
  "REGIONW"         text,
  "GEOLEV1"         text,
  "GEOLEV2"         text,
  "DHS_IPUMSI_KE"   text,

  "PERNUM"          text,
  "PERWT"           text,
  "AGE"             text,
  "AGE2"            text,
  "SEX"             text,
  "MARST"           text,
  "MARSTD"          text,

  "BIRTHYR"         text,
  "BIRTHMO"         text,
  "CHBORN"          text,
  "CHSURV"          text,
  "LASTBMO"         text,
  "LASTBYR"         text,
  "CHDEAD"          text,
  "LASTBMORT"       text,
  "CHDEADYR"        text,
  "CHDEADMO"        text,
  "HOMECHILD"       text,
  "AWAYCHILD"       text,

  "NATIVITY"        text,
  "BPLCOUNTRY"      text,
  "CITIZEN"         text,
  "NATION"          text,
  "YRIMM"           text,
  "BPL1_KE"         text,
  "BPL2_KE"         text,

  "RELIGION"        text,
  "RELIGIOND"       text,
  "SCHOOL"          text,
  "LIT"             text,
  "EDATTAIN"        text,
  "EDATTAIND"       text,
  "YRSCHOOL"        text,
  "EDUCKE"          text,

  "EMPSTAT"         text,
  "EMPSTATD"        text,
  "CLASSWK"         text,
  "CLASSWKD"        text,
  "EMPSECT"         text,
  "OCCISCO"         text,
  "OCC"             text,

  "MIGRATE1"        text,
  "MIGCTRY1"        text,
  "GEOMIG1_1"       text,
  "MIGYRS1"         text,
  "MIG1_1_KE"       text,
  "MIG2_1_KE"       text,

  "DISABLED"        text
);

-- IMPORTANT --
-- Import CSV here using pgadmin4 import tool MANUALLY using "IMPORT/EXPORT DATA...". Do NOT use COPY command. 

-- 1st row to check proper import of header
SELECT *
FROM extract_8kenya
ORDER BY ctid
LIMIT 1;

-- Get unique values and frequencies for the "COUNTRY" column
SELECT "COUNTRY", COUNT(*) AS frequency
FROM extract_8kenya
GROUP BY "COUNTRY"
ORDER BY frequency DESC;

-- Backup
CREATE TABLE extract_8kenya_backup AS
SELECT * FROM extract_8kenya;

-- Master table for further analysis
CREATE TABLE master_8kenya AS
SELECT * FROM extract_8kenya;

-- ##########################################################
-- # 3. DATA CLEANING, HARMONIZATION & DERIVED VARIABLE CREATION
-- ##########################################################

-- ----------------------------------------------------------
-- 3.1 Birth province harmonization
-- ----------------------------------------------------------

-- Re-code to allow for cleaner matching with codebook

/* -- Re-code to follow 8340XX format
ALTER TABLE public.master_15Kenya
ADD COLUMN IF NOT EXISTS bpltz_834 integer;

UPDATE public.master_15Kenya
SET bpltz_834 =
    834000 + NULLIF(TRIM(bpltz), '')::integer; */

-- Create column for birth-province with full names
ALTER TABLE public.master_8kenya
ADD COLUMN IF NOT EXISTS birth_province text;

-- De-code birth province names based on bpltz codes
  -- Note: 7min processing 
UPDATE public.master_8kenya
SET birth_province = CASE
    -- Nairobi (404001)
    WHEN LOWER(TRIM("BPL1_KE")) IN (
        'nairobi west', 'nairobi east', 'nairobi north', 'westlands', 'nairobi'
    ) THEN '404001'

    -- Central (404002)
    WHEN LOWER(TRIM("BPL1_KE")) IN (
        'nyandarua north', 'nyandarua south', 'nyeri north', 'nyeri south',
        'kirinyaga', 'muranga north', 'muranga south', 'kiambu (kiambaa)',
        'kikuyu', 'kiambu west', 'lari', 'githunguri', 'thika east',
        'thika west', 'ruiru', 'gatanga', 'gatundu', 'nyandaura', 'nyeri',
        'muranga', 'thika', 'maragua', 'other central province'
    ) THEN '404002'

    -- Coast (404003)
    WHEN LOWER(TRIM("BPL1_KE")) IN (
        'mombasa', 'kilindini', 'kwale', 'kinango', 'msambweni', 'kilifi',
        'kaloleni', 'malindi', 'tana river', 'tana delta', 'lamu', 'taita',
        'taveta', 'taita taveta', 'other coast province'
    ) THEN '404003'

    -- Eastern (404004)
    WHEN LOWER(TRIM("BPL1_KE")) IN (
        'marsabit', 'chalbi', 'laisamis', 'moyale', 'isiolo', 'garba tulla',
        'imenti central', 'imenti north', 'imenti south', 'meru south',
        'maara', 'igembe', 'tigania', 'tharaka', 'embu', 'mbeere',
        'kitui north', 'kitui south (mutomo)', 'mwingi', 'kyuso',
        'machakos', 'mwala', 'yatta', 'kangundo', 'makueni', 'mbooni',
        'kibwezi', 'nzaui', 'kitui', 'meru', 'meru north', 'meru central',
        'other eastern province'
    ) THEN '404004'

    -- Northeastern (404005)
    WHEN LOWER(TRIM("BPL1_KE")) IN (
        'garissa', 'lagdera', 'fafi', 'ijara', 'wajir south', 'wajir north',
        'wajir east', 'wajir west', 'mandera central', 'mandera east',
        'mandera west', 'wajir', 'mandera', 'other north-eastern province'
    ) THEN '404005'

    -- Nyanza (404006)
    WHEN LOWER(TRIM("BPL1_KE")) IN (
        'siaya', 'bondo', 'rarieda', 'kisumu east', 'kisumu west', 'nyando',
        'homa bay', 'suba', 'rachuonyo', 'migori', 'rongo', 'kuria west',
        'kuria east', 'kisii central', 'kisii south', 'masaba', 'gucha',
        'gucha south', 'nyamira', 'manga', 'borabu', 'kisumu', 'kuria',
        'kisii', 'north kisii', 'south nyanza', 'other nyanza province'
    ) THEN '404006'

    -- Rift Valley (404007)
    WHEN LOWER(TRIM("BPL1_KE")) IN (
        'turkana central', 'turkana north', 'turkana south', 'west pokot',
        'pokot north', 'pokot central', 'samburu central', 'samburu east',
        'samburu north', 'trans nzoia west', 'trans nzoia east', 'kwanza',
        'baringo', 'baringo north', 'east pokot', 'koibatek', 'eldoret west',
        'eldoret east', 'wareng', 'marakwet', 'keiyo', 'nandi north',
        'nandi central', 'nandi east', 'nandi south', 'tinderet',
        'laikipia north', 'laikipia east', 'laikipia west', 'nakuru',
        'nakuru north', 'naivasha', 'molo', 'narok north', 'narok wouth',
        'trans mara', 'kajiado central', 'loitoktok', 'kericho', 'kipkelion',
        'buret', 'sotik', 'bomet', 'kajiado north', 'turkana', 'samburu',
        'trans nzoia', 'nandi', 'laikipia', 'narok', 'kajiado',
        'elgeyo markwet', 'uasin gishu', 'other rift valley province'
    ) THEN '404007'

    -- Western (404008)
    WHEN LOWER(TRIM("BPL1_KE")) IN (
        'kakamega central', 'kakamega south', 'kakamega north',
        'kakamega east', 'lugari', 'vihiga', 'emuhaya', 'hamisi',
        'mumias', 'butere', 'bungoma south', 'bungoma north',
        'bungoma east', 'bungoma west', 'mt. elgon', 'busia',
        'teso north', 'samia', 'bunyala', 'teso south', 'kakamega',
        'butere/mumias', 'bungoma', 'teso', 'other western province'
    ) THEN '404008'

    ELSE NULL
END;

-- ----------------------------------------------------------
-- 3.2 Foreign-born labeling
-- ----------------------------------------------------------

ALTER TABLE public.master_8kenya
ADD COLUMN IF NOT EXISTS "FOREIGN" integer;

UPDATE public.master_8kenya
SET "FOREIGN" = CASE
    WHEN CAST("BPL1_KE" AS integer) = 404097 THEN 1
    ELSE 0
END;

-- ----------------------------------------------------------
-- 3.3 Age harmonization & cohort labeling
-- ----------------------------------------------------------

-- Clean age column
ALTER TABLE public.master_8kenya
ADD COLUMN IF NOT EXISTS age_clean integer;

-- Remove invalid values
UPDATE public.master_8kenya
SET age_clean = CASE
    WHEN CAST("AGE" AS integer) BETWEEN 0 AND 99 THEN CAST("AGE" AS integer)
    ELSE NULL
END;

-- Birthyear column
ALTER TABLE public.master_8kenya
ADD COLUMN IF NOT EXISTS birth_year integer;

-- Compute birthyear using year of census and age
ALTER TABLE public.master_8kenya
ALTER COLUMN "YEAR" TYPE integer
USING CAST("YEAR" AS integer);

UPDATE public.master_8kenya
SET birth_year = "YEAR" - age_clean;

-- Cohort creation 
ALTER TABLE public.master_8kenya
ADD COLUMN IF NOT EXISTS cohort integer;

UPDATE public.master_8kenya
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
DELETE FROM public.master_8kenya
WHERE cohort IS NULL;

-- Restrict age range to 20-90
DELETE FROM public.master_8kenya
WHERE age_clean < 20
   OR age_clean > 90;

-- ----------------------------------------------------------
-- 3.4 Education variable construction & labeling 
-- ----------------------------------------------------------

-- Cleaning EDATTAIND
DELETE FROM public.master_8kenya
WHERE CAST("EDATTAIND" AS integer) IN (0, 999);

-- Decode EDATTAIND for convenience
ALTER TABLE public.master_8kenya
ADD COLUMN IF NOT EXISTS education text;

UPDATE public.master_8kenya
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
ALTER TABLE public.master_8kenya
ADD COLUMN IF NOT EXISTS primary_educ boolean;

UPDATE public.master_8kenya
SET primary_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (100, 110, 120) THEN FALSE
    ELSE TRUE
END;

-- Binary labeling: lower secondary or higher
ALTER TABLE public.master_8kenya
ADD COLUMN IF NOT EXISTS higher_educ boolean;

UPDATE public.master_8kenya
SET higher_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (221, 222, 311, 312, 321, 322, 400) THEN TRUE
    ELSE FALSE
END;

-- Binary labeling: tertiary or equivalent
ALTER TABLE public.master_8kenya
ADD COLUMN IF NOT EXISTS tertiary_educ boolean;

UPDATE public.master_8kenya
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

DROP TABLE IF EXISTS public.edu_residence_8kenya;

CREATE TABLE public.edu_residence_8kenya AS
SELECT
    cohort,
    "GEOLEV1",

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
    COUNT(primary_educ) AS nc_Kenya

FROM public.master_8kenya
WHERE cohort NOT IN (1905, 1985)
GROUP BY cohort, "GEOLEV1";

-- Join
DROP TABLE IF EXISTS public.geom_edu_residence_8kenya;

CREATE TABLE public.geom_edu_residence_8kenya AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_Kenya -- fucking fix this shit, unbelievable 
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_residence_8kenya e
    ON CAST(s."GEOLEVEL1" AS integer) = CAST(e."GEOLEV1" AS integer)
WHERE CAST(s."GEOLEVEL1" AS integer) BETWEEN 404001 AND 404008;

-- ----------------------------------------------------------
-- 4.2 Summary by birthplace region
-- ----------------------------------------------------------

DROP TABLE IF EXISTS public.edu_birthplace_8kenya;

CREATE TABLE public.edu_birthplace_8kenya AS
WITH birthplace_harmonized AS (
    SELECT
        cohort,
        CAST("BPL1_KE" AS integer) AS "GEO1_KE",
        CAST("PERWT" AS numeric) AS perwt_num,
        primary_educ,
        higher_educ,
        tertiary_educ
    FROM public.master_8kenya
    WHERE cohort NOT IN (1905, 1985)
      AND "FOREIGN" = 0
      AND CAST("BPL1_KE" AS integer) NOT IN (404097, 404098, 404099)
)
SELECT
    cohort,
    "GEO1_KE",

    SUM(perwt_num * (primary_educ::int))
        / NULLIF(SUM(perwt_num), 0) AS primary_educ,

    SUM(perwt_num * (higher_educ::int))
        / NULLIF(SUM(perwt_num), 0) AS higher_educ,

    SUM(perwt_num * (tertiary_educ::int))
        / NULLIF(SUM(perwt_num), 0) AS tertiary_educ,

    COUNT(primary_educ) AS nc_kenya
FROM birthplace_harmonized
WHERE "GEO1_KE" IS NOT NULL
GROUP BY cohort, "GEO1_KE";

-- join
DROP TABLE IF EXISTS public.geom_edu_birthplace_8kenya;

CREATE TABLE public.geom_edu_birthplace_8kenya AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_kenya
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_birthplace_8kenya e
    ON CAST(s."GEOLEVEL1" AS integer) = e."GEO1_KE"
WHERE CAST(s."GEOLEVEL1" AS integer) BETWEEN 404001 AND 404008;

-- ----------------------------------------------------------
-- 4.3 Summary by current residence region/gender
-- ----------------------------------------------------------

DROP TABLE IF EXISTS public.edu_residence_8kenya_gender;

CREATE TABLE public.edu_residence_8kenya_gender AS
SELECT
    cohort,
    "GEOLEV1",
    "SEX",

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
    COUNT(primary_educ) AS nc_kenya

FROM public.master_8kenya
WHERE cohort NOT IN (1905, 1985)
GROUP BY cohort, "GEOLEV1", "SEX";

-- Join
DROP TABLE IF EXISTS public.geom_edu_residence_8kenya_gender;

CREATE TABLE public.geom_edu_residence_8kenya_gender AS
SELECT
    s.*,
    e.cohort,
    e."SEX",
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_kenya
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_residence_8kenya_gender e
    ON CAST(s."GEOLEVEL1" AS integer) = CAST(e."GEOLEV1" AS integer)
WHERE CAST(s."GEOLEVEL1" AS integer) BETWEEN 404001 AND 404008;

-- ----------------------------------------------------------
-- 4.4 Summary by birthplace region/gender
-- ----------------------------------------------------------

DROP TABLE IF EXISTS public.edu_birthplace_8kenya_gender;

CREATE TABLE public.edu_birthplace_8kenya_gender AS
WITH birthplace_harmonized AS (
    SELECT
        cohort,
        "SEX",
        CAST("BPL1_KE" AS integer) AS "GEO1_KE",
        CAST("PERWT" AS numeric) AS perwt_num,
        primary_educ,
        higher_educ,
        tertiary_educ
    FROM public.master_8kenya
    WHERE cohort NOT IN (1905, 1985)
      AND "FOREIGN" = 0
      AND CAST("BPL1_KE" AS integer) NOT IN (404097, 404098, 404099)
)
SELECT
    cohort,
    "GEO1_KE",
    "SEX",

    SUM(perwt_num * (primary_educ::int))
        / NULLIF(SUM(perwt_num), 0) AS primary_educ,

    SUM(perwt_num * (higher_educ::int))
        / NULLIF(SUM(perwt_num), 0) AS higher_educ,

    SUM(perwt_num * (tertiary_educ::int))
        / NULLIF(SUM(perwt_num), 0) AS tertiary_educ,

    COUNT(primary_educ) AS nc_kenya
FROM birthplace_harmonized
WHERE "GEO1_KE" IS NOT NULL
GROUP BY cohort, "GEO1_KE", "SEX";

-- join
DROP TABLE IF EXISTS public.geom_edu_birthplace_8kenya_gender;

CREATE TABLE public.geom_edu_birthplace_8kenya_gender AS
SELECT
    s.*,
    e.cohort,
    e."SEX",
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_kenya
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_birthplace_8kenya_gender e
    ON CAST(s."GEOLEVEL1" AS integer) = e."GEO1_KE"
WHERE CAST(s."GEOLEVEL1" AS integer) BETWEEN 404001 AND 404008;

-- ----------------------------------------------------------
-- 4.5 Difference by residence region/gender
-- ----------------------------------------------------------
-- The code below was added to answer Ewout's question regarding gender-based differences in Kenya's Northeastern province. Not part of original assignment and thus not reproduced for other countries unless requested. 

-- remove gender = 9 (NIU)
DELETE FROM public.master_8kenya
WHERE CAST("SEX" AS integer) = 9
   OR "SEX" IS NULL;

-- create table
DROP TABLE IF EXISTS public.edu_residence_8kenya_diff;

CREATE TABLE public.edu_residence_8kenya_diff AS
SELECT
    cohort,
    "GEOLEV1",

    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN primary_educ END) AS primary_male,
    MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN primary_educ END) AS primary_female,
    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN primary_educ END)
      - MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN primary_educ END) AS primary_male_minus_female,

    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN higher_educ END) AS higher_male,
    MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN higher_educ END) AS higher_female,
    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN higher_educ END)
      - MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN higher_educ END) AS higher_male_minus_female,

    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN tertiary_educ END) AS tertiary_male,
    MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN tertiary_educ END) AS tertiary_female,
    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN tertiary_educ END)
      - MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN tertiary_educ END) AS tertiary_male_minus_female,

    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN nc_kenya END) AS n_male,
    MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN nc_kenya END) AS n_female

FROM public.edu_residence_8kenya_gender
GROUP BY cohort, "GEOLEV1";

-- join
DROP TABLE IF EXISTS public.geom_edu_residence_8kenya_diff;

CREATE TABLE public.geom_edu_residence_8kenya_diff AS
SELECT
    s.*,
    e.cohort,
    e.primary_male,
    e.primary_female,
    e.primary_male_minus_female,
    e.higher_male,
    e.higher_female,
    e.higher_male_minus_female,
    e.tertiary_male,
    e.tertiary_female,
    e.tertiary_male_minus_female,
    e.n_male,
    e.n_female
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_residence_8kenya_diff e
    ON CAST(s."GEOLEVEL1" AS integer) = CAST(e."GEOLEV1" AS integer)
WHERE CAST(s."GEOLEVEL1" AS integer) BETWEEN 404001 AND 404008;

-- ----------------------------------------------------------
-- 4.6 Difference by birthplace region/gender
-- ----------------------------------------------------------
DROP TABLE IF EXISTS public.edu_birthplace_8kenya_diff;

CREATE TABLE public.edu_birthplace_8kenya_diff AS
SELECT
    cohort,
    "GEO1_KE",

    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN primary_educ END) AS primary_male,
    MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN primary_educ END) AS primary_female,
    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN primary_educ END)
      - MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN primary_educ END) AS primary_male_minus_female,

    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN higher_educ END) AS higher_male,
    MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN higher_educ END) AS higher_female,
    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN higher_educ END)
      - MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN higher_educ END) AS higher_male_minus_female,

    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN tertiary_educ END) AS tertiary_male,
    MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN tertiary_educ END) AS tertiary_female,
    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN tertiary_educ END)
      - MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN tertiary_educ END) AS tertiary_male_minus_female,

    MAX(CASE WHEN CAST("SEX" AS integer) = 1 THEN nc_kenya END) AS n_male,
    MAX(CASE WHEN CAST("SEX" AS integer) = 2 THEN nc_kenya END) AS n_female

FROM public.edu_birthplace_8kenya_gender
GROUP BY cohort, "GEO1_KE";

-- join
DROP TABLE IF EXISTS public.geom_edu_birthplace_8kenya_diff;

CREATE TABLE public.geom_edu_birthplace_8kenya_diff AS
SELECT
    s.*,
    e.cohort,
    e.primary_male,
    e.primary_female,
    e.primary_male_minus_female,
    e.higher_male,
    e.higher_female,
    e.higher_male_minus_female,
    e.tertiary_male,
    e.tertiary_female,
    e.tertiary_male_minus_female,
    e.n_male,
    e.n_female
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_birthplace_8kenya_diff e
    ON CAST(s."GEOLEVEL1" AS integer) = e."GEO1_KE"
WHERE CAST(s."GEOLEVEL1" AS integer) BETWEEN 404001 AND 404008;