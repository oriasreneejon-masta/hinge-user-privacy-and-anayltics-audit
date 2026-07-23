![Banner] (hingelogo.png)
# Hinge User Telemetry: Data Quality & Safety Audit

## 📌 Business Overview
On consumer dating platforms like Hinge, user safety, privacy, and data integrity are core product requirements. Raw telemetry data capturing user locations, ages, and profile verification statuses must be audited to ensure compliance with global privacy regulations (**GDPR/CCPA**) and to prevent the exposure of sensitive user locations.

This repository demonstrates a SQL data governance pipeline that cleans raw profile telemetry, flags age/bot anomalies, **fuzzes exact GPS coordinates**, and constructs an anonymized analytical view for product engagement modeling.

---

## 🛠️ Data Quality & Safety Audit Summary

| Risk / Issue Area | Problem Identified in Raw Data | Resolution / SQL Technique |
| :--- | :--- | :--- |
| **Location Safety** | Raw GPS coordinates (`40.7128, -74.0060`) exposed exact real-time user locations. | Applied **location fuzzing** via `ROUND(exact_latitude, 2)` to generalize coordinates to a safe ~1km zone. |
| **User Safety / Compliance** | Out-of-bounds ages logged (`age: 17` and `age: 105`). | Filtered out underage accounts (<18) and scrubbed invalid age entries in staging. |
| **PII Exposure** | Full member names visible in raw telemetry logs. | Masked member names (`M*** L***`) using string extraction in `vw_anonymized_hinge_analytics`. |
| **Bot / Spam Flags** | Unverified accounts with 0-character prompt responses. | Isolated empty prompt length logs using `COALESCE()` and flagged for fraud auditing. |

---

## 📖 Data Dictionary (Anonymized Analytics View)

| Column Name | Data Type | Privacy Level | Description |
| :--- | :--- | :--- | :--- |
| `user_id` | String | Low | Anonymized profile identifier. |
| `masked_name` | String | Masked | Anonymized member name (`M*** L***`). |
| `clean_age` | Integer | Internal | Verified user age (filtered for $18 \le \text{age} \le 100$). |
| `fuzzed_latitude` | Decimal | Obfuscated | Latitude rounded to 2 decimal places to prevent exact address lookup. |
| `fuzzed_longitude` | Decimal | Obfuscated | Longitude rounded to 2 decimal places to protect physical safety. |
| `verified_status` | String | Internal | Account verification standing (`Verified`, `Unverified`). |

---

## 🛠️ Tech Stack
* **Language:** SQL (PostgreSQL / MySQL compatible)
* **Privacy Standards:** Location Fuzzing & PII Masking (Privacy-by-Design)
* **Documentation:** Data Dictionaries & Markdown
