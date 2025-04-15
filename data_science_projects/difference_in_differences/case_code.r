# Install necessary packages if not already installed
if (!requireNamespace("haven", quietly = TRUE)) install.packages("haven")
if (!requireNamespace("httr", quietly = TRUE)) install.packages("httr")
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")

# Load libraries
library(haven)
library(httr)
library(dplyr)

# URL of the .dta file
url <- "https://github.com/reifjulian/driving/raw/main/data/mortality/derived/all.dta"  # Use raw file link

# Temporary file to save the .dta file
temp_file <- tempfile(fileext = ".dta")

# Download the .dta file
GET(url, write_disk(temp_file, overwrite = TRUE))

# Read the .dta file
data <- read_dta(temp_file)

# Display the first few rows
head(data)

# Question 1: Calculate mortality rates due to any cause for individuals in the sample 
# who are 1–24 months above the MLDA and for those who are 1–24 months below the MLDA.
# Does this difference between these two groups plausibly describe the causal effect of reaching the MLDA on mortality?


# Calculate mortality rates in units of deaths per 100,000 person-years
data <- data %>%
  mutate(mortality_rate_any = 100000 * cod_any / (pop / 12))

# View the resulting data
head(data[, c("agemo_mda", "pop", "cod_any", "mortality_rate_any")])

# Summary of calculated rates
summary(data$mortality_rate_any)

# Filter data for individuals 1-24 months above the MLDA
above_mlda <- data %>%
  filter(agemo_mda >= 1 & agemo_mda <= 24)

# Filter data for individuals 1-24 months below the MLDA
below_mlda <- data %>%
  filter(agemo_mda >= -24 & agemo_mda <= -1)

# Calculate average mortality rates for both groups
avg_mortality_above <- mean(above_mlda$mortality_rate_any, na.rm = TRUE)
avg_mortality_below <- mean(below_mlda$mortality_rate_any, na.rm = TRUE)

# Display results
cat("Average Mortality Rate (1–24 months above MLDA):", avg_mortality_above, "\n")
cat("Average Mortality Rate (1–24 months below MLDA):", avg_mortality_below, "\n")

# Calculate the difference between the two groups
difference <- avg_mortality_above - avg_mortality_below
cat("Difference in Mortality Rate:", difference, "\n")

# Question 2: Create a scatter plot showing mortality rates due to (a) any cause 
# and (b) motor vehicle accidents. Add a vertical line at MLDA.

# Install necessary packages if not already installed
if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")

# Load the ggplot2 library
library(ggplot2)

# Filter data for individuals within 2 years (±24 months) of the MLDA
plot_data <- data %>%
  filter(agemo_mda >= -24 & agemo_mda <= 24) %>%
  mutate(mortality_rate_mva = 100000 * cod_MVA / (pop / 12))  # Mortality rates for motor vehicle accidents

# Create the scatter plot
ggplot(plot_data, aes(x = agemo_mda)) +
  # Mortality rates due to any cause (black squares)
  geom_point(aes(y = mortality_rate_any), color = "black", shape = 15, size = 3, alpha = 0.8) +
  # Mortality rates due to motor vehicle accidents (blue circles)
  geom_point(aes(y = mortality_rate_mva), color = "blue", shape = 16, size = 3, alpha = 0.8) +
  # Add a vertical line at MLDA (0 months)
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 1) +
  # Add labels and title
  labs(
    x = "Age in Months Since MLDA",
    y = "Mortality Rate (per 100,000 person-years)",
    title = "Mortality Rates Due to Any Cause and Motor Vehicle Accidents"
  ) +
  # Improve plot appearance
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 10)
  )
# ggsave("mortality_rates_plot.png", width = 10, height = 6, dpi = 300)

# Question 3: Non-parametric “donut” RD. Calculate the RD estimated effect of driving 
# on mortality rates for different bandwidths and report the results.

# Install necessary packages if not already installed
if (!requireNamespace("haven", quietly = TRUE)) install.packages("haven")
if (!requireNamespace("httr", quietly = TRUE)) install.packages("httr")
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("broom", quietly = TRUE)) install.packages("broom")

# Load required libraries
library(haven)
library(httr)
library(dplyr)
library(broom)

# URL of the .dta file
url <- "https://github.com/reifjulian/driving/raw/main/data/mortality/derived/all.dta"

# Temporary file to save the .dta file
temp_file <- tempfile(fileext = ".dta")

# Download the .dta file
GET(url, write_disk(temp_file, overwrite = TRUE))

# Read the .dta file
data <- read_dta(temp_file)

# Add columns for mortality rates
data <- data %>%
  mutate(
    mortality_rate_any = 100000 * cod_any / (pop / 12),  # Mortality rate for any cause
    mortality_rate_mva = 100000 * cod_MVA / (pop / 12)  # Mortality rate for motor vehicle accidents
  )

# Function to calculate "donut" RD estimate for a given bandwidth
donut_rd <- function(data, bandwidth) {
  # Filter data within the bandwidth but exclude the partially treated observation (agemo_mda == 0)
  # Check rows where agemo_mda is not 0
  print("Data:")
  print(data)
  not_zero <- data %>% filter(agemo_mda != 0)
  print("Rows where agemo_mda is not 0:")
  print(not_zero)
  
  # Check rows within the bandwidth range
  within_bandwidth <- data %>% filter(agemo_mda >= -bandwidth & agemo_mda <= bandwidth)
  print("Rows within the bandwidth range:")
  print(within_bandwidth)
  
  # Combine both conditions
  donut_data <- data %>%
    filter(agemo_mda != 0 & agemo_mda >= -bandwidth & agemo_mda <= bandwidth)
  print("Filtered donut data:")
  print(donut_data)
  
  print("Donut data:")
  print(donut_data)
  # Debugging: Check data dimensions
  cat("Bandwidth:", bandwidth, 
      "| Rows in Filtered Data:", nrow(donut_data), 
      "| Missing mortality_rate_any:", sum(is.na(donut_data$mortality_rate_any)), 
      "| Missing mortality_rate_mva:", sum(is.na(donut_data$mortality_rate_mva)), "\n")
  
  # Ensure there are sufficient observations for meaningful regression
  if (nrow(donut_data) < 10) {
    cat("Insufficient observations for bandwidth:", bandwidth, "\n")
    return(data.frame(bandwidth = bandwidth, RD_any = NA, RD_mva = NA))
  }
  
  # Linear regression models
  model_any <- tryCatch(
    lm(mortality_rate_any ~ I(agemo_mda > 0), data = donut_data),
    error = function(e) NULL
  )
  model_mva <- tryCatch(
    lm(mortality_rate_mva ~ I(agemo_mda > 0), data = donut_data),
    error = function(e) NULL
  )
  print("Model Any:")
  print(model_any)
  
  print("Model MVA:")
  print(model_mva)
  
  estimate_any <- if (!is.null(model_any) && "I(agemo_mda > 0)TRUE" %in% names(coef(model_any))) {
    coef(model_any)["I(agemo_mda > 0)TRUE"]
  } else {
    NA
  }
  estimate_mva <- if (!is.null(model_mva) && "I(agemo_mda > 0)TRUE" %in% names(coef(model_mva))) {
    coef(model_mva)["I(agemo_mda > 0)TRUE"]
  } else {
    NA
  }
  
  
  # Return results as a data frame
  return(data.frame(bandwidth = bandwidth, RD_any = estimate_any, RD_mva = estimate_mva))
}

# Define bandwidths to analyze
bandwidths <- c(48, 24, 12, 6)

# Apply the "donut" RD function for each bandwidth
results <- bind_rows(lapply(bandwidths, function(bw) donut_rd(data, bw)))

# Display the results
print(results)

# Save the results as a CSV file
write.csv(results, "donut_rd_results.csv", row.names = FALSE)

# Question 4: Parametric “donut” RD. Calculate the parametric RD estimated effect of driving 
# on mortality rates for different bandwidths and report the results.


# Function to calculate parametric "donut" RD estimate for a given bandwidth
parametric_donut_rd <- function(data, bandwidth) {
  # Filter data within the bandwidth but exclude the partially treated observation (agemo_mda == 0)
  donut_data <- data %>%
    filter(agemo_mda != 0 & agemo_mda >= -bandwidth & agemo_mda <= bandwidth)
  
  # Ensure there are sufficient observations for meaningful regression
  if (nrow(donut_data) < 10) {
    cat("Insufficient observations for bandwidth:", bandwidth, "\n")
    return(data.frame(bandwidth = bandwidth, RD_any = NA, RD_mva = NA))
  }
  
  # Linear regression models with linear trends on either side of the cutoff
  model_any <- tryCatch(
    lm(mortality_rate_any ~ I(agemo_mda > 0) + agemo_mda + I(agemo_mda * (agemo_mda > 0)), data = donut_data),
    error = function(e) NULL
  )
  model_mva <- tryCatch(
    lm(mortality_rate_mva ~ I(agemo_mda > 0) + agemo_mda + I(agemo_mda * (agemo_mda > 0)), data = donut_data),
    error = function(e) NULL
  )
  
  # Extract RD estimates
  estimate_any <- if (!is.null(model_any) && "I(agemo_mda > 0)TRUE" %in% names(coef(model_any))) {
    coef(model_any)["I(agemo_mda > 0)TRUE"]
  } else {
    NA
  }
  
  estimate_mva <- if (!is.null(model_mva) && "I(agemo_mda > 0)TRUE" %in% names(coef(model_mva))) {
    coef(model_mva)["I(agemo_mda > 0)TRUE"]
  } else {
    NA
  }
  
  # Return results as a data frame
  return(data.frame(bandwidth = bandwidth, RD_any = estimate_any, RD_mva = estimate_mva))
}

# Define bandwidths to analyze
bandwidths <- c(48, 24, 12, 6)

# Apply the parametric "donut" RD function for each bandwidth
parametric_results <- bind_rows(lapply(bandwidths, function(bw) parametric_donut_rd(data, bw)))

# Display the results
print(parametric_results)

# Save the results as a CSV file
write.csv(parametric_results, "parametric_donut_rd_results.csv", row.names = FALSE)