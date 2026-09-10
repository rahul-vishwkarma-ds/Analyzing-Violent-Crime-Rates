
# ============== Pooled model with 10 features ==================================
library(brms)
library(ggplot2)
library(bayesplot)

# ------------------------------------------------------------------------------
# Setup: Create Folders If Not Exist
# ------------------------------------------------------------------------------
dir.create("output/models", recursive = TRUE, showWarnings = FALSE)
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# Load Data
# ------------------------------------------------------------------------------
source("R/data_prep.R")
data.x <- get_us_data()
data <- data.x
five_features <- attr(data.x, "five_features")
ten_features <- attr(data.x, "ten_features")

# ------------------------------------------------------------------------------
# Setup: Create Folders If Not Exist
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Formula & Priors for Pooled Model
# ------------------------------------------------------------------------------
formula.pool10 <- as.formula(paste("ViolentCrimesPerPop ~", 
                                   paste(ten_features, collapse = " + ")))

prior.pool10 <- 
  prior(normal(-1.4, 0.1), class = "Intercept") +
  prior(normal(0, 4), class = "b") + 
  prior(gamma(2, 0.1), class = "phi")

# ------------------------------------------------------------------------------
# Prior Predictive Check
# ------------------------------------------------------------------------------
fit_prior10 <- brm(
  formula = formula.pool10,
  data = data, 
  prior = prior.pool10,
  family = "beta",
  sample_prior = "only",  
  chains = 4,
  seed = 42,
  cores = 4,
  iter = 4000
)

set.seed(42)
ppc_plot10 <- pp_check(fit_prior10, ndraws = 30) +
  theme_bw(base_size = 22) +
  labs(x = "Normalized Violent Crimes per Capita")

ggsave(plot = ppc_plot10, filename = "output/figures/pooled_ppc10.png")
saveRDS(ppc_plot10, file = "output/models/pooled_ppc10.rds")

# ------------------------------------------------------------------------------
# Model Fitting
# ------------------------------------------------------------------------------
fit_pool10 <- brm(
  formula = formula.pool10, 
  data = data,
  prior = prior.pool10, 
  family = "beta",
  chains = 4,
  seed = 42,
  cores = 4,
  iter = 4000
)

# Save Model
saveRDS(fit_pool10, file = "output/models/pooled_model10.rds") 

# ------------------------------------------------------------------------------
# Results Summary
# ------------------------------------------------------------------------------
sink("output/models/pooled_summary10.txt")  
print(summary(fit_pool10))      
sink()                         

# ------------------------------------------------------------------------------
# Trace Plots
# ------------------------------------------------------------------------------
trace_plots10 <- plot(
  fit_pool10,
  #pars = ten_features,
  ask = FALSE
)

for (i in seq_along(trace_plots10)) {
  ggsave(
    filename = paste0("output/figures/pooled_trace_plot10_", i, ".png"),
    plot = trace_plots10[[i]]
  )
  
  saveRDS(
    object = trace_plots10[[i]], 
    file = paste0("output/models/pooled_trace_plot10_", i, ".rds")
  )
}

# ------------------------------------------------------------------------------
# Posterior Density Plot
# ------------------------------------------------------------------------------
set.seed(42)


# ? ? ? ? ?  ?? ? ?  Problem with title fitting on the plot
pooled_pd10 <- pp_check(fit_pool10, ndraws = 30) +
  theme_bw(base_size = 22) +
  labs(x = "Normalized Violent Crimes per Capita")

ggsave(plot = pooled_pd10, filename = "output/figures/pooled_pd10.png")
saveRDS(pooled_pd10, file = "output/models/pooled_pd10.rds")

   



# ------------------------------------------------------------------------------
# Residual Plot
# ------------------------------------------------------------------------------
y_pred_brm10 <- posterior_predict(fit_pool10)
y_pred_mean10 <- colMeans(y_pred_brm10)
y_obs <- fit_pool10$data$ViolentCrimesPerPop
residuals_brm10 <- y_obs - y_pred_mean10
data_plot10 <- data.frame(y_obs = y_obs, residuals = residuals_brm10)

pooled_residual_plot_10 <- ggplot(data_plot10, aes(x = y_obs, y = residuals)) +
  geom_point(alpha = 0.5, col = "purple") +
  geom_hline(yintercept = 0, color = "red", lwd = 1) +
  labs(
    x = "Normalized Violent Crimes per Capita",
    y = "Residuals"
  ) +
  ggtitle("Pooled Model with 10 features") +
  theme_bw(base_size = 22)  

ggsave(plot = pooled_residual_plot_10, filename = "output/figures/pooled_residual10.png")
saveRDS(pooled_residual_plot_10, file = "output/models/pooled_residual10.rds")
