# 🏠 Property Sale Price Prediction using Machine Learning (R)

This project focuses on predicting the sale prices of properties using historical data and a machine learning model trained in R. The workflow includes EDA, data cleaning, feature selection, encoding, scaling, model training, and final prediction on unseen data.

---

## 📁 Files Used
- `historic_property_data.csv`: Training dataset containing past property sales and features.
- `predict_property_data.csv`: Dataset containing properties for which we need to predict sale prices.

---

## 🧠 Workflow Overview

### 1. ⏱️ Script Execution Time Logging
The script starts by capturing the start time and prints timestamps at the beginning and end.

### 2. 📊 Exploratory Data Analysis (EDA)
- Checks the number of rows and columns in both datasets.
- Identifies missing values and visualizes their distribution.
- Generates summary statistics for `sale_price`.
- Plots a histogram and boxplot for price distribution.

### 3. 🧹 Data Preprocessing
- Removes columns with excessive missing data and redundant identifiers.
- Imputes:
  - **Numerical features** with median.
  - **Categorical features** with mode.

### 4. 🔁 Multicollinearity and Feature Selection
- Uses `caret` to remove highly correlated variables (above 0.7).
- Removes numerical features that have very low correlation (|correlation| < 0.1) with `sale_price`.

### 5. 🧾 Categorical Encoding
- All categorical variables are label-encoded using `as.factor()` and converted to numeric.

### 6. 🔍 Train-Validation Split
- Data is split 80-20 into training and validation sets.
- Log transformation is applied to `sale_price` for normalization.
- Features are scaled using `scale()` function.

### 7. 🤖 Model Training
- Two models are trained and evaluated:
  - **Linear Regression**
  - **Random Forest** (with 5 trees)
- Evaluation metrics:
  - **MSE (Mean Squared Error)**
  - **R-squared**

### 8. 📈 Model Evaluation
- Both models are evaluated on the validation dataset.
- R² and MSE values are compared.

### 9. 🧪 Final Predictions on Unseen Data
- Applies the same preprocessing steps to `predict_property_data`.
- Predicts sale prices using the trained Random Forest model.
- Reverses log and scaling transformations to return values in the original scale.
- Outputs results into a CSV file `predict_data_with_predictions.csv` with `pid` and `final_sale_price`.

---

## 📦 Output
A CSV file containing:
- `pid`: A unique identifier for each property (autogenerated)
- `final_sale_price`: Predicted sale price, rounded to 2 decimal places

---

## 📚 Libraries Used
- `readr`
- `caret`
- `Metrics`
- `randomForest`

---

## 🕒 Runtime Logging
Logs the total time taken to execute the full script, helping in tracking performance.

---

## 🔧 How to Run
Just run the full R script in RStudio or any R-compatible environment.

---

## ✍️ Author
Aishwary Joshi  
MSBA | University of Illinois Urbana-Champaign  
Big Data for Finance - FIN 550  
