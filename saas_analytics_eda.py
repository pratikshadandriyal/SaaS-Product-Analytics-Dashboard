# ============================================================
# SaaS Product Analytics -- Complete EDA Script
# Author: Pratiksha Dandriyal
# Description: Exploratory Data Analysis for all 4 tables
# ============================================================

import pandas as pd
import matplotlib.pyplot as plt

# ============================================================
# SETUP -- File Path
# ============================================================

path = r"C:\Users\prati_t686nlu\OneDrive\Desktop\SAAS Project CSV"

# Load all 4 CSVs
users = pd.read_csv(f"{path}\\users.csv")
sessions = pd.read_csv(f"{path}\\sessions.csv")
feature_usage = pd.read_csv(f"{path}\\feature_usage.csv")
subscriptions = pd.read_csv(f"{path}\\subscriptions.csv")


# ============================================================
# DATASET AUDIT
# ============================================================

print("=" * 60)
print("DATASET AUDIT")
print("=" * 60)

for name, df in [('USERS', users), ('SESSIONS', sessions),
                 ('FEATURE_USAGE', feature_usage), ('SUBSCRIPTIONS', subscriptions)]:
    print(f"\n--- {name} ---")
    print(f"Shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")
    print(f"NULL counts:\n{df.isnull().sum()}")


# ============================================================
# EDA STEP 1 -- Plan Type Distribution
# ============================================================

print("\n" + "=" * 60)
print("EDA STEP 1 -- PLAN TYPE DISTRIBUTION")
print("=" * 60)

# Normalize plan_type
users['plan_type_clean'] = users['plan_type'].str.lower().str.strip()

# Distribution
print("\nPlan Type Distribution:")
print(users['plan_type_clean'].value_counts(dropna=False))

# Percentage split
print("\n--- % breakdown ---")
print(users['plan_type_clean'].value_counts(dropna=False, normalize=True).mul(100).round(1))


# ============================================================
# EDA STEP 2 -- Signup Trends Over Time
# ============================================================

print("\n" + "=" * 60)
print("EDA STEP 2 -- SIGNUP TRENDS OVER TIME")
print("=" * 60)

# Parse dates with mixed formats
users['signup_date_clean'] = pd.to_datetime(
    users['signup_date'],
    format='mixed',
    errors='coerce'
)

# Date parsing summary
print(f"\nTotal rows: {len(users)}")
print(f"Successfully parsed dates: {users['signup_date_clean'].notna().sum()}")
print(f"Failed to parse (NaT): {users['signup_date_clean'].isna().sum()}")

# Monthly signup trend
users['signup_month'] = users['signup_date_clean'].dt.to_period('M')
monthly_signups = users.groupby('signup_month').size().reset_index(name='signups')

print("\n--- Monthly Signups ---")
print(monthly_signups.to_string())

# Plot
plt.figure(figsize=(12, 5))
plt.plot(monthly_signups['signup_month'].astype(str),
         monthly_signups['signups'], marker='o', color='steelblue')
plt.title('Monthly User Signups')
plt.xlabel('Month')
plt.ylabel('Number of Signups')
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig(f"{path}\\signup_trend.png")
plt.show()
print("Chart saved: signup_trend.png")


# ============================================================
# EDA STEP 3 -- Churn Rate Overview
# ============================================================

print("\n" + "=" * 60)
print("EDA STEP 3 -- CHURN RATE OVERVIEW")
print("=" * 60)

# Normalize churned column
subscriptions['churned_clean'] = subscriptions['churned'].str.upper().str.strip()

# Overall churn rate
print("\n--- Overall Churn Distribution ---")
print(subscriptions['churned_clean'].value_counts(dropna=False))

total_valid = subscriptions['churned_clean'].notna().sum()
churned_count = (subscriptions['churned_clean'] == 'Y').sum()
churn_rate = churned_count / total_valid * 100
print(f"\nOverall Churn Rate: {churn_rate:.1f}%")

# Churn by plan type
merged = subscriptions.merge(users[['user_id', 'plan_type_clean']], on='user_id', how='left')

print("\n--- Churn Rate by Plan Type ---")
churn_by_plan = merged.groupby('plan_type_clean')['churned_clean'].apply(
    lambda x: (x == 'Y').sum() / x.notna().sum() * 100
).round(1)
print(churn_by_plan)

# Churn by industry
print("\n--- Churn Rate by Industry ---")
churn_by_industry = merged.merge(
    users[['user_id', 'industry']], on='user_id', how='left'
).groupby('industry')['churned_clean'].apply(
    lambda x: (x == 'Y').sum() / x.notna().sum() * 100
).round(1).sort_values(ascending=False)
print(churn_by_industry)

# Plot churn by industry
plt.figure(figsize=(10, 5))
churn_by_industry.plot(kind='bar', color='tomato')
plt.title('Churn Rate by Industry')
plt.xlabel('Industry')
plt.ylabel('Churn Rate %')
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig(f"{path}\\churn_by_industry.png")
plt.show()
print("Chart saved: churn_by_industry.png")


# ============================================================
# EDA STEP 4 -- Feature Usage Patterns
# ============================================================

print("\n" + "=" * 60)
print("EDA STEP 4 -- FEATURE USAGE PATTERNS")
print("=" * 60)

# Overall feature usage
print("\n--- Overall Feature Usage Count ---")
print(feature_usage['feature_name'].value_counts())

# Avg usage count per feature
print("\n--- Avg Usage Count per Feature ---")
print(feature_usage.groupby('feature_name')['usage_count'].mean().round(1).sort_values(ascending=False))

# Unique users per feature
print("\n--- Unique Users per Feature ---")
print(feature_usage.groupby('feature_name')['user_id'].nunique().sort_values(ascending=False))

# Feature usage by plan type
merged_feat = feature_usage.merge(users[['user_id', 'plan_type_clean']], on='user_id', how='left')

print("\n--- Avg Usage Count by Feature and Plan Type ---")
pivot = merged_feat.groupby(['feature_name', 'plan_type_clean'])['usage_count'].mean().round(1).unstack()
print(pivot)

# Feature adoption depth
features_per_user = feature_usage.groupby('user_id')['feature_name'].nunique()
print(f"\n--- Feature Adoption Depth ---")
for i in range(1, 6):
    print(f"Users using {i} feature(s): {(features_per_user == i).sum()}")

# High value users (3+ features)
high_value = (features_per_user >= 3).sum()
total_active = features_per_user.count()
print(f"\nHigh Value Users (3+ features): {high_value} ({round(high_value/total_active*100, 1)}%)")

# Plot avg usage by feature
plt.figure(figsize=(10, 5))
feature_usage.groupby('feature_name')['usage_count'].mean().sort_values().plot(
    kind='barh', color='steelblue')
plt.title('Average Usage Count by Feature')
plt.xlabel('Avg Usage Count')
plt.tight_layout()
plt.savefig(f"{path}\\feature_usage_chart.png")
plt.show()
print("Chart saved: feature_usage_chart.png")


# ============================================================
# EDA STEP 5 -- Session Behaviour by Device
# ============================================================

print("\n" + "=" * 60)
print("EDA STEP 5 -- SESSION BEHAVIOUR BY DEVICE")
print("=" * 60)

# Drop NULL durations for analysis
sessions_clean = sessions.dropna(subset=['duration_minutes'])
print(f"\nRows after dropping NULL durations: {len(sessions_clean)} / {len(sessions)}")

# Overall session stats
print("\n--- Overall Session Duration Stats ---")
print(sessions_clean['duration_minutes'].describe().round(1))

# Avg session duration by device
print("\n--- Avg Session Duration by Device ---")
device_stats = sessions_clean.groupby('device_type')['duration_minutes'].agg(
    ['mean', 'median', 'count']).round(1)
print(device_stats)

# Sessions per user
sessions_per_user = sessions_clean.groupby('user_id').size()
print(f"\n--- Sessions per User ---")
print(f"Avg sessions per user: {sessions_per_user.mean():.1f}")
print(f"Max sessions per user: {sessions_per_user.max()}")
print(f"Min sessions per user: {sessions_per_user.min()}")

# Device type distribution
print("\n--- Device Type Distribution ---")
print(sessions_clean['device_type'].value_counts(dropna=False))
print("\n--- Device % ---")
print(sessions_clean['device_type'].value_counts(normalize=True).mul(100).round(1))

# Duration by plan type
merged_sess = sessions_clean.merge(users[['user_id', 'plan_type_clean']], on='user_id', how='left')
print("\n--- Avg Session Duration by Plan Type ---")
print(merged_sess.groupby('plan_type_clean')['duration_minutes'].mean().round(1))

# Monthly session volume
sessions_clean['date_parsed'] = pd.to_datetime(
    sessions_clean['date'], format='mixed', errors='coerce')
sessions_clean['month'] = sessions_clean['date_parsed'].dt.to_period('M')
monthly_sessions = sessions_clean.groupby('month').agg(
    total_sessions=('session_id', 'count'),
    avg_duration=('duration_minutes', 'mean')
).reset_index()
monthly_sessions['avg_duration'] = monthly_sessions['avg_duration'].round(1)

print("\n--- Monthly Session Volume ---")
print(monthly_sessions.to_string())

# Plot
fig, axes = plt.subplots(1, 2, figsize=(12, 5))

# Device distribution pie
sessions_clean['device_type'].value_counts().plot(
    kind='pie', ax=axes[0], autopct='%1.1f%%',
    colors=['steelblue', 'tomato', 'mediumseagreen'])
axes[0].set_title('Sessions by Device Type')
axes[0].set_ylabel('')

# Avg duration by device bar
device_stats['mean'].sort_values().plot(
    kind='barh', ax=axes[1], color='steelblue')
axes[1].set_title('Avg Session Duration by Device (mins)')
axes[1].set_xlabel('Minutes')

plt.tight_layout()
plt.savefig(f"{path}\\session_behaviour.png")
plt.show()
print("Chart saved: session_behaviour.png")


# ============================================================
# EDA SUMMARY
# ============================================================

print("\n" + "=" * 60)
print("EDA COMPLETE -- KEY FINDINGS SUMMARY")
print("=" * 60)
print("""
1. PLAN TYPE SPLIT
   - 49.2% paid, 48.8% free, 2% NULL
   - Near 50/50 split -- conversion focus needed

2. SIGNUP TRENDS
   - ~300-400 signups/month, flat growth
   - 25% dates failed to parse (mixed formats)
   - Plateau signals need to focus on retention

3. CHURN RATE
   - Overall churn: 49.9%
   - FREE: 50.2% vs PAID: 49.6% -- almost identical
   - Manufacturing churns most (53.1%)
   - Healthcare churns least (47.8%)

4. FEATURE ADOPTION
   - Analytics most used, Dashboard least used
   - 22% users use only 1 feature (churn risk)
   - 42.9% users use 3+ features (high value segment)
   - More features = higher conversion rate

5. SESSION BEHAVIOUR
   - Avg session duration: 60.6 mins
   - Even device split: mobile 33.7%, tablet 33.5%, desktop 32.7%
   - Free users engage longer than paid (62.1 vs 60.3 mins)
   - Stable ~500 sessions/month throughout 2024
""")
