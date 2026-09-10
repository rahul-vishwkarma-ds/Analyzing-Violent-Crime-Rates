rm(list = ls())

# Load libraries
library(ggplot2)
library(dplyr)
library(maps)
library(mapdata)
library(ggrepel)

# Step 1: Load the dataset -----------------------------------------
source("R/data_upload.R")

# Step 2: Summarize number of communities per state
community_summary <- data.x %>%
  filter(!is.na(state)) %>% # filters non-NA data rows only
  group_by(state) %>%
  summarise(num_communities = n_distinct(communityname)) %>%
  ungroup()

# Step 3: Map state codes to state names ----------------------------
state_codes <- data.frame(
  state = lookup_table$original_fips,
  region = tolower(lookup_table$name)
)

# Merge state_codes with the community_summary
community_summary <- left_join(community_summary, state_codes, by = "state")

# Step 4: Calculate relative percentages -------------------------
total_communities <- sum(community_summary$num_communities, na.rm = TRUE)
community_summary <- community_summary %>%
  mutate(relative_percentage = round((num_communities / total_communities) * 100, 2))

# Step 5: Prepare state map data ------------------------------
state_map <- map_data("state") 
state_map <- left_join(state_map, community_summary, by = c("region" = "region"))

# Step 6: Calculate state centroids for labels -----------------------
state_centroids <- state_map %>%
  group_by(region) %>%
  summarise(long = mean(range(long)), lat = mean(range(lat)),
            label = paste0(region, "\n", relative_percentage, "%"),
            num_communities = first(num_communities)) %>%
  filter(!is.na(num_communities))

# Step 7: Plot the map with relative values and state names -------------
ggplot() +
  geom_polygon(data = state_map, 
               aes(x = long, y = lat, group = group, fill = relative_percentage), 
               color = "white") +
  geom_text(data = state_centroids, aes(x = long, y = lat, label = label),
            color = "black", size = 3, fontface = "bold", lineheight = 0.9) +
  scale_fill_gradient(low = "lightgreen", high = "darkgreen", 
                      na.value = "gray90", 
                      name = "Relative %") +
  theme_minimal() +
  labs(title = "Relative Number of Communities Represented in Each State",
       subtitle = "States filled based on the relative percentage of communities in the dataset",
       x = "Longitude", y = "Latitude") +
  theme(legend.position = "right")


########################### Map of California ########################

source("R/california_spatial_prep.R")

datax <- data.x %>%
  select(communityname, ViolentCrimesPerPop)

merged_cali <- merged_cali %>%
  left_join(datax, by = c("communityname"))

ca_map <- map_data("county", "california")

ggplot() +
  geom_polygon(data = ca_map, aes(x = long, y = lat, group = group), 
               fill = "gold", color = "black") +
  geom_point(data = merged_cali, aes(x = Longitude, y = Latitude, color = ViolentCrimesPerPop),
             size = 2) +
  geom_text_repel(data = merged_cali, aes(x = Longitude, y = Latitude, 
                                          label = communityname), 
                  size = 3, color = "black", max.overlaps = 10) +
  scale_color_gradient(low = "lightblue", high = "darkblue") +
  coord_fixed(1.3) +
  labs(title = "Map of Californian Communities", 
       x = "Longitude", y = "Latitude") +
  theme_minimal()

# for presentation -------------------------------------------------------------

state_map_modified <- state_map %>%
  left_join(data.x %>% 
              select(state,ViolentCrimesPerPop) %>%
              group_by(state) %>%
              summarise(mn = mean(ViolentCrimesPerPop)))
            
map_crime_rates <- ggplot() +
  geom_polygon(data = state_map_modified, 
               aes(x = long, y = lat, group = group, fill = mn), 
               color = "white") +
  scale_fill_gradient(low = "darkgreen", high = "red", 
                      na.value = "gray90", 
                      name = "Stand. Crime Rate") +
  theme_bw() +
  labs(x = "Longitude", y = "Latitude") +
  theme(legend.position = "right") +
  theme(axis.text.x = element_text(color = "grey20", size = 10),
        axis.text.y = element_text(color = "grey20", size = 10),  
        axis.title.x = element_text(color = "grey20", size = 20),
        axis.title.y = element_text(color = "grey20", size = 20))

ggsave(plot = map_crime_rates, filename = "output/figures/map_crime_rates.png")
