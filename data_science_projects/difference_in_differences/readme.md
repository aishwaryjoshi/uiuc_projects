# 🚗 Minimum Legal Drinking Age & Mortality: Regression Discontinuity Analysis in R

This project investigates the causal impact of reaching the **Minimum Legal Drinking Age (MLDA)** on mortality rates using mortality and population data. The analysis focuses on a **non-parametric** and **parametric "donut" regression discontinuity (RD)** approach near the MLDA cutoff, using monthly age bins.

---

## 📁 Data Source

- Dataset: `all.dta` from [Julian Reif's Driving Study GitHub Repo](https://github.com/reifjulian/driving)
- Format: Stata `.dta`
- Link: `https://github.com/reifjulian/driving/raw/main/data/mortality/derived/all.dta`

---

## 📊 Analysis Summary

### 1. Mortality Rate Calculation
- Mortality rates computed as deaths per 100,000 person-years.
- Comparison between individuals:
  - **1–24 months above MLDA**
  - **1–24 months below MLDA**

### 2. Visual Exploration
- **Scatter plot** of mortality due to:
  - Any cause (black squares)
  - Motor vehicle accidents (blue circles)
- **Vertical red line** at MLDA cutoff (age in months = 0)

### 3. Non-Parametric “Donut” RD
- Compares mortality right before and after MLDA.
- Excludes data at the MLDA (age = 0) to avoid contamination.
- RD estimates reported for bandwidths: **48, 24, 12, 6 months**

### 4. Parametric “Donut” RD
- Adds linear trends on both sides of the MLDA cutoff.
- Regression includes interaction between trend and treatment indicator.
- RD estimates computed for same bandwidths: **48, 24, 12, 6 months**

---

## 📦 Output Files
- `donut_rd_results.csv`: RD estimates (non-parametric) for all bandwidths
- `parametric_donut_rd_results.csv`: RD estimates (parametric) for all bandwidths

---

## 📚 R Packages Used
- `haven`: Read Stata files
- `httr`: Download file from GitHub
- `dplyr`: Data manipulation
- `ggplot2`: Plotting
- `broom`: Tidy model outputs

---

## 🧠 Key Insight
This design provides a robust estimate of the causal effect of legally reaching the drinking age on short-term mortality risks — especially highlighting risks from **motor vehicle accidents**.

---

## ✍️ Author
Aishwary Joshi  
MSBA | University of Illinois Urbana-Champaign  
Course: Big Data for Finance  
