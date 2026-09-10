# Violent Crime Rates Dataset

## Source
Raw dataset: `data/raw_data/communities.data` & `communities.names` (UCI Machine Learning Repository: Communities and Crime Dataset)

## Description
This dataset combines socio-economic data from the 1990 US Census, law enforcement data from the 1990 US LEMAS survey, and crime data from the 1995 FBI UCR. It is used to predict the total number of violent crimes per 100K population.

## Key Variables Used
- **ViolentCrimesPerPop**: The total number of violent crimes per 100K pop (Target Variable, normalized to [0,1]).
- **Socio-Economic Predictors**: Includes metrics like `PctKids2Par`, `PctImmigRec10`, `PctPopUnderPov`, `medFamInc`, and `racePctWhite`.
- **Spatial Predictors**: Longitude and Latitude (used specifically for the California sub-models).

## Data Processing
The dataset undergoes heavy pre-processing in the `R/` directory before being fed into Bayesian models (`brms`). 
1. `data_prep_base.R`: Cleans and normalizes the target variable, removing NaNs.
2. `feature_selections.R`: Extracts the most important 5 and 10 features based on ROC correlation.
3. `spatial_prep.R` & `california_spatial_prep.R`: Joins community codes and normalizes Lat/Lon specifically for the spatial Gaussian Process models.
