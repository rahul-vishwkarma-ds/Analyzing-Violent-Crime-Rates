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

# Prepare data for the model
spatial.features <- c(five_features, "Longitude_scaled", 
                      "Latitude_scaled", "ViolentCrimesPerPop")

data <- data %>% select(all_of(c(spatial.features)))
names(data)
dim(data)

# ------------------------------------------------------------------------------
# Formula & Priors for Gaussian Process Model
# ------------------------------------------------------------------------------
formula.base2 <- as.formula(ViolentCrimesPerPop ~ gp(Latitude_scaled, Longitude_scaled))

formula.gp <- update(formula.base2, paste(". ~ . +", paste(five_features, collapse = " + ")))

priors.gp <- c(
  prior(normal(-1.0, 0.1), class = "Intercept"),  
  prior(normal(0, 2), class = "b"),              
  prior(gamma(2, 0.4), class = "phi"),           
  prior(exponential(8), class = "sdgp"),         
  prior(exponential(2), class = "lscale")
)


# ------------------------------------------------------------------------------
# Prior Predictive Check
# ------------------------------------------------------------------------------
fit_prior_gp <- brm(
  formula = formula.gp,
  data = data, 
  prior = priors.gp,
  family = "beta",
  sample_prior = "only",  
  chains = 4, 
  cores = 4,
  iter = 4000
)

ppc_plot_gp <- pp_check(fit_prior_gp, ndraws = 200) +
  theme_bw(base_size = 22) +
  labs(x = "Normalized Violent Crimes per Capita")

ggsave(plot = ppc_plot_gp, filename = "output/figures/gp_ppc.png")
saveRDS(ppc_plot_gp, file = "output/models/gp_ppc.rds")

# ------------------------------------------------------------------------------
# Model Fitting
# ------------------------------------------------------------------------------
fit_gp <- brm(
  formula = formula.gp,
  data = data,
  prior = priors.gp,
  family = "beta",
  chains = 4, 
  cores = 4,
  iter = 4000,
  seed = 42
)

# Save Model
saveRDS(fit_gp, file = "output/models/gp_model.rds")

# ------------------------------------------------------------------------------
# Results Summary
# ------------------------------------------------------------------------------
sink("output/models/gp_summary.txt")  
print(summary(fit_gp))      
sink()                         

# ------------------------------------------------------------------------------
# Trace Plots
# ------------------------------------------------------------------------------
trace_plots_gp <- plot(
  fit_gp,
  pars = c("b_PctKids2Par", "b_PctImmigRec10", "b_PctPopUnderPov", "b_medFamInc", "b_racePctWhite", "Intercept"),
  ask = FALSE
)

for (i in seq_along(trace_plots_gp)) {
  ggsave(
    filename = paste0("output/figures/gp_trace_plot_", i, ".png"),
    plot = trace_plots_gp[[i]]
  )
  
  saveRDS(
    object = trace_plots_gp[[i]], 
    file = paste0("output/models/gp_trace_plot_", i, ".rds")
  )
}

# ------------------------------------------------------------------------------
# Posterior Density Plot
# ------------------------------------------------------------------------------
gp_pd <- pp_check(fit_gp, ndraws = 100) +
  theme_bw(base_size = 22) 
ggsave(plot = gp_pd, filename = "output/figures/gp_pd.png")
saveRDS(gp_pd, file = "output/models/gp_pd.rds")

  

# ------------------------------------------------------------------------------
# Residual Plot
# ------------------------------------------------------------------------------
y_pred_gp <- posterior_predict(fit_gp)
y_pred_mean_gp <- colMeans(y_pred_gp)
y_obs_gp <- fit_gp$data$y
residuals_gp <- y_obs_gp - y_pred_mean_gp
data_plot_gp <- data.frame(y_obs = y_obs_gp, residuals = residuals_gp)

gp_residual_plot <- ggplot(data_plot_gp, aes(x = y_obs, y = residuals)) +
  geom_point(alpha = 0.5, col = "blue") +
  geom_hline(yintercept = 0, color = "red", lwd = 1) +
  labs(
    x = "Normalized Violent Crimes per Capita",
    y = "Residuals"
  ) +
  theme_bw(base_size = 22)  

ggsave(plot = gp_residual_plot, filename = "output/figures/gp_residual.png")
saveRDS(gp_residual_plot, file = "output/models/gp_residual.rds")
