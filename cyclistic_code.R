# library(data.table)
library(tidyverse)
library(lubridate)
library(skimr)
library(scales)

td202207 <- read.csv("202207-divvy-tripdata.csv")
td202208 <- read.csv("202208-divvy-tripdata.csv")
td202209 <- read.csv("202209-divvy-publictripdata.csv")
td202210 <- read.csv("202210-divvy-tripdata.csv")
td202211 <- read.csv("202211-divvy-tripdata.csv")
td202212 <- read.csv("202212-divvy-tripdata.csv")
td202301 <- read.csv("202301-divvy-tripdata.csv")
td202302 <- read.csv("202302-divvy-tripdata.csv")
td202303 <- read.csv("202303-divvy-tripdata.csv")
td202304 <- read.csv("202304-divvy-tripdata.csv")
td202305 <- read.csv("202305-divvy-tripdata.csv")
td202306 <- read.csv("202306-divvy-tripdata.csv")

# data_frames_list <- list(td202207,td202208,td202209,td202210,td202211,td202212,
#                         td202301,td202302,td202303,td202304,td202305,td202306)

# trip_data <- rbindlist(data_frames_list)

trip_data <- rbind(td202207,td202208,td202209,td202210,td202211,td202212,
                   td202301,td202302,td202303,td202304,td202305,td202306)

str(trip_data)
colnames(trip_data)
head(trip_data)

rows_before <- nrow(trip_data)

na_records <- is.na(trip_data)
na_count_per_column <- colSums(na_records)
total_na_count <- sum(na_records)

trip_data <- drop_na(trip_data)

anyDuplicated(trip_data$ride_id)

trip_data <- trip_data[!(trip_data$start_station_name == "" |
                           trip_data$start_station_id == "" |
                           trip_data$end_station_name == "" |
                           trip_data$end_station_id == "" ),]

rows_after <- nrow(trip_data)

print(paste("Removed", rows_before - rows_after, " rows during cleaning"))

summary(trip_data)

trip_data$started_at <- ymd_hms(trip_data$started_at)
trip_data$ended_at <- ymd_hms(trip_data$ended_at)

skim(trip_data)

trip_data$duration <- as.numeric(trip_data$ended_at - trip_data$started_at, units = "secs")

skim(trip_data$duration)

negative_duration <- trip_data %>% 
  filter(duration < 0)

dim(negative_duration)
head(negative_duration)

zero_duration <- trip_data %>% 
  filter(duration == 0)
dim(zero_duration)
head(zero_duration)

short_duration <- trip_data %>% 
  filter(duration < 60)
dim(short_duration)

long_duration <- trip_data %>% 
  filter(duration > 86400)
dim(long_duration)

trip_data <- trip_data[!(trip_data$duration < 60 | trip_data$duration > 86400),]
skim(trip_data$duration)

# Distribution of rides by user types
rd_usertype <- trip_data %>% 
  group_by(member_casual) %>% 
  summarize(count = length(member_casual), part_rides = (length(member_casual) / nrow(trip_data)) * 100 )

print(rd_usertype)

# Piechart of distribution of rides by user type
pie <- ggplot(rd_usertype, aes(x='', y=part_rides, fill=member_casual))+
  geom_bar(width = 1, stat = "identity") + 
  coord_polar("y") +
  scale_fill_brewer(palette="Pastel2") + 
  theme(axis.text.x=element_blank()) +
  geom_text(aes(label = percent(part_rides / 100)),
            position = position_stack(vjust = 0.5), 
            size = 5) +
  labs(x= "", y= "", title = "Distribution of Rides by User Type")







# trip_data %>%
#  ggplot(aes(member_casual, fill = member_casual)) + geom_bar() + labs(x= "Type of 
# User", y= "Number of rides", title = "Rides Distribution By User Type")
