-- =====================================================================
-- HINGE USER TELEMETRY: DATA QUALITY & SAFETY AUDIT
-- Author: Renee Jon Orias
-- Objective: Audit user profiles for age/bot anomalies, fuzz exact GPS
--            coordinates for user safety, and generate a privacy-safe view.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. DATA QUALITY PROFILING: Identify Anomalies & Safety Violations
-- ---------------------------------------------------------------------

-- A. Detect Duplicate Profile Logs
SELECT 
    user_id, 
    COUNT(*) AS duplicate_count
FROM raw_hinge_user_activity
GROUP BY user_id
HAVING COUNT(*) > 1;

-- B. Flag Age Violations (Underage < 18 or Outlier Age > 100)
SELECT 
    user_id, 
    full_name, 
    age,
    account_status
FROM raw_hinge_user_activity
WHERE age < 18 OR age > 100;

-- C. Flag Blank or Incomplete Profile Responses (Potential Bot Accounts)
SELECT 
    user_id, 
    verified_status, 
    prompt_response_length 
FROM raw_hinge_user_activity
WHERE prompt_response_length IS NULL OR prompt_response_length = 0;

-- ---------------------------------------------------------------------
-- 2. DATA SANITIZATION & STAGING
-- ---------------------------------------------------------------------

CREATE TABLE staging_hinge_user_activity AS
SELECT DISTINCT
    user_id,
    TRIM(full_name) AS clean_full_name,
    CASE 
        WHEN age < 18 THEN NULL -- Exclude underage records
        WHEN age > 100 THEN NULL -- Reset invalid age entries
        ELSE age
    END AS clean_age,
    gender,
    TRIM(location_city) AS clean_city,
    exact_latitude,
    exact_longitude,
    verified_status,
    COALESCE(prompt_response_length, 0) AS clean_prompt_length,
    account_status
FROM raw_hinge_user_activity
WHERE age >= 18 AND age <= 100;

-- ---------------------------------------------------------------------
-- 3. USER SAFETY & GOVERNANCE: Location Fuzzing & PII Masking
-- ---------------------------------------------------------------------

-- View for Analytics & Product Teams (Fuzzes GPS coordinates to ~1km radius)
CREATE VIEW vw_anonymized_hinge_analytics AS
SELECT 
    user_id,
    -- Mask Full Name: 'Maya Lin' -> 'M*** L***'
    CONCAT(
        LEFT(clean_full_name, 1), '*** ',
        LEFT(SUBSTRING_INDEX(clean_full_name, ' ', -1), 1), '***'
    ) AS masked_name,
    clean_age,
    gender,
    clean_city,
    -- Location Fuzzing: Round GPS to 2 decimals to obscure exact neighborhood/street
    ROUND(exact_latitude, 2) AS fuzzed_latitude,
    ROUND(exact_longitude, 2) AS fuzzed_longitude,
    verified_status,
    clean_prompt_length,
    account_status
FROM staging_hinge_user_activity;
