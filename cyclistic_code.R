# Load packages
library(tidyverse)
library(lubridate)
library(skimr)
library(scales)

# Collect data
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

# Merge monthly temporary data-frames in single data-frame
trip_data <- rbind(td202207,td202208,td202209,td202210,td202211,td202212,
                   td202301,td202302,td202303,td202304,td202305,td202306)

# Check structure of data frame
str(trip_data)
# Check names of variable
colnames(trip_data)
# Check 6 first records of data frame
head(trip_data)

# Check number of rows before cleaning
rows_before <- nrow(trip_data)

# Check data frame for N/A records
na_records <- is.na(trip_data)
na_count_per_column <- colSums(na_records)
total_na_count <- sum(na_records)

# Drop N/A
trip_data <- drop_na(trip_data)

# Check for duplicate ride_ids
anyDuplicated(trip_data$ride_id)

# Clean all missing values
trip_data <- trip_data[!(trip_data$start_station_name == "" |
                           trip_data$start_station_id == "" |
                           trip_data$end_station_name == "" |
                           trip_data$end_station_id == "" ),]

# Check number of row after cleaning
rows_after <- nrow(trip_data)

# Number of removed rows during cleaning
print(paste("Removed", rows_before - rows_after, " rows during cleaning"))

# Check of properly data format
summary(trip_data)

# Convert columns in datetime format
trip_data$started_at <- ymd_hms(trip_data$started_at)
trip_data$ended_at <- ymd_hms(trip_data$ended_at)

# Check of properly data format again
skim(trip_data)

# add duration column
trip_data$duration <- as.numeric(trip_data$ended_at - trip_data$started_at, units = "secs")

#add month column
trip_data$month <- month(trip_data$started_at, label = TRUE, locale = "en")

#add weekday column
trip_data$weekday <- wday(trip_data$started_at, label = TRUE, locale = "en")

#add dayhour column
trip_data$dayhour <- hour(trip_data$started_at)

# check new column for errors
skim(trip_data)

# Create subset with records of negative duration only
negative_duration <- trip_data %>% 
  filter(duration < 0)

# Check dimension of subset
dim(negative_duration)
# Preview of subset
head(negative_duration)

# Same procedure for zero duration
zero_duration <- trip_data %>% 
  filter(duration == 0)
dim(zero_duration)
head(zero_duration)

# Same procedure for short duration < 1'
short_duration <- trip_data %>% 
  filter(duration < 60)
dim(short_duration)

# Same procedure for long duration > 24 h
long_duration <- trip_data %>% 
  filter(duration > 86400)
dim(long_duration)

# clean data from negative, zero and short duration
trip_data <- trip_data[!(trip_data$duration < 60 | trip_data$duration > 86400),]
skim(trip_data$duration)

# export cleaned data for Tableau
write.csv(trip_data, "trip_data.csv")

# Distribution of rides by user types
rd_usertype <- trip_data %>% 
  group_by(member_casual) %>% 
  summarise(count = length(member_casual), part_rides = (length(member_casual) / nrow(trip_data)) * 100 )
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

# Distribution of rides by user types and month
rd_month <- trip_data %>% 
  group_by(member_casual, month) %>%
  summarise(count = length(month),
            .groups = "drop")

# casual users monthly rides filter
casual_rd_month <- trip_data %>% 
  group_by(month) %>%
  filter(member_casual == "casual") %>% 
  summarise(count = length(month), .groups = "drop")

# Calculate mean and standard deviation of casual user monthly rides
casual_rd_month %>% 
  summarise(mean(count),sd(count))
  
# member users monthly rides filter
member_rd_month <- trip_data %>% 
  group_by(month) %>%
  filter(member_casual == "member") %>% 
  summarise(count = length(month), .groups = "drop")

# Calculate mean and standard deviation of member user monthly rides
member_rd_month %>% 
  summarise(mean(count),sd(count))

# Bar plot of distribution of rides by user types and month
rd_month_plot <- ggplot(rd_month, aes(month, count, fill = member_casual)) +
  geom_col(position = "dodge") +  scale_fill_brewer(palette="Set2") +
  labs(title = "The number of rides by month", x = "Month", y = "Number of rides")

# Distribution of rides by user types and day of the week
rd_weekday <- trip_data %>% 
  group_by(member_casual, weekday) %>%
  summarise(count = length(weekday),
            .groups = "drop")

# casual users daily rides filter
casual_rd_weekday <- trip_data %>% 
  group_by(weekday) %>%
  filter(member_casual == "casual") %>% 
  summarise(count = length(weekday), .groups = "drop")

# Calculate mean and standard deviation of casual user daily rides
casual_rd_weekday %>% 
  summarise(mean(count),sd(count))

# member users daily rides filter
member_rd_weekday <- trip_data %>% 
  group_by(weekday) %>%
  filter(member_casual == "member") %>% 
  summarise(count = length(weekday), .groups = "drop")

# Calculate mean and standard deviation of member user monthly rides
member_rd_weekday %>% 
  summarise(mean(count),sd(count))

# Bar plot of distribution of rides by user types and day of week
rd_weekday_plot <- ggplot(rd_weekday, aes(weekday, count, fill = member_casual)) +
  geom_col(position = "dodge") +  scale_fill_brewer(palette="Set2") +
  labs(title = "The number of rides by day of week", x = "Day of week", y = "Number of rides") +
  facet_wrap(~member_casual)

# Distribution of rides by user types and hour of the day
rd_dayhour <- trip_data %>% 
  group_by(member_casual, dayhour) %>%
  summarise(count = length(dayhour),
            .groups = "drop")

# casual users daily rides filter
casual_rd_dayhour <- trip_data %>% 
  group_by(dayhour) %>%
  filter(member_casual == "casual") %>% 
  summarise(count = length(dayhour), .groups = "drop")

# Calculate mean and standard deviation of casual user daily rides
casual_rd_dayhour %>% 
  summarise(mean(count),sd(count))

# member users daily rides filter
member_rd_dayhour <- trip_data %>% 
  group_by(dayhour) %>%
  filter(member_casual == "member") %>% 
  summarise(count = length(dayhour), .groups = "drop")

# Calculate mean and standard deviation of member user monthly rides
member_rd_dayhour %>% 
  summarise(mean(count),sd(count))

# Bar plot of distribution of rides by user types and hour of day
rd_dayhour_plot <- ggplot(rd_dayhour, aes(dayhour, count, fill = member_casual)) +
  geom_area(position = "dodge") +  scale_fill_brewer(palette="Set2") +
  labs(title = "The number of rides by hour of day", x = "Hour of day", y = "Number of rides") +
  facet_wrap(~member_casual)

# Distribution of rides by user types and type of vehicle
rd_rideable_type <- trip_data %>% 
  group_by(member_casual, rideable_type) %>%
  summarise(count = length(rideable_type),
            .groups = "drop")
print(rd_rideable_type)

rd_rideable_plot <- ggplot(rd_rideable_type, aes(member_casual, count, fill = rideable_type)) +
  geom_col(position = "dodge") +  scale_fill_brewer(palette="Set2") +
  labs(title = "The number of rides by type of vehicle", x = "Type of vehicle", y = "Number of rides")

#Distribution of rides by user types and start station
rd_station <- trip_data %>% 
  group_by(member_casual, start_station_name) %>%
  summarise(count = length(start_station_name), start_id = first(start_station_id),
            .groups = "drop") %>% 
  arrange(desc(count))
print(rd_station)


# Distribution of rides by user types and duration of ride
rd_duration <- trip_data %>% 
  group_by(member_casual) %>%
  summarise(mean = mean(duration), min = min(duration), max = max(duration), 
            sd = sd(duration), median = median(duration), .groups = "drop")
print(rd_duration)

# Piechart of distribution of ride mean duration by user types
mean_duration_plot <- ggplot(rd_duration, aes(x='', y=mean, fill=member_casual))+
  geom_bar(width = 1, stat = "identity") + 
  coord_polar("y") +
  scale_fill_brewer(palette="Pastel1") + 
  theme(axis.text.x=element_blank()) +
  geom_text(aes(label = round(mean, digits=0)),
            position = position_stack(vjust = 0.5), 
            size = 5) +
  labs(x= "", y= "", title = "Distribution of Mean Duration by User Type")

# Piechart of distribution of ride median duration by user types
median_duration_plot <- ggplot(rd_duration, aes(x='', y=median, fill=member_casual))+
  geom_bar(width = 1, stat = "identity") + 
  coord_polar("y") +
  scale_fill_brewer(palette="Set1") + 
  theme(axis.text.x=element_blank()) +
  geom_text(aes(label = round(median, digits=0)),
            position = position_stack(vjust = 0.5), 
            size = 5) +
  labs(x= "", y= "", title = "Distribution of Median Duration by User Type")

# Distribution of ride duration by user types and month
duration_month <- trip_data %>% 
  group_by(member_casual, month) %>%
  summarise(mean = mean(duration), min = min(duration), max = max(duration), 
            sd = sd(duration), median = median(duration), .groups = "drop")
print(n=24, duration_month)


median_month_plot <- ggplot(duration_month, aes(month, median, fill = member_casual)) +
  geom_col(position = "dodge") +  scale_fill_brewer(palette="Set1") +
  labs(title = "The median ride duration by month", x = "Month", y = "Median")

# Distribution of ride duration by user types and day of the week
duration_weekday <- trip_data %>% 
  group_by(member_casual, weekday) %>%
  summarise(mean = mean(duration), min = min(duration), max = max(duration), 
            sd = sd(duration), median = median(duration), .groups = "drop")
print(duration_weekday)

median_weekday_plot <- ggplot(duration_weekday, aes(weekday, median, fill = member_casual)) +
  geom_col(position = "dodge") +  scale_fill_brewer(palette="Set1") +
  labs(title = "The median ride duration by days", x = "Days of the Week", y = "Median")

# Distribution of ride duration by user types and hour of the day
duration_dayhour <- trip_data %>% 
  group_by(member_casual, dayhour) %>%
  summarise(mean = mean(duration), min = min(duration), max = max(duration), 
            sd = sd(duration), median = median(duration), .groups = "drop")

median_dayhour_plot <- ggplot(duration_dayhour, aes(dayhour, median, fill = member_casual)) +
  geom_col(position = "dodge") +  scale_fill_brewer(palette="Set1") +
  labs(title = "The median ride duration by hours", x = "Hour of the Day", y = "Median")

# Distribution of ride duration by user types and type of vehicle
duration_rideable_type <- trip_data %>% 
  group_by(member_casual, rideable_type) %>%
  summarise(mean = mean(duration), min = min(duration), max = max(duration), 
            sd = sd(duration), median = median(duration), .groups = "drop")
print(duration_rideable_type)

duration_rideable_plot <- ggplot(duration_rideable_type, aes(member_casual, median, fill = rideable_type)) +
  geom_col(position = "dodge") +  scale_fill_brewer(palette="Set1") +
  labs(title = "The median ride duration by type of vehicle", x = "Type of vehicle", y = "Median")