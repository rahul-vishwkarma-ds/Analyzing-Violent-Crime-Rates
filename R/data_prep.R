library(dplyr)
library(caret)
library(randomForest)

#' Get the fully processed US Crime dataset
#' 
#' This function checks if the processed CSV exists. If it does, it loads it.
#' If not, it processes the raw data, performs feature selection, and saves it.
get_us_data <- function(keep_zeros = FALSE) {
  processed_path <- "data/processed_data/cleaned_us_crime_data.csv"
  features_path <- "data/processed_data/features_list.rds"
  
  if (file.exists(processed_path) && file.exists(features_path)) {
    message("Loading cached US Crime data...")
    data.x <- read.csv(processed_path)
    features <- readRDS(features_path)
    attr(data.x, "five_features") <- features$five
    attr(data.x, "ten_features") <- features$ten
    return(data.x)
  }
  
  message("Processing raw US Crime data from scratch...")
  
  # 1. Read attribute names
  attribute_names <- readLines("data/raw_data/communities.names")
  attribute_names <- gsub("@attribute ", "", attribute_names[grepl("@attribute", attribute_names)])
  attribute_names <- sapply(strsplit(attribute_names, " "), FUN = `[`, 1)
  
  # 2. Read dataset
  data <- read.csv("data/raw_data/communities.data", header = FALSE, 
                   na.strings = "?", col.names = attribute_names)
  
  # 3. Clean NAs and drop non-numeric covariates
  data <- data[ , colSums(is.na(data)) == 0]
  
  unique_states <- sort(unique(data$state)) # 46
  new_state_ids <- setNames(seq_along(unique_states), unique_states) 
  data$statenew <- new_state_ids[as.character(data$state)]
  
  data.x <- data # Backup with state, communityname, and statenew intact
  
  # keep only the ones that exist
  cols_to_drop <- c("state", "communityname", "fold", "statenew")
  drop_idx <- which(names(data) %in% cols_to_drop)
  if (length(drop_idx) > 0) {
    data <- data[ , -drop_idx]
  }
  
  # 4. Feature Selection using ROC importance
  roc_imp <- filterVarImp(x = data[, !names(data) %in% c("ViolentCrimesPerPop")], 
                          y = data$ViolentCrimesPerPop)
  roc_imp <- data.frame(variable = rownames(roc_imp), score = as.double(roc_imp[,1]))
  
  ten_features <- roc_imp[order(roc_imp$score, decreasing = TRUE), ][1:10,]$variable
  five_features <- roc_imp[order(roc_imp$score, decreasing = TRUE), ][1:5,]$variable
  
  # 5. Beta transformation bounds
  if (!keep_zeros) {
    data.x$ViolentCrimesPerPop <- pmin(pmax(data.x$ViolentCrimesPerPop, 1e-6), 1 - 1e-6)
  }
  
  # Add the selected features as an attribute so other scripts can access them
  attr(data.x, "five_features") <- five_features
  attr(data.x, "ten_features") <- ten_features
  
  # Save the full data.x dataset and the features list
  write.csv(data.x, processed_path, row.names = FALSE)
  saveRDS(list(five = five_features, ten = ten_features), features_path)
  
  return(data.x)
}

#' Get the fully processed California Spatial dataset
#' 
#' Depends on get_us_data(). Merges with California lat/lon data and scales coordinates.
get_california_data <- function() {
  processed_path <- "data/processed_data/cleaned_california_spatial_data.csv"
  
  if (file.exists(processed_path)) {
    message("Loading cached California Spatial data...")
    data_cali <- read.csv(processed_path)
    
    # We must ensure five_features and ten_features are still available 
    # since we bypassed get_us_data() execution. Let's just grab them from US data.
    us_data <- get_us_data() 
    attr(data_cali, "five_features") <- attr(us_data, "five_features")
    attr(data_cali, "ten_features") <- attr(us_data, "ten_features")
    return(data_cali)
  }
  
  message("Processing raw California Spatial data from scratch...")
  
  # 1. Get base data
  data.x <- get_us_data()
  ten_features <- attr(data.x, "ten_features")
  
  # 2. Load Community Codes
  comm_code <- read.delim("data/raw_data/communitycodes.txt")
  comm_code$state <- rep(6, 278)
  
  data.x$communityname <- gsub("city|town|-MorongoValle", "", data.x$communityname)
  data.x$communityname[data.x$communityname == "GroverCity"] <- "GroverBeach"
  data.x$communityname[data.x$communityname == "SouthSanFranciscodivision"] <- "SouthSanFrancisco"
  data.x$communityname[data.x$communityname == "LaCanadaFlintridge"] <- "LaCañadaFlintridge"
  
  # 3. Load California Lat/Lon
  cal_cities <- read.csv("data/raw_data/cal_cities_lat_long.csv")
  cal_cities$Name <- gsub("\\s+", "", cal_cities$Name)
  names(cal_cities)[1] <- "communityname"
  
  comm_code$communityname[51] <- "LaCañadaFlintridge"
  comm_code$communityname[59] <- "SouthSanFrancisco"
  comm_code$communityname[105] <- "GroverBeach"
  
  merged_cali <- comm_code %>%
    left_join(cal_cities, by = c("communityname"), suffix = c("", "_ref"))
  
  missing_idx <- which(is.na(merged_cali$Longitude))
  merged_cali[missing_idx,7] <- c(37.822578, 39.752079, 37.221340, 37.565159, 34.523930, 38.053928)
  merged_cali[missing_idx,8] <- c(-122.000839, -121.621971, -121.979637, -122.363487, -117.216927, -122.155571)
  
  # 4. Merge with main dataset
  data_cali <- data.x %>%
    filter(state == 6) %>%
    select(all_of(c(ten_features, "state", "communityname", "ViolentCrimesPerPop"))) %>%
    right_join(merged_cali, by = c("communityname", "state"))
  
  # 5. Scale coordinates to [0,1]
  data_cali <- data_cali %>%
    mutate(
      Latitude_scaled = (Latitude - min(Latitude)) / (max(Latitude) - min(Latitude)),
      Longitude_scaled = (Longitude - min(Longitude)) / (max(Longitude) - min(Longitude))
    )
  
  attr(data_cali, "five_features") <- attr(data.x, "five_features")
  attr(data_cali, "ten_features") <- ten_features
  
  write.csv(data_cali, processed_path, row.names = FALSE)
  
  return(data_cali)
}

