
# Us-state
pooled_model5 <- readRDS("output/models/pooled_model5.rds")
pooled_model10 <- readRDS("output/models/pooled_model10.rds")
zoi_model_5 <- readRDS("output/models/zoi_model_5.rds")
hierarchical_model <- readRDS("output/models/hierarchical_model.rds")

# California
cs_model <- readRDS("output/models/cs_model.rds")
gp_model <- readRDS("output/models/gp_model.rds")


library(loo)

dir.create("output/models", 
           recursive = TRUE, showWarnings = FALSE)

# LOO
loo.pool5 <- loo(pooled_model5)
saveRDS(loo.pool5, file = "output/models/loo.pool5.rds")

loo.pool10 <- loo(pooled_model10)
saveRDS(loo.pool10, file = "output/models/loo.pool10.rds")

loo.poolzoi5 <- loo(zoi_model_5)
saveRDS(loo.poolzoi5, file = "output/models/loo.poolzoi5.rds")

loo.hier5 <- loo(hierarchical_model)
saveRDS(loo.hier5, file = "output/models/loo.hier5.rds")


loo.cs <- loo(cs_model)
saveRDS(loo.cs, file = "output/models/loo.cs.rds")

loo.gp <- loo(gp_model)
saveRDS(loo.gp, file = "output/models/loo.gp.rds")

# Compare models
sink("output/models/loo.comp.us.state.txt")
(loo.comp.us.state <- loo_compare(loo.pool5, loo.pool10, loo.poolzoi5, loo.hier5))
sink("output/models/loo.comp.cali.txt")
(loo.comp.cali <- loo_compare(loo.cs, loo.gp))

# # excluding zoi5
# sink("output/models/pmp.state.txt")
# (pmp.state <- loo_model_weights(list(loo.pool5, loo.pool10, loo.hier5 
#                                      #, loo.poolzoi5
#                                      ), 
#                                 method = "stacking"))

sink("output/models/pmp.pool5v10.txt")
(pmp.pool5v10 <- loo_model_weights(list(loo.pool5, loo.pool10), 
                                method = "stacking"))

sink("output/models/pmp.pool5vhier.txt")
(pmp.pool5v10 <- loo_model_weights(list(loo.pool5, loo.hier5), 
                                   method = "stacking"))

sink("output/models/pmp.cali.txt")
(pmp.cali <-loo_model_weights(list(loo.cs, loo.gp), 
                              method = "stacking"))

sink()







