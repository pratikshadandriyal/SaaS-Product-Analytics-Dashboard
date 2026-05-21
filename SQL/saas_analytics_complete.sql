-- ============================================================
-- SaaS Product Analytics -- Complete SQL Script
-- Author: Pratiksha Dandriyal
-- Description: Data Cleaning + Analytical Queries
-- Database: SaaS_Analytics
-- Tables: users, sessions, feature_usage, subscriptions
-- ============================================================

-- ============================================================
-- SECTION 1: DATABASE SETUP
-- ============================================================

CREATE DATABASE SaaS_Analytics;
GO

USE SaaS_Analytics;
GO

-- ============================================================
-- SECTION 2: DATA CLEANING
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 USERS TABLE
-- ------------------------------------------------------------

-- Pre-cleaning audit
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) AS null_signup_dates,
    SUM(CASE WHEN plan_type IS NULL THEN 1 ELSE 0 END) AS null_plan_types,
    SUM(CASE WHEN acquisition_channel IS NULL THEN 1 ELSE 0 END) AS null_channels
FROM users;

-- Standardise plan_type to lowercase
UPDATE users
SET plan_type = LOWER(LTRIM(RTRIM(plan_type)));

-- Impute NULL plan_type as 'free'
UPDATE users
SET plan_type = 'free'
WHERE plan_type IS NULL;

-- Impute NULL acquisition_channel as 'unknown'
UPDATE users
SET acquisition_channel = 'unknown'
WHERE acquisition_channel IS NULL;

-- Add clean date column
ALTER TABLE users ADD signup_date_clean DATE;
GO

-- Fix mixed date formats (YYYY-MM-DD, MM/DD/YYYY, DD-MM-YYYY)
UPDATE users
SET signup_date_clean = TRY_CONVERT(DATE, signup_date, 23)
WHERE signup_date IS NOT NULL AND signup_date_clean IS NULL;

UPDATE users
SET signup_date_clean = TRY_CONVERT(DATE, signup_date, 101)
WHERE signup_date IS NOT NULL AND signup_date_clean IS NULL;

UPDATE users
SET signup_date_clean = TRY_CONVERT(DATE, signup_date, 105)
WHERE signup_date IS NOT NULL AND signup_date_clean IS NULL;

-- Post-cleaning audit
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN signup_date_clean IS NULL THEN 1 ELSE 0 END) AS null_dates_remaining,
    SUM(CASE WHEN plan_type = 'free' THEN 1 ELSE 0 END) AS free_users,
    SUM(CASE WHEN plan_type = 'paid' THEN 1 ELSE 0 END) AS paid_users,
    SUM(CASE WHEN acquisition_channel = 'unknown' THEN 1 ELSE 0 END) AS unknown_channels
FROM users;


-- ------------------------------------------------------------
-- 2.2 SESSIONS TABLE
-- ------------------------------------------------------------

-- Pre-cleaning audit
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS null_dates,
    SUM(CASE WHEN duration_minutes IS NULL THEN 1 ELSE 0 END) AS null_durations,
    SUM(CASE WHEN device_type IS NULL THEN 1 ELSE 0 END) AS null_devices
FROM sessions;

-- Add clean date column
ALTER TABLE sessions ADD date_clean DATE;
GO

-- Impute NULL device_type as 'unknown'
UPDATE sessions
SET device_type = 'unknown'
WHERE device_type IS NULL;

-- Fix mixed date formats
UPDATE sessions
SET date_clean = TRY_CONVERT(DATE, date, 23)
WHERE date IS NOT NULL AND date_clean IS NULL;

UPDATE sessions
SET date_clean = TRY_CONVERT(DATE, date, 101)
WHERE date IS NOT NULL AND date_clean IS NULL;

UPDATE sessions
SET date_clean = TRY_CONVERT(DATE, date, 105)
WHERE date IS NOT NULL AND date_clean IS NULL;

-- Impute NULL duration_minutes with median value (61)
UPDATE sessions
SET duration_minutes = 61
WHERE duration_minutes IS NULL;

-- Remove duplicate sessions (keep lowest session_id per user+date+device)
DELETE FROM sessions
WHERE session_id NOT IN (
    SELECT MIN(session_id)
    FROM sessions
    GROUP BY user_id, date, device_type
);

-- Post-cleaning audit
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN date_clean IS NULL THEN 1 ELSE 0 END) AS null_dates_remaining,
    SUM(CASE WHEN duration_minutes IS NULL THEN 1 ELSE 0 END) AS null_durations_remaining,
    SUM(CASE WHEN device_type = 'unknown' THEN 1 ELSE 0 END) AS unknown_devices
FROM sessions;


-- ------------------------------------------------------------
-- 2.3 FEATURE USAGE TABLE
-- ------------------------------------------------------------

-- Pre-cleaning audit
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS null_dates,
    SUM(CASE WHEN usage_count IS NULL THEN 1 ELSE 0 END) AS null_usage_counts,
    SUM(CASE WHEN feature_name IS NULL THEN 1 ELSE 0 END) AS null_features
FROM feature_usage;

-- Add clean date column
ALTER TABLE feature_usage ADD date_clean DATE;
GO

-- Fix mixed date formats
UPDATE feature_usage
SET date_clean = TRY_CONVERT(DATE, date, 23)
WHERE date IS NOT NULL AND date_clean IS NULL;

UPDATE feature_usage
SET date_clean = TRY_CONVERT(DATE, date, 101)
WHERE date IS NOT NULL AND date_clean IS NULL;

UPDATE feature_usage
SET date_clean = TRY_CONVERT(DATE, date, 105)
WHERE date IS NOT NULL AND date_clean IS NULL;

-- Impute NULL usage_count with median (25)
UPDATE feature_usage
SET usage_count = 25
WHERE usage_count IS NULL;

-- Remove duplicates
DELETE FROM feature_usage
WHERE CONCAT(user_id, feature_name, ISNULL(date, 'NULL')) IN (
    SELECT CONCAT(user_id, feature_name, ISNULL(date, 'NULL'))
    FROM feature_usage
    GROUP BY user_id, feature_name, date
    HAVING COUNT(*) > 1
)
AND usage_count NOT IN (
    SELECT MIN(usage_count)
    FROM feature_usage
    GROUP BY user_id, feature_name, date
    HAVING COUNT(*) > 1
);

-- Post-cleaning audit
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN date_clean IS NULL THEN 1 ELSE 0 END) AS null_dates_remaining,
    SUM(CASE WHEN usage_count IS NULL THEN 1 ELSE 0 END) AS null_usage_remaining
FROM feature_usage;


-- ------------------------------------------------------------
-- 2.4 SUBSCRIPTIONS TABLE
-- ------------------------------------------------------------

-- Pre-cleaning audit
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN plan_start_date IS NULL THEN 1 ELSE 0 END) AS null_start_dates,
    SUM(CASE WHEN plan_end_date IS NULL THEN 1 ELSE 0 END) AS null_end_dates,
    SUM(CASE WHEN churned IS NULL THEN 1 ELSE 0 END) AS null_churned,
    SUM(CASE WHEN MRR IS NULL THEN 1 ELSE 0 END) AS null_mrr
FROM [subscriptions];

-- Add clean date columns
ALTER TABLE [subscriptions] ADD plan_start_clean DATE;
ALTER TABLE [subscriptions] ADD plan_end_clean DATE;
GO

-- Fix plan_start_date formats
UPDATE [subscriptions]
SET plan_start_clean = TRY_CONVERT(DATE, plan_start_date, 23)
WHERE plan_start_date IS NOT NULL AND plan_start_clean IS NULL;

UPDATE [subscriptions]
SET plan_start_clean = TRY_CONVERT(DATE, plan_start_date, 101)
WHERE plan_start_date IS NOT NULL AND plan_start_clean IS NULL;

UPDATE [subscriptions]
SET plan_start_clean = TRY_CONVERT(DATE, plan_start_date, 105)
WHERE plan_start_date IS NOT NULL AND plan_start_clean IS NULL;

-- Fix plan_end_date formats
UPDATE [subscriptions]
SET plan_end_clean = TRY_CONVERT(DATE, plan_end_date, 23)
WHERE plan_end_date IS NOT NULL AND plan_end_clean IS NULL;

UPDATE [subscriptions]
SET plan_end_clean = TRY_CONVERT(DATE, plan_end_date, 101)
WHERE plan_end_date IS NOT NULL AND plan_end_clean IS NULL;

UPDATE [subscriptions]
SET plan_end_clean = TRY_CONVERT(DATE, plan_end_date, 105)
WHERE plan_end_date IS NOT NULL AND plan_end_clean IS NULL;

-- Standardise churned column to uppercase Y/N
UPDATE [subscriptions]
SET churned = UPPER(LTRIM(RTRIM(churned)));

-- Impute NULL churned as 'N'
UPDATE [subscriptions]
SET churned = 'N'
WHERE churned IS NULL;

-- Impute NULL MRR for free users = 0
UPDATE [subscriptions]
SET MRR = 0
WHERE MRR IS NULL
AND user_id IN (SELECT user_id FROM users WHERE plan_type = 'free');

-- Impute NULL MRR for paid users = median (59)
UPDATE [subscriptions]
SET MRR = 59
WHERE MRR IS NULL
AND user_id IN (SELECT user_id FROM users WHERE plan_type = 'paid');

-- Impute any remaining NULL MRR = 0
UPDATE [subscriptions]
SET MRR = 0
WHERE MRR IS NULL;

-- Post-cleaning audit
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN plan_start_clean IS NULL THEN 1 ELSE 0 END) AS null_start_remaining,
    SUM(CASE WHEN plan_end_clean IS NULL THEN 1 ELSE 0 END) AS null_end_remaining,
    SUM(CASE WHEN churned IS NULL THEN 1 ELSE 0 END) AS null_churned_remaining,
    SUM(CASE WHEN MRR IS NULL THEN 1 ELSE 0 END) AS null_mrr_remaining,
    SUM(CASE WHEN churned = 'Y' THEN 1 ELSE 0 END) AS churned_users,
    SUM(CASE WHEN churned = 'N' THEN 1 ELSE 0 END) AS active_users
FROM [subscriptions];


-- ============================================================
-- SECTION 3: ANALYTICAL QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 EXECUTIVE OVERVIEW (Page 1)
-- ------------------------------------------------------------

-- Total Users & Plan Split
SELECT 
    COUNT(*) AS total_users,
    SUM(CASE WHEN plan_type = 'free' THEN 1 ELSE 0 END) AS free_users,
    SUM(CASE WHEN plan_type = 'paid' THEN 1 ELSE 0 END) AS paid_users,
    ROUND(SUM(CASE WHEN plan_type = 'paid' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS paid_pct
FROM users;

-- Total MRR
SELECT 
    ROUND(SUM(MRR), 0) AS total_mrr,
    ROUND(AVG(MRR), 0) AS avg_mrr_per_user
FROM [subscriptions]
WHERE churned = 'N';

-- Overall Churn Rate
SELECT
    ROUND(SUM(CASE WHEN churned = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct,
    SUM(CASE WHEN churned = 'Y' THEN 1 ELSE 0 END) AS churned_users,
    SUM(CASE WHEN churned = 'N' THEN 1 ELSE 0 END) AS active_users
FROM [subscriptions];

-- Monthly Signups Trend
SELECT 
    FORMAT(signup_date_clean, 'yyyy-MM') AS signup_month,
    COUNT(*) AS new_signups,
    SUM(CASE WHEN plan_type = 'paid' THEN 1 ELSE 0 END) AS paid_signups,
    SUM(CASE WHEN plan_type = 'free' THEN 1 ELSE 0 END) AS free_signups
FROM users
WHERE signup_date_clean IS NOT NULL
GROUP BY FORMAT(signup_date_clean, 'yyyy-MM')
ORDER BY signup_month;

-- Acquisition Channel Performance
SELECT 
    acquisition_channel,
    COUNT(*) AS total_users,
    SUM(CASE WHEN plan_type = 'paid' THEN 1 ELSE 0 END) AS paid_users,
    ROUND(SUM(CASE WHEN plan_type = 'paid' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS conversion_pct
FROM users
GROUP BY acquisition_channel
ORDER BY conversion_pct DESC;


-- ------------------------------------------------------------
-- 3.2 USER BEHAVIOUR & ENGAGEMENT (Page 2)
-- ------------------------------------------------------------

-- Overall Session Stats
SELECT
    COUNT(*) AS total_sessions,
    ROUND(AVG(duration_minutes), 1) AS avg_duration_mins,
    ROUND(MIN(duration_minutes), 1) AS min_duration,
    ROUND(MAX(duration_minutes), 1) AS max_duration
FROM sessions;

-- Avg Session Duration by Device
SELECT
    device_type,
    COUNT(*) AS total_sessions,
    ROUND(AVG(duration_minutes), 1) AS avg_duration_mins
FROM sessions
GROUP BY device_type
ORDER BY avg_duration_mins DESC;

-- Sessions by Device Type %
SELECT
    device_type,
    COUNT(*) AS session_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct
FROM sessions
GROUP BY device_type
ORDER BY session_count DESC;

-- Avg Session Duration by Plan Type
SELECT
    u.plan_type,
    COUNT(*) AS total_sessions,
    ROUND(AVG(s.duration_minutes), 1) AS avg_duration_mins
FROM sessions s
JOIN users u ON s.user_id = u.user_id
GROUP BY u.plan_type
ORDER BY avg_duration_mins DESC;

-- Monthly Session Volume Trend
SELECT
    FORMAT(date_clean, 'yyyy-MM') AS month,
    COUNT(*) AS total_sessions,
    ROUND(AVG(duration_minutes), 1) AS avg_duration
FROM sessions
WHERE date_clean IS NOT NULL
GROUP BY FORMAT(date_clean, 'yyyy-MM')
ORDER BY month;


-- ------------------------------------------------------------
-- 3.3 FEATURE ADOPTION (Page 3)
-- ------------------------------------------------------------

-- Overall Feature Usage Distribution
SELECT
    feature_name,
    COUNT(*) AS total_usage_events,
    ROUND(AVG(usage_count), 1) AS avg_usage_count,
    COUNT(DISTINCT user_id) AS unique_users
FROM feature_usage
GROUP BY feature_name
ORDER BY total_usage_events DESC;

-- Feature Usage by Plan Type
SELECT
    f.feature_name,
    u.plan_type,
    COUNT(*) AS usage_events,
    ROUND(AVG(f.usage_count), 1) AS avg_usage_count
FROM feature_usage f
JOIN users u ON f.user_id = u.user_id
GROUP BY f.feature_name, u.plan_type
ORDER BY f.feature_name, u.plan_type;

-- Feature Adoption Depth per User
SELECT
    features_used,
    COUNT(*) AS user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct
FROM (
    SELECT 
        user_id,
        COUNT(DISTINCT feature_name) AS features_used
    FROM feature_usage
    GROUP BY user_id
) x
GROUP BY features_used
ORDER BY features_used;

-- High Value Users (3+ Features)
SELECT
    COUNT(*) AS high_value_users,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT user_id) FROM feature_usage), 1) AS pct_of_active_users
FROM (
    SELECT user_id
    FROM feature_usage
    GROUP BY user_id
    HAVING COUNT(DISTINCT feature_name) >= 3
) x;


-- ------------------------------------------------------------
-- 3.4 CHURN & RETENTION (Page 4)
-- ------------------------------------------------------------

-- Overall Churn Rate
SELECT
    SUM(CASE WHEN churned = 'Y' THEN 1 ELSE 0 END) AS churned_users,
    SUM(CASE WHEN churned = 'N' THEN 1 ELSE 0 END) AS active_users,
    ROUND(SUM(CASE WHEN churned = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM [subscriptions];

-- Churn Rate by Plan Type
SELECT
    u.plan_type,
    COUNT(*) AS total_users,
    SUM(CASE WHEN s.churned = 'Y' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN s.churned = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM [subscriptions] s
JOIN users u ON s.user_id = u.user_id
GROUP BY u.plan_type
ORDER BY churn_rate_pct DESC;

-- Churn Rate by Industry
SELECT
    u.industry,
    COUNT(*) AS total_users,
    SUM(CASE WHEN s.churned = 'Y' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN s.churned = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM [subscriptions] s
JOIN users u ON s.user_id = u.user_id
GROUP BY u.industry
ORDER BY churn_rate_pct DESC;

-- Churn Rate by Acquisition Channel
SELECT
    u.acquisition_channel,
    COUNT(*) AS total_users,
    SUM(CASE WHEN s.churned = 'Y' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN s.churned = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM [subscriptions] s
JOIN users u ON s.user_id = u.user_id
GROUP BY u.acquisition_channel
ORDER BY churn_rate_pct DESC;

-- Churn Rate by Country
SELECT
    u.country,
    COUNT(*) AS total_users,
    SUM(CASE WHEN s.churned = 'Y' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN s.churned = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM [subscriptions] s
JOIN users u ON s.user_id = u.user_id
GROUP BY u.country
ORDER BY churn_rate_pct DESC;

-- Revenue Lost to Churn
SELECT
    ROUND(SUM(CASE WHEN churned = 'Y' THEN MRR ELSE 0 END), 0) AS mrr_lost_to_churn,
    ROUND(SUM(CASE WHEN churned = 'N' THEN MRR ELSE 0 END), 0) AS mrr_retained,
    ROUND(SUM(CASE WHEN churned = 'Y' THEN MRR ELSE 0 END) * 100.0 / SUM(MRR), 1) AS pct_mrr_lost
FROM [subscriptions];

-- Cohort Retention -- Signup Month vs Churn
SELECT
    FORMAT(u.signup_date_clean, 'yyyy-MM') AS signup_cohort,
    COUNT(*) AS total_users,
    SUM(CASE WHEN s.churned = 'N' THEN 1 ELSE 0 END) AS retained_users,
    ROUND(SUM(CASE WHEN s.churned = 'N' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS retention_rate_pct
FROM [subscriptions] s
JOIN users u ON s.user_id = u.user_id
WHERE u.signup_date_clean IS NOT NULL
GROUP BY FORMAT(u.signup_date_clean, 'yyyy-MM')
ORDER BY signup_cohort;


-- ------------------------------------------------------------
-- 3.5 CONVERSION FUNNEL (Page 1 + Page 3)
-- ------------------------------------------------------------

-- Trial to Paid Conversion Funnel
SELECT
    'Total Users' AS funnel_stage,
    COUNT(*) AS user_count,
    100.0 AS pct
FROM users
UNION ALL
SELECT
    'Active Users (Not Churned)',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM users), 1)
FROM [subscriptions]
WHERE churned = 'N'
UNION ALL
SELECT
    'Paid Users',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM users), 1)
FROM users
WHERE plan_type = 'paid'
UNION ALL
SELECT
    'Paid + Active (Not Churned)',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM users), 1)
FROM [subscriptions] s
JOIN users u ON s.user_id = u.user_id
WHERE s.churned = 'N'
AND u.plan_type = 'paid';

-- Conversion Rate by Acquisition Channel
SELECT
    u.acquisition_channel,
    COUNT(*) AS total_users,
    SUM(CASE WHEN u.plan_type = 'paid' THEN 1 ELSE 0 END) AS paid_users,
    ROUND(SUM(CASE WHEN u.plan_type = 'paid' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS conversion_pct,
    SUM(CASE WHEN u.plan_type = 'paid' AND s.churned = 'N' THEN 1 ELSE 0 END) AS paid_active,
    ROUND(SUM(CASE WHEN u.plan_type = 'paid' AND s.churned = 'N' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS paid_active_pct
FROM users u
JOIN [subscriptions] s ON u.user_id = s.user_id
GROUP BY u.acquisition_channel
ORDER BY conversion_pct DESC;

-- Feature Adoption vs Conversion
SELECT
    features_used,
    COUNT(*) AS total_users,
    SUM(CASE WHEN plan_type = 'paid' THEN 1 ELSE 0 END) AS paid_users,
    ROUND(SUM(CASE WHEN plan_type = 'paid' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS conversion_pct
FROM (
    SELECT 
        f.user_id,
        COUNT(DISTINCT f.feature_name) AS features_used,
        u.plan_type
    FROM feature_usage f
    JOIN users u ON f.user_id = u.user_id
    GROUP BY f.user_id, u.plan_type
) x
GROUP BY features_used
ORDER BY features_used;

-- MRR by Acquisition Channel
SELECT
    u.acquisition_channel,
    u.plan_type,
    COUNT(*) AS users,
    ROUND(SUM(s.MRR), 0) AS total_mrr,
    ROUND(AVG(s.MRR), 0) AS avg_mrr
FROM users u
JOIN [subscriptions] s ON u.user_id = s.user_id
WHERE u.plan_type = 'paid'
AND s.churned = 'N'
GROUP BY u.acquisition_channel, u.plan_type
ORDER BY total_mrr DESC;
