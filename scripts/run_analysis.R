# ==============================================================================
# Analyzing Violent Crime Rates - Main Execution Script
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Generate / Load Data Cache
# ------------------------------------------------------------------------------
# This will safely cache the cleaned CSV datasets in data/processed_data/
# If the CSVs already exist, it will instantly load them instead.
source("R/data_prep.R")
message("Generating/Loading US Crime Data...")
us_data <- get_us_data()
message("Generating/Loading California Spatial Data...")
cali_data <- get_california_data()


# ------------------------------------------------------------------------------
# 2. Run Bayesian Models
# ------------------------------------------------------------------------------
# WARNING: These models (brms) are computationally expensive and can 
# take several hours to run. Uncomment the models below to run them individually.

# --- U.S. State Models ---
# source("R/models/pooled_model_5.R")
# source("R/models/pooled_model_10.R")
# source("R/models/hierarchical_model.R")
# source("R/models/zero-one-inflated.R")

# --- California Spatial Models ---
source("R/models/gp_model.R")
source("R/models/cs_model.R")

# ------------------------------------------------------------------------------
# 3. Compare Models
# ------------------------------------------------------------------------------
# Note: You must run the models above FIRST before comparing them.
# source("R/models/compare_models.R")

message("\nExecution script configured. Please uncomment the models you wish to run.")
