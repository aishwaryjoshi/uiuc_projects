# BIG Data Problem Set 1
# Date: 2024-11-14
# Contributors: AISHWARY JOSHI

# Load necessary libraries
library(tidyverse)
library(dplyr)
library(broom)

# Read in the claims dataset from the public use data repository
claims_csv <- read_csv("https://reifjulian.github.io/illinois-wellness-data/data/csv/claims.csv")

# Uncomment below lines if you wish to inspect the dataset
head(claims_csv)
str(claims_csv)

# --------------------------------------------------------------------------------
# Question 3.1.4:
# For each outcome in the claims dataset, as measured pre-randomization (i.e., prior to August 2016),
# report the following in a four-column table (one row per outcome):
# (1) Variable description
# (2) Control group mean
# (3) Treatment group mean
# (4) P-value on the difference
# Use linear regression to calculate all these values.

# Variables for analysis (pre-randomization outcomes)
variables <- c(
  "covg_0715_0716", "diabetes_1015_0716", "hyperlipidemia_1015_0716",
  "hypertension_1015_0716", "nonzero_spend_0715_0716", "pcp_any_office_1015_0716",
  "pcp_any_visits_1015_0716", "pcp_total_office_1015_0716", "pcp_total_visits_1015_0716",
  "pos_er_critical_1015_0716", "pos_hospital_1015_0716", "pos_office_outpatient_1015_0716",
  "spendHosp_0715_0716", "spendOff_0715_0716", "spendRx_0715_0716", "spend_0715_0716"
)

# Function to fit linear model and extract results
cv_fun <- function(f) {
  
  # Fit linear model of the form: outcome ~ treat
  lm_result <- lm(as.formula(paste(f, "~ treat")), data = claims_csv)
  
  # Tidy the results for easy extraction
  tidy_result <- tidy(lm_result, conf.int = TRUE, conf.level = 0.95)
  
  return(tidy_result)
}

# Apply the function to each variable and store results
balance_sheet <- lapply(variables, cv_fun)

# Initialize a list to store the extracted data
data_list <- lapply(1:length(balance_sheet), function(i) {
  # Extract the summary for each variable
  lm_summary <- balance_sheet[[i]]
  
  # Control group mean (intercept)
  control_mean <- lm_summary$estimate[lm_summary$term == "(Intercept)"]
  
  # Treatment effect estimate (difference between treatment and control means)
  treat_effect <- lm_summary$estimate[lm_summary$term == "treat"]
  
  # Treatment group mean (control mean + treatment effect)
  treat_mean <- control_mean + treat_effect
  
  # P-value for the difference between treatment and control groups
  p_value <- lm_summary$p.value[lm_summary$term == "treat"]
  
  # Round the values for better readability
  control_mean <- round(control_mean, 3)
  treat_mean <- round(treat_mean, 3)
  p_value <- round(p_value, 3)
  
  # Combine the extracted data into a vector
  return(c(variable = variables[i], control_mean, treat_mean, p_value))
})

# Combine all the extracted data into a single data frame
output_df_q4 <- do.call(rbind, data_list)
output_df_q4 <- as.data.frame(output_df_q4)

# Assign appropriate column names
colnames(output_df_q4) <- c("Variable", "Control Group Mean", "Treatment Group Mean", "P-Value")

# Display the resulting data frame
print("Question 4 Results:")
print(output_df_q4)

# --------------------------------------------------------------------------------
# Question 3.1.5:
# For each outcome in the claims dataset, as measured in the first year following randomization,
# report the following in a three-column table (one row per outcome):
# (1) Variable description
# (2) Estimated difference between treatment and control groups (no demographic controls) with standard error
# (3) Estimated difference between treatment and control groups (with demographic controls) with standard error
# Demographic controls: sex (male/female), race (white/nonwhite), age groups (37-49, 50+)

# Variables for analysis (post-randomization outcomes)
variables2 <- c(
  "covg_0816_0717", "diabetes_0816_0717", "hyperlipidemia_0816_0717",
  "hypertension_0816_0717", "nonzero_spend_0816_0717", "pcp_any_office_0816_0717",
  "pcp_any_visits_0816_0717", "pcp_total_office_0816_0717", "pcp_total_visits_0816_0717",
  "pos_er_critical_0816_0717", "pos_hospital_0816_0717", "pos_office_outpatient_0816_0717",
  "spendHosp_0816_0717", "spendOff_0816_0717", "spendRx_0816_0717", "spend_0816_0717"
)

# Function to fit linear model without demographic controls
cv_fun2 <- function(f) {
  
  # Fit linear model: outcome ~ treat
  lm_result <- lm(as.formula(paste(f, "~ treat")), data = claims_csv)
  
  # Tidy the results
  tidy_result <- tidy(lm_result)
  
  return(tidy_result)
}

# Function to fit linear model with demographic controls
cv_fun3 <- function(f) {
  
  # Fit linear model: outcome ~ treat + demographics
  lm_result <- lm(as.formula(paste(f, "~ treat + male + age37_49 + age50 + white")), data = claims_csv)
  
  # Tidy the results
  tidy_result <- tidy(lm_result)
  
  return(tidy_result)
}

# Apply functions to each variable and store results
balance_sheet2 <- lapply(variables2, cv_fun2)
balance_sheet3 <- lapply(variables2, cv_fun3)

# Extract the estimated differences and standard errors
data_list2 <- lapply(1:length(balance_sheet2), function(i) {
  # Summary without controls
  lm_summary <- balance_sheet2[[i]]
  
  # Estimated difference (treat coefficient)
  treat_estimate <- lm_summary$estimate[lm_summary$term == "treat"]
  
  # Standard error
  treat_stderr <- lm_summary$std.error[lm_summary$term == "treat"]
  
  # Round the values
  treat_estimate <- round(treat_estimate, 4)
  treat_stderr <- round(treat_stderr, 4)
  
  # Combine into a vector
  return(c(variable = variables2[i], treat_estimate, treat_stderr))
})

data_list3 <- lapply(1:length(balance_sheet3), function(i) {
  # Summary with controls
  lm_summary <- balance_sheet3[[i]]
  
  # Estimated difference (treat coefficient)
  treat_estimate <- lm_summary$estimate[lm_summary$term == "treat"]
  
  # Standard error
  treat_stderr <- lm_summary$std.error[lm_summary$term == "treat"]
  
  # Round the values
  treat_estimate <- round(treat_estimate, 4)
  treat_stderr <- round(treat_stderr, 4)
  
  # Combine into a vector
  return(c(treat_estimate, treat_stderr))
})

# Combine the two lists element-wise
output_list_q5 <- Map(function(dl2, dl3) {
  c(dl2, dl3)
}, data_list2, data_list3)

# Convert the combined list to a data frame
output_df_q5 <- do.call(rbind, output_list_q5)
output_df_q5 <- as.data.frame(output_df_q5)

# Assign column names
colnames(output_df_q5) <- c(
  "Variable",
  "Estimated Difference (No Controls)",
  "Standard Error (No Controls)",
  "Estimated Difference (With Controls)",
  "Standard Error (With Controls)"
)

# Display the resulting data frame
print("Question 5 Results:")
print(output_df_q5)

# --------------------------------------------------------------------------------
# Question 3.1.6:
# For each outcome in the claims dataset, as measured in the first year following randomization,
# report the following in a three-column table (one row per outcome):
# (1) Variable description
# (2) Estimated difference between participants and non-participants (no demographic controls) with standard error
# (3) Estimated difference between participants and non-participants (with demographic controls) with standard error
# Demographic controls: sex (male/female), race (white/nonwhite), age groups (37-49, 50+)

# Variables for analysis (same as in Question 5)
variables3 <- variables2

# Function to fit linear model comparing participants and non-participants (no controls)
cv_fun4 <- function(f) {
  
  # Fit linear model: outcome ~ hra_c_yr1
  lm_result <- lm(as.formula(paste(f, "~ hra_c_yr1")), data = claims_csv)
  
  # Tidy the results
  tidy_result <- tidy(lm_result)
  
  return(tidy_result)
}

# Function to fit linear model comparing participants and non-participants (with controls)
cv_fun5 <- function(f) {
  
  # Fit linear model: outcome ~ hra_c_yr1 + demographics
  lm_result <- lm(as.formula(paste(f, "~ hra_c_yr1 + male + age37_49 + age50 + white")), data = claims_csv)
  
  # Tidy the results
  tidy_result <- tidy(lm_result)
  
  return(tidy_result)
}

# Apply functions to each variable and store results
balance_sheet4 <- lapply(variables3, cv_fun4)
balance_sheet5 <- lapply(variables3, cv_fun5)

# Extract the estimated differences and standard errors
data_list4 <- lapply(1:length(balance_sheet4), function(i) {
  # Summary without controls
  lm_summary <- balance_sheet4[[i]]
  
  # Estimated difference (hra_c_yr1 coefficient)
  participation_estimate <- lm_summary$estimate[lm_summary$term == "hra_c_yr1"]
  
  # Standard error
  participation_stderr <- lm_summary$std.error[lm_summary$term == "hra_c_yr1"]
  
  # Round the values
  participation_estimate <- round(participation_estimate, 4)
  participation_stderr <- round(participation_stderr, 4)
  
  # Combine into a vector
  return(c(variable = variables3[i], participation_estimate, participation_stderr))
})

data_list5 <- lapply(1:length(balance_sheet5), function(i) {
  # Summary with controls
  lm_summary <- balance_sheet5[[i]]
  
  # Estimated difference (hra_c_yr1 coefficient)
  participation_estimate <- lm_summary$estimate[lm_summary$term == "hra_c_yr1"]
  
  # Standard error
  participation_stderr <- lm_summary$std.error[lm_summary$term == "hra_c_yr1"]
  
  # Round the values
  participation_estimate <- round(participation_estimate, 4)
  participation_stderr <- round(participation_stderr, 4)
  
  # Combine into a vector
  return(c(participation_estimate, participation_stderr))
})

# Combine the two lists element-wise
output_list_q6 <- Map(function(dl4, dl5) {
  c(dl4, dl5)
}, data_list4, data_list5)

# Convert the combined list to a data frame
output_df_q6 <- do.call(rbind, output_list_q6)
output_df_q6 <- as.data.frame(output_df_q6)

# Assign column names
colnames(output_df_q6) <- c(
  "Variable",
  "Estimated Difference (No Controls)",
  "Standard Error (No Controls)",
  "Estimated Difference (With Controls)",
  "Standard Error (With Controls)"
)

# Display the resulting data frame
print("Question 6 Results:")
print(output_df_q6)

# --------------------------------------------------------------------------------

# Note:
# - The 'hra_c_yr1' variable indicates whether an individual participated in the wellness program during the first year.
# - In Question 6, we compare participants to non-participants, which may introduce selection bias because participation is voluntary.
# - Demographic controls may help adjust for observable differences, but unobserved factors may still affect the estimates.

# End of Script
