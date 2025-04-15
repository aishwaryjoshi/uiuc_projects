# 📊 Illinois Wellness Claims Analysis (R)

**Contributor:** Aishwary Joshi  
**Date:** November 14, 2024  

---

## 📁 Dataset
The dataset used in this problem set is `claims.csv`, which contains pre- and post-randomization claims data for individuals participating in a wellness program.  
Data Source: [Public Wellness Data Repository](https://reifjulian.github.io/illinois-wellness-data/data/csv/claims.csv)

---

## 🧠 Objectives

This script conducts statistical analyses to evaluate:
- Baseline comparability across treatment and control groups before randomization
- Post-treatment effects of assignment to treatment
- Participation effects among those who opted into the program

---

## 📌 Questions Answered

### 🔹 **Q3.1.4 – Baseline Balance**
For outcomes measured **before randomization**, the script:
- Estimates mean values for treatment and control groups
- Calculates the p-value for differences using linear regression
- Outputs a 4-column summary:  
  `Variable | Control Mean | Treatment Mean | P-Value`

### 🔹 **Q3.1.5 – Treatment Effects (Intent-to-Treat)**
For **post-randomization outcomes**, the script:
- Estimates the effect of treatment assignment on outcomes
- Computes results:
  - **Without demographic controls**
  - **With demographic controls** (sex, race, age group)
- Outputs a 5-column summary including standard errors

### 🔹 **Q3.1.6 – Participation Effects**
For the same post-randomization outcomes, the script:
- Estimates differences between **participants vs. non-participants**
- Again reports effects with and without controls
- Notes potential for **selection bias** since participation was voluntary

---

## 🧮 Methodology

- Linear regression (`lm()`) is used throughout for comparisons
- `broom::tidy()` is applied to extract coefficients and p-values
- Demographic controls include:
  - `male`
  - `age37_49`, `age50` (age bins)
  - `white` (race binary)
- Results are rounded and compiled into structured data frames for clarity

---

## 📦 R Packages Used

- `tidyverse`: For data manipulation and modeling
- `broom`: To cleanly extract model output
- `dplyr`: Efficient data wrangling

---

## 📤 Outputs

Each question produces a summary table viewable in R’s console:
- `output_df_q4`: Baseline balance (Q3.1.4)
- `output_df_q5`: Treatment effect estimates (Q3.1.5)
- `output_df_q6`: Participation effect estimates (Q3.1.6)

---

## 📝 Notes

- Random assignment in Q5 supports **causal interpretation**.
- Voluntary participation in Q6 may lead to **confounding**, even after adjusting for demographics.
- The script avoids hardcoding variables and uses `lapply()` for modularity and scalability.

---

## ✍️ Author
**Aishwary Joshi**  
MSBA | Gies College of Business  
University of Illinois at Urbana-Champaign  
