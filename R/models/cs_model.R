library(brms)
library(ggplot2)
library(tidyr)
library(dplyr)
library(bayesplot)

# ------------------------------------------------------------------------------
# Setup: Create Folders If Not Exist
# ------------------------------------------------------------------------------
dir.create("output/models", recursive = TRUE, showWarnings = FALSE)
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# Setup: Create Folders If Not Exist
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Load Data
# ------------------------------------------------------------------------------
source("R/data_prep.R")
data <- get_california_data()
five_features <- attr(data, "five_features")
ten_features <- attr(data, "ten_features")

spatial.features <- c(five_features, "Longitude_scaled", 
                      "Latitude_scaled", "ViolentCrimesPerPop")

data <- data %>% select(all_of(c(spatial.features)))
names(data)
dim(data)

# ------------------------------------------------------------------------------
# Formula & Priors for Gaussian Process Model
# ------------------------------------------------------------------------------
knots_list <- list(
  lon_knots = quantile(data$Longitude_scaled, probs = c(0.25, 0.5, 0.75)), 
  lat_knots  = quantile(data$Latitude_scaled,  probs = c(0.25, 0.5, 0.75))
)

formula.base <- as.formula(ViolentCrimesPerPop ~ s(Latitude_scaled, bs = "cs") + 
                             s(Longitude_scaled, bs = "cs"))

formula.cs <- update(formula.base, paste(". ~ . +", paste(five_features, collapse = " + ")))

# for 5 and 10 features
priors.cs <- c(
  prior(normal(0, 1), class = "b"),             # Regular slope priors for covariates
  prior(normal(-1, 0.1), class = "Intercept"),     # Intercept prior
  prior(exponential(500), class = "sds"),         # Smoothness of splines
  prior(gamma(4, 0.5), class = "phi")           # Precision parameter for Beta regression
)

# ------------------------------------------------------------------------------
# Prior Predictive Check
# ------------------------------------------------------------------------------
fit_prior_cs <- brm(
  formula = formula.cs,
  data = data,
  prior = priors.cs,
  family = "beta", 
  knots = knots_list,
  sample_prior = "only",  
  chains = 4, 
  cores = 4,
  iter = 4000
)


set.seed(42)
ppc_plot_cs <- pp_check(fit_prior_cs, ndraws = 200) +
  theme_bw(base_size = 22) +
  labs(x = "Normalized Violent Crimes per Capita")

ggsave(plot = ppc_plot_cs, filename = "output/figures/cs_ppc.png")
saveRDS(ppc_plot_cs, file = "output/models/cs_ppc.rds")

# ------------------------------------------------------------------------------
# Model Fitting
# ------------------------------------------------------------------------------
fit_cs <- brm(
  formula = formula.cs,
  data = data,
  prior = priors.cs,
  family = "beta", 
  knots = knots_list,
  chains = 4, 
  cores = 4,
  iter = 4000,
  seed = 42
)

# Save Model
saveRDS(fit_cs, file = "output/models/cs_model.rds")

# ------------------------------------------------------------------------------
# Results Summary
# ------------------------------------------------------------------------------
sink("output/models/cs_summary.txt")  
print(summary(fit_cs))      
sink()                         

# ------------------------------------------------------------------------------
# Trace Plots
# ------------------------------------------------------------------------------
trace_plots_cs <- plot(
  fit_cs,
  ask = FALSE
)

for (i in seq_along(trace_plots_cs)) {
  ggsave(
    filename = paste0("output/figures/cs_trace_plot_", i, ".png"),
    plot = trace_plots_cs[[i]]
  )
  
  saveRDS(
    object = trace_plots_cs[[i]], 
    file = paste0("output/models/cs_trace_plot_", i, ".rds")
  )
}

# ------------------------------------------------------------------------------
# Posterior Density Plot
# ------------------------------------------------------------------------------
set.seed(42)
cs_pd <- pp_check(fit_cs, ndraws = 100) +
  theme_bw(base_size = 22) 
ggsave(plot = cs_pd, filename = "output/figures/cs_pd.png")
saveRDS(cs_pd, file = "output/models/cs_pd.rds")

  
# ------------------------------------------------------------------------------
# Residual Plot
# ------------------------------------------------------------------------------
y_pred_cs <- posterior_predict(fit_cs)
y_pred_mean_cs <- colMeans(y_pred_cs)
y_obs_cs <- fit_cs$data$ViolentCrimesPerPop
residuals_cs <- y_obs_cs - y_pred_mean_cs
data_plot_cs <- data.frame(y_obs = y_obs_cs, residuals = residuals_cs)

cs_residual_plot <- ggplot(data_plot_cs, aes(x = y_obs, y = residuals)) +
  geom_point(alpha = 0.5, col = "blue") +
  geom_hline(yintercept = 0, color = "red", lwd = 1) +
  labs(
    x = "Normalized Violent Crimes per Capita",
    y = "Residuals"
  ) +
  theme_bw(base_size = 22)  

ggsave(plot = cs_residual_plot, filename = "output/figures/cs_residual.png")
saveRDS(cs_residual_plot, file = "output/models/cs_residual.rds")

