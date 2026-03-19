# SaaS Product Analytics Dashboard

An end-to-end product analytics solution built to analyse user behaviour, feature adoption, churn patterns, and revenue metrics for a fictional B2B SaaS company. Built using SQL Server, Power BI, and Python.

---

## Dashboard Preview

### Page 1 — Executive Overview
![Executive Overview](screenshots/page1_executive_overview.png)

### Page 2 — User Behaviour & Engagement
![User Behaviour](screenshots/page2_user_behaviour.png)

### Page 3 — Feature Adoption
![Feature Adoption](screenshots/page3_feature_adoption.png)

### Page 4 — Churn & Retention
![Churn & Retention](screenshots/page4_churn_retention.png)

---

## Problem Statement

A B2B SaaS company offering a project management tool is struggling to understand why free trial users aren't converting to paid plans, and why existing paid users are churning after 3–4 months. The product team needs a data-driven view of user behaviour, feature adoption, and retention patterns to make informed decisions.

---

## Tech Stack

| Tool | Purpose |
|---|---|
| Python (Pandas, NumPy, Matplotlib) | Synthetic data generation, EDA |
| SQL Server | Data storage, cleaning, analytical queries |
| Power BI (DAX, Power Query) | Interactive dashboard, data modelling |

---

## Dataset

Synthetic dataset generated using Python with realistic dirty data issues:

| Table | Rows | Description |
|---|---|---|
| users | 5,000 | User demographics, plan type, acquisition channel |
| sessions | 6,566 | Session logs with device type and duration |
| feature_usage | 14,996 | Feature interaction logs per user |
| subscriptions | 5,000 | Subscription status, MRR, churn flag |

**Intentional data quality issues introduced:**
- Mixed date formats (YYYY-MM-DD, MM/DD/YYYY, DD-MM-YYYY)
- Inconsistent plan_type casing (free, Free, FREE, paid, Paid, PAID)
- NULL values in 5–8% of key columns
- Duplicate session records
- Missing acquisition channel values

---

## Project Workflow

### Step 1 — Data Generation (Python)
- Generated 4 synthetic tables using Pandas and NumPy
- Introduced realistic dirty data issues for cleaning practice
- Performed EDA across 5 dimensions:
  - Plan type distribution
  - Signup trends over time
  - Churn rate overview
  - Feature usage patterns
  - Session behaviour by device

### Step 2 — Data Cleaning (SQL Server)
- Standardised plan_type casing to lowercase
- Fixed mixed date formats using TRY_CONVERT with format codes 23, 101, 105
- Imputed NULL values (plan_type → 'free', acquisition_channel → 'unknown', duration_minutes → median 61, MRR → 0 for free / 59 for paid)
- Removed 13,434 duplicate session records
- Added clean date columns alongside raw columns for traceability

### Step 3 — Analytical Queries (SQL Server)
Wrote 5 query sets covering:
- Executive overview metrics (MRR, churn rate, signup trends)
- User behaviour and session analytics
- Feature adoption depth and usage patterns
- Churn analysis by industry, channel, and country
- Conversion funnel from free trial to paid active user

### Step 4 — Dashboard (Power BI)
Built a 4-page interactive dashboard with:
- Star schema data model (users as central dimension table)
- 20+ DAX measures
- Cross-page slicers for plan type, device type, industry, and feature
- Consistent Charcoal & Purple dark theme

---

## Data Model

Star schema with users as the central dimension table:

```
users (1) ──── (1) subscriptions
users (1) ──── (*) sessions
users (1) ──── (*) feature_usage
```

---

## Dashboard Pages

### Page 1 — Executive Overview
**Audience:** CEO, VP of Product

**KPIs:** Total Users | Total MRR | Churn Rate % | Paid Users %

**Visuals:**
- Monthly Signups Trend (Line Chart) — free vs paid breakdown
- Free vs Paid Split (Donut Chart)
- User Conversion Funnel — 5,000 → 2,571 → 2,458 → 1,273
- Conversion % by Acquisition Channel (Bar Chart)

**Key Finding:** Only 1 in 4 users is a paying, retained customer. Google drives highest conversion (51.2%) but also highest churn.

---

### Page 2 — User Behaviour & Engagement
**Audience:** Product Manager

**KPIs:** Total Sessions | Avg Session Duration | Free vs Paid Duration

**Visuals:**
- Monthly Session Volume (Line Chart) — stable ~500 sessions/month
- Sessions by Device Type (Donut Chart)
- Avg Session Duration by Plan Type (Bar Chart)
- Avg Duration by Device Type (Column Chart)

**Key Finding:** Free users have longer average sessions (62.1 mins) than paid users (60.3 mins) — suggesting paid users aren't deriving additional value from their subscription.

---

### Page 3 — Feature Adoption
**Audience:** Product Team

**KPIs:** Total Feature Events | Avg Usage Count | High Value Users %

**Visuals:**
- Feature Usage Volume (Bar Chart) — analytics most used, dashboard least
- Feature Adoption Depth (Column Chart) — Disengaged to Power Users
- Avg Feature Usage Free vs Paid (Clustered Bar)
- Conversion % by Adoption Segment (Column Chart)

**Key Finding:** Users adopting all 5 features convert at 55.3% vs 46.9% for single-feature users. 42.9% of active users are high-value (3+ features).

---

### Page 4 — Churn & Retention
**Audience:** Customer Success Team

**KPIs:** Churn Rate % | MRR Lost to Churn | Active Users

**Visuals:**
- Churn Rate by Industry (Bar Chart) — Manufacturing highest at 51.2%
- Churned vs Active Users (Donut Chart)
- Cohort Retention Rate by Signup Month (Line Chart)
- MRR Lost vs Retained (Bar Chart)

**Key Finding:** $90,548 in MRR is lost to churn monthly — nearly equal to $92,818 retained. Manufacturing and Google-acquired users show highest churn rates.

---

## Key Business Insights

1. **Conversion crisis** — Only 25.5% of total users are paid and active. Free-to-paid conversion needs urgent attention.

2. **Feature adoption drives revenue** — Users with 5 features convert at 55.3% vs 46.9% for single-feature users. Onboarding should push feature discovery in the first 7 days.

3. **Google paradox** — Google brings the most users (908) with the highest conversion (51.2%) but also the highest churn (51.2%). Acquisition quality needs re-evaluation.

4. **Referral is the best channel** — Referral users have the highest MRR ($18,969, avg $73/user) and lowest churn. Referral program should be prioritised.

5. **Manufacturing is the highest churn industry** — 51.2% churn rate. Targeted retention campaigns needed here first.

6. **Free users engage more than paid** — Free users have longer sessions (62.1 vs 60.3 mins) and nearly identical churn to paid users. Pricing or onboarding may be the issue, not engagement.

7. **$90,548 MRR lost monthly** — Nearly equal to retained MRR. Reducing churn by even 10% would add ~$9,000/month in recovered revenue.

---

## SQL Cleaning Highlights

```sql
-- Standardise plan_type casing
UPDATE users
SET plan_type = LOWER(LTRIM(RTRIM(plan_type)));

-- Fix mixed date formats
UPDATE users
SET signup_date_clean = TRY_CONVERT(DATE, signup_date, 23)
WHERE signup_date IS NOT NULL AND signup_date_clean IS NULL;

UPDATE users
SET signup_date_clean = TRY_CONVERT(DATE, signup_date, 101)
WHERE signup_date IS NOT NULL AND signup_date_clean IS NULL;

-- Remove duplicate sessions
DELETE FROM sessions
WHERE session_id NOT IN (
    SELECT MIN(session_id)
    FROM sessions
    GROUP BY user_id, date, device_type
);
```

---

## DAX Highlights

```
-- Churn Rate
Churn Rate % = 
FORMAT(
    DIVIDE(
        COUNTROWS(FILTER(subscriptions, subscriptions[churned] = "Y")),
        COUNTROWS(subscriptions), 0
    ) * 100, "0.0\%"
)

-- High Value Users
High Value Users % = 
FORMAT(
    DIVIDE(
        COUNTROWS(
            FILTER(
                VALUES(feature_usage[user_id]),
                CALCULATE(DISTINCTCOUNT(feature_usage[feature_name])) >= 3
            )
        ),
        DISTINCTCOUNT(feature_usage[user_id]), 0
    ) * 100, "0.0\%"
)

-- MRR Lost to Churn
MRR Lost to Churn = 
FORMAT(
    CALCULATE(SUM(subscriptions[MRR]), subscriptions[churned] = "Y"),
    "$#,##0"
)
```

---

## EDA Findings Summary

| Dimension | Finding |
|---|---|
| Plan Split | 49.2% paid, 48.8% free — near 50/50 |
| Signup Trend | Flat ~400/month — no growth signal |
| Churn Rate | 49.9% overall — free (50.2%) vs paid (49.6%) nearly identical |
| Feature Usage | Analytics most used, Dashboard least used |
| Session Behaviour | Stable ~500 sessions/month, avg 61.1 mins |

---

## Files in This Repository

```
SaaS-Product-Analytics-Dashboard/
├── data/
│   ├── users.csv
│   ├── sessions.csv
│   ├── feature_usage.csv
│   └── subscriptions.csv
├── screenshots/
│   ├── page1_executive_overview.png
│   ├── page2_user_behaviour.png
│   ├── page3_feature_adoption.png
│   └── page4_churn_retention.png
├── saas_analytics_complete.sql
├── saas_analytics_eda.py
└── README.md
```

---

## How to Run This Project

**Python EDA:**
```bash
pip install pandas numpy matplotlib
python saas_analytics_eda.py
```

**SQL Cleaning & Analysis:**
1. Open SQL Server Management Studio
2. Create database: `SaaS_Analytics`
3. Import 4 CSV files using Import Flat File wizard
4. Run `saas_analytics_complete.sql` section by section

**Power BI Dashboard:**
1. Open Power BI Desktop
2. Get Data → SQL Server → localhost → SaaS_Analytics
3. Load all 4 tables
4. Recreate data model and DAX measures as documented above

---

## Author

**Pratiksha Dandriyal**
BTech CSE | Data Analyst
[LinkedIn](https://linkedin.com/in/pratikshadandriyal) | [GitHub](https://github.com/pratikshadandriyal)

---

## Other Projects

- [Banking Analytics Dashboard](https://github.com/pratikshadandriyal/Banking-Analytics-PowerBI) — SQL Server + Power BI, 10,000+ transactions, 11 KPIs
- [AI Job Displacement Dashboard](https://github.com/pratikshadandriyal/AI-Job-Displacement-Dashboard) — Power BI, 13,700+ job records across 9 countries
