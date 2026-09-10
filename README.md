# Analyzing Violent Crime Rates in U.S. Communities

**Applied Bayesian Data Analysis Project**

This repository contains the code and report for our group project on modeling violent crime rates using Hierarchical and Spatial Bayesian Regression. The study explores the benefits of incorporating hierarchy and spatial dependencies into regression models to address complex data structures.

## 📌 Project Overview

Traditional regression models often fail to capture key patterns when observations are influenced by group membership or spatial dependencies. In this project, we compared the predictive performance of several Bayesian models using a dataset of U.S. communities.

We evaluated five different Bayesian models using the `brms` package powered by Stan: 1. **Pooled Model (Beta Regression)** 2. **Zero-One Inflated Beta Model** (To handle boundary limits of pre-normalized data) 3. **Hierarchical Model** (To account for state-level variations across the US) 4. **Cubic Splines Model** (Spatial analysis restricted to California) 5. **Gaussian Process Model** (Advanced spatial analysis restricted to California)

## 📊 Dataset

The dataset combines socioeconomic data from the 1990 US Census, law enforcement data from the 1990 US LEMAS survey, and crime data from the 1995 FBI UCR. - **Target Variable:** Per Capita Violent Crimes (Normalized between `0` and `1`). - **Predictors Used:** `PctKids2Par`, `PctIlleg`, `PctFam2Par`, `racePctWhite`, `PctYoungKids2Par`. - **Spatial Data:** Longitude and Latitude (used for California-specific models).

## 🎯 Key Findings

- **Hierarchical Modeling:** Accounting for state-level variation significantly improved predictive performance (ELPD) over the simple pooled model.
- **Spatial Dependencies:** For the California subset, the Gaussian Process model demonstrated superior performance over the Cubic Splines model.
- **Zero-One Inflation:** Explicitly modeling the boundary values (`0` and `1`) improved the model fit but came with extreme computational costs.
- **Limitations:** All models exhibited a persistent residual pattern—overestimating low crime rates and underestimating high crime rates—suggesting that the pre-normalization of the dataset severely limits interpretability.

## 📂 Repository Structure

``` text
.
├── Analyzing-Violent-Crime-Rates.Rproj   # RStudio Project File
├── README.md                             # Project documentation
├── data/                                 # Data directory
│   ├── raw_data/                         # Original raw datasets (read-only)
│   ├── processed_data/                   # Cleaned/processed datasets (cached here)
│   └── metadata/                         # Data documentation
├── R/                                    # Reusable logic modules
│   ├── data_prep.R                       # Data cleaning and caching pipeline
│   ├── maps.R                            # Spatial mapping utilities
│   └── models/                           # Standardized Bayesian model scripts
│       ├── cs_model.R                    # Cubic Splines
│       ├── gp_model.R                    # Gaussian Process
│       ├── hierarchical_model.R          # Hierarchical
│       ├── pooled_model_5.R              # Pooled
│       ├── zero-one-inflated.R           # Zero-One Inflated
│       └── compare_models.R              # Generates LOO/PMP comparison metrics
├── scripts/                              # Top-level execution scripts
│   └── run_analysis.R                    # Main script to run models and cache data
├── manuscript/                           # LaTeX source code and static report images
└── output/                               # Generated results (git-ignored)
    ├── figures/                          # Trace plots, residual plots, PPCs
    └── models/                           # Saved .rds model checkpoints and summaries
```

## 🚀 How to Run

1.  **Install Dependencies:** Make sure you have `brms`, `rstan`, `caret`, and `randomForest` installed.
2.  **Run the Project:** You can execute all data caching, preprocessing, and Bayesian models from a single central script by running `source("scripts/run_analysis.R")`. This script intelligently caches your dataset to `data/processed_data/` so that subsequent model runs load instantly.
3.  **Compare Models:** After the models have successfully completed and saved their `.rds` checkpoints, run `source("R/models/compare_models.R")` to calculate LOO cross-validation and compute posterior model weights.

## 🛠️ Technologies & Libraries

- **Language:** R
- **Bayesian Framework:** `brms`, `Stan`, `loo`
- **Other Key Packages:** `dplyr`, `ggplot2`, `caret`

## 👨‍💻 Authors

**Group 31** - Lennart Koppe - Rahul Vishwkarma - Samuel Trippler

*TU Dortmund University - March 2025*
