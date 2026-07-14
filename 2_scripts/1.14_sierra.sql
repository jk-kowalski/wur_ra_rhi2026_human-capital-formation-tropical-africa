-- ##########################################################
-- # 1. INTRODUCTION & METADATA
-- ##########################################################

-- Author       : Kuba Kowalski
-- Project      : RHI 2026 – IPUMS Africa (Sierra Leone) Preprocessing
-- Script name  : 1.14_sierra.sql
-- Last updated : 03/05/2026
-- Purpose      : Preprocess IPUMS census data (Sierra Leone) for statistical analysis and spatial integration.

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
    -- IPUMS International: SBenin Census Microdata (2012, 2002, 1988)
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
CREATE TABLE public.extract_14sierra (
  "COUNTRY"          text,
  "YEAR"             text,
  "SAMPLE"           text,
  "SERIAL"           text,
  "HHWT"             text,
  "URBAN"            text,
  "REGIONW"          text,
  "GEOLEV1"          text,
  "GEOLEV2"          text,

  "GEO1_SL"          text,
  "GEO1_SL2004"      text,
  "GEO1_SL2015"      text,
  "GEO1ALT_SL2015"   text,

  "GEO2_SL"          text,
  "GEO2_SL2004"      text,
  "GEO2_SL2015"      text,
  "GEO2ALT_SL2015"   text,

  "PROVSL"           text,
  "DHS_IPUMSI_SL"    text,

  "PERNUM"           text,
  "PERWT"            text,
  "AGE"              text,
  "AGE2"             text,
  "SEX"              text,
  "MARST"            text,
  "MARSTD"           text,

  "CHBORN"           text,
  "CHSURV"           text,
  "CHDEAD"           text,

  "NATIVITY"         text,
  "BPLCOUNTRY"       text,
  "CITIZEN"          text,
  "NATION"           text,
  "BTHCERT"          text,
  "BPLSL"            text,

  "RELIGION"         text,
  "RELIGIOND"        text,
  "ETHNICSL"         text,
  "SPEAKENG"         text,
  "LANGSL2"          text,
  "MTONGSL"          text,

  "SCHOOL"           text,
  "LIT"              text,
  "EDATTAIN"         text,
  "EDATTAIND"        text,
  "YRSCHOOL"         text,
  "EDUCSL"           text,

  "EMPSTAT"          text,
  "EMPSTATD"         text,
  "LABFORCE"         text,
  "CLASSWK"          text,
  "CLASSWKD"         text,
  "EMPSECT"          text,
  "OCCISCO"          text,
  "OCC"              text,
  "INDGEN"           text,
  "IND"              text,

  "MIGRATE5"         text,
  "MIGCTRY5"         text,
  "GEOMIG1_5"        text,
  "MIG1_14_SL"       text,
  "MIG1_5_SL"        text,
  "MIG2_14_SL"       text,
  "MIG2_5_SL"        text,

  "DISABLED"         text
);

-- *IMPORTANT* --
-- Import CSV here using pgadmin4 import tool MANUALLY using "IMPORT/EXPORT DATA...". Do NOT use COPY command. 

-- 1st row to check proper import of header
SELECT *
FROM extract_14sierra
ORDER BY ctid
LIMIT 1;

-- Get unique values and frequencies for the "COUNTRY" column
SELECT "COUNTRY", COUNT(*) AS frequency
FROM extract_14sierra
GROUP BY "COUNTRY"
ORDER BY frequency DESC;

-- Backup
CREATE TABLE extract_14sierra_backup AS
SELECT * FROM extract_14sierra;

-- Master table for further analysis
CREATE TABLE master_14sierra AS
SELECT * FROM extract_14sierra;

-- ##########################################################
-- # 3. DATA CLEANING, HARMONIZATION & DERIVED VARIABLE CREATION
-- ##########################################################

-- ----------------------------------------------------------
-- 3.1 Birth province harmonization
-- ----------------------------------------------------------

-- Re-code to allow for cleaner matching with codebook, at least they're larger than sierra leone. 

-- 694011	Kailahun: Jawie, Kpeje Bongre, Kpeje West, Luawa, Malema, Njaluahun, Penguia, Upper Bambara, Yawei, Kissi Kama, Kissi Teng, Kissi Tongi
-- 694012	Kenema: Dodo, Dama, Gaura, Kandu Lekpeama, Simbaru, Kenema Town, Koya [Kenema], Niawa, Langrama, Lower Bambara, Nongowa, Small Bo, Tunkia, Nomo, Wandor, Gorama Mende, Malegohun
-- 694013	Kono: Gbane, Fiama, Gorama Kono, Tankoro, Kamara, Gbense, Koidu Town, Lei, Toli, Nimikoro, Nimiyama, Sandor, Soa, Mafindor, Gbane Kandor
-- 694021	Bombali: Biriwa, Magbaimba Ndorhahun, Bombali Sebora, Gbanti-Kamaranka, Makari Gbanti, Makeni Town, Safroko Limba, Paki Masabong, Sanda Loko, Sanda Tenraran, Libeisaygahun, Sella Limba, Gbendembu Ngowahun
-- 694022	Kambia: Gbinle-Dixing, Magbema, Masungbala, Tonko Limba, Bramaia, Mambolo, Samu
-- 694023	Koinadugu: Dembelia Sinkunia, Diang, Follosaba Dembelia, Mongo, Neya, Nieni, Sulima, Wara Wara Bafodia, Wara Wara Yagala, Sengbe, Kasunko
-- 694024	Port Loko: Kaffu Bullom, Lokomasama, BKM [Bureh Kaseh], Dibia, Marampa, Masimera, Sanda Magbolontor, TMS [T.M. Safroko], Maforki, Buya Romende
-- 694025	Tonkolili: Gbonkolenken, Kholifa Rowalla, Malal Mara, Kholifa Mabang, Tane, Yoni, Kunike Sanda, Kunike Barina, Sambaya, Tane, Kalansogoia, Kafe Simira
-- 694031	Bo: Bagbwe, Niawa Lenga, Bo Town, Baoma, Kakua, Jaiama-Bongor, Wunde, Kakua, Lugbu, Tikonko, Valunia, Selenga, Gbo, Bumpe Ngawo
-- 694032	Bonthe: Bum, Kwamebai Krim, Imperi, Bendu Cha, Jong, Nongoba Bullom, Yawbeko, Sittia, Bonthe Town, Dema, Sogbini, Kpanda Kemo
-- 694033	Moyamba: Bagruwa, Timdale, Bumpeh, Dasse, Kamajei, Kowa, Fakunya, Kagboro, Kaiyamba, Kori, Lower Banta, Upper Banta, Ribbi, Kongbora
-- 694034	Pujehun: Barri, Gallinasperi, Kpaka, YKK [Yekomo Kpukumu Krim], Mano Sakrim, Makpele, Malen, Kpanga-Kabonde, Sowa, Pejeh, Panga Krim, Soro Gbema
-- 694041	Western Rural: Koya [Western - rural], Waterloo, York - rural, Mountain
-- 694042	Western Urban: Western - urban - Central 1, Western - urban - Central 2, Western - urban - East 1, Western - urban - East 2, Western - urban - East 3,  Western - urban - West 1, Western - urban - West 2, Western - urban - West 3

-- birth prov for harm
ALTER TABLE public.master_14sierra
ADD COLUMN IF NOT EXISTS birth_province integer;

-- manual remapping 
UPDATE public.master_14sierra
SET birth_province = CASE
    WHEN CAST("BPLSL" AS integer) BETWEEN 1101 AND 1199 THEN 694011 -- Kailahun
    WHEN CAST("BPLSL" AS integer) BETWEEN 1201 AND 1299 THEN 694012 -- Kenema
    WHEN CAST("BPLSL" AS integer) BETWEEN 1301 AND 1399 THEN 694013 -- Kono

    WHEN CAST("BPLSL" AS integer) BETWEEN 2101 AND 2199 THEN 694021 -- Bombali
    WHEN CAST("BPLSL" AS integer) BETWEEN 2201 AND 2299 THEN 694022 -- Kambia
    WHEN CAST("BPLSL" AS integer) BETWEEN 2301 AND 2399 THEN 694023 -- Koinadugu
    WHEN CAST("BPLSL" AS integer) BETWEEN 2401 AND 2499 THEN 694024 -- Port Loko
    WHEN CAST("BPLSL" AS integer) BETWEEN 2501 AND 2599 THEN 694025 -- Tonkolili

    WHEN CAST("BPLSL" AS integer) BETWEEN 3101 AND 3199 THEN 694031 -- Bo
    WHEN CAST("BPLSL" AS integer) BETWEEN 3201 AND 3299 THEN 694032 -- Bonthe
    WHEN CAST("BPLSL" AS integer) BETWEEN 3301 AND 3399 THEN 694033 -- Moyamba
    WHEN CAST("BPLSL" AS integer) BETWEEN 3401 AND 3499 THEN 694034 -- Pujehun

    WHEN CAST("BPLSL" AS integer) BETWEEN 4101 AND 4199 THEN 694041 -- Western Rural
    WHEN CAST("BPLSL" AS integer) BETWEEN 4201 AND 4299 THEN 694042 -- Western Urban

    WHEN CAST("BPLSL" AS integer) IN (9997, 9998) THEN NULL

    ELSE NULL
END;
-- ----------------------------------------------------------
-- 3.2 Foreign-born labeling
-- ----------------------------------------------------------

ALTER TABLE public.master_14sierra
ADD COLUMN IF NOT EXISTS "FOREIGN" integer;

UPDATE public.master_14sierra
SET "FOREIGN" = CASE
    WHEN CAST("BPLSL" AS integer) = 9997 THEN 1
    WHEN CAST("BPLSL" AS integer) = 9998 THEN NULL
    ELSE 0
END;

-- ----------------------------------------------------------
-- 3.3 Age harmonization & cohort labeling
-- ----------------------------------------------------------

-- Clean age column
ALTER TABLE public.master_14sierra
ADD COLUMN IF NOT EXISTS age_clean integer;

-- Remove invalid values
UPDATE public.master_14sierra
SET age_clean = CASE
    WHEN CAST("AGE" AS integer) BETWEEN 0 AND 99 THEN CAST("AGE" AS integer)
    ELSE NULL
END;

-- Birthyear column
ALTER TABLE public.master_14sierra
ADD COLUMN IF NOT EXISTS birth_year integer;

-- Compute birthyear using year of census and age
ALTER TABLE public.master_14sierra
ALTER COLUMN "YEAR" TYPE integer
USING CAST("YEAR" AS integer);

UPDATE public.master_14sierra
SET birth_year = "YEAR" - age_clean;

-- Cohort creation 
ALTER TABLE public.master_14sierra
ADD COLUMN IF NOT EXISTS cohort integer;

UPDATE public.master_14sierra
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
DELETE FROM public.master_14sierra
WHERE cohort IS NULL;

-- Restrict age range to 20-90
DELETE FROM public.master_14sierra
WHERE age_clean < 20
   OR age_clean > 90;

-- ----------------------------------------------------------
-- 3.4 Education variable construction & labeling 
-- ----------------------------------------------------------

-- Cleaning EDATTAIND
DELETE FROM public.master_14sierra
WHERE CAST("EDATTAIND" AS integer) IN (0, 999);

-- Decode EDATTAIND for convenience
ALTER TABLE public.master_14sierra
ADD COLUMN IF NOT EXISTS education text;

UPDATE public.master_14sierra
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
ALTER TABLE public.master_14sierra
ADD COLUMN IF NOT EXISTS primary_educ boolean;

UPDATE public.master_14sierra
SET primary_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (100, 110, 120) THEN FALSE
    ELSE TRUE
END;

-- Binary labeling: lower secondary or higher
ALTER TABLE public.master_14sierra
ADD COLUMN IF NOT EXISTS higher_educ boolean;

UPDATE public.master_14sierra
SET higher_educ = CASE
    WHEN CAST("EDATTAIND" AS integer) IN (221, 222, 311, 312, 321, 322, 400) THEN TRUE
    ELSE FALSE
END;

-- Binary labeling: tertiary or equivalent
ALTER TABLE public.master_14sierra
ADD COLUMN IF NOT EXISTS tertiary_educ boolean;

UPDATE public.master_14sierra
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

DROP TABLE IF EXISTS public.edu_residence_14sierra;

CREATE TABLE public.edu_residence_14sierra AS
SELECT
    cohort,
    "GEO1_SL",

    SUM(CAST("PERWT" AS numeric) * (primary_educ::int)) 
        / NULLIF(SUM(CAST("PERWT" AS numeric)), 0) AS primary_educ,

    SUM(CAST("PERWT" AS numeric) * (higher_educ::int)) 
        / NULLIF(SUM(CAST("PERWT" AS numeric)), 0) AS higher_educ,

    SUM(CAST("PERWT" AS numeric) * (tertiary_educ::int)) 
        / NULLIF(SUM(CAST("PERWT" AS numeric)), 0) AS tertiary_educ,

    COUNT(primary_educ) AS nc_sierra

FROM public.master_14sierra
WHERE cohort NOT IN (1905, 1985)
GROUP BY cohort, "GEO1_SL";


-- Join
DROP TABLE IF EXISTS public.geom_edu_residence_14sierra;

CREATE TABLE public.geom_edu_residence_14sierra AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_sierra
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_residence_14sierra e
    ON CAST(s."GEOLEVEL1" AS integer) = CAST(e."GEO1_SL" AS integer)
WHERE CAST(s."GEOLEVEL1" AS integer) IN (
    694011, 694012, 694013,
    694021, 694022, 694023, 694024, 694025,
    694031, 694032, 694033, 694034,
    694041, 694042
);

-- ----------------------------------------------------------
-- 4.2 Summary by birthplace region
-- ----------------------------------------------------------

DROP TABLE IF EXISTS public.edu_birthplace_14sierra;

CREATE TABLE public.edu_birthplace_14sierra AS
WITH birthplace_harmonized AS (
    SELECT
        cohort,
        birth_province,
        CAST("PERWT" AS numeric) AS perwt_num,
        primary_educ,
        higher_educ,
        tertiary_educ
    FROM public.master_14sierra
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

    COUNT(primary_educ) AS nc_sierra
FROM birthplace_harmonized
GROUP BY cohort, birth_province;


-- Join
DROP TABLE IF EXISTS public.geom_edu_birthplace_14sierra;

CREATE TABLE public.geom_edu_birthplace_14sierra AS
SELECT
    s.*,
    e.cohort,
    e.primary_educ,
    e.higher_educ,
    e.tertiary_educ,
    e.nc_sierra
FROM public.world_geolev1_2021 s
LEFT JOIN public.edu_birthplace_14sierra e
    ON CAST(s."GEOLEVEL1" AS integer) = e.birth_province
WHERE CAST(s."GEOLEVEL1" AS integer) IN (
    694011, 694012, 694013,
    694021, 694022, 694023, 694024, 694025,
    694031, 694032, 694033, 694034,
    694041, 694042
);