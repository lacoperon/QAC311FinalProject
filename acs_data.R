# Authored by Elliot Williams
# May 12th, 2018
# If you use my code, please attribute me (and star my repo!)
# https://github.com/lacoperon/QAC311FinalProject

# Note: The result of this code is found within `./data/acs_panel_data.csv`, 
#       which is much faster than running this code on your local machine.

library(readr)
library(dplyr)

# -- Read in our custom PUMA 2010 Mapping file, to do as above
city_mapping <- read_csv("./constructed/CountyMapping.csv")

# -- American Community Survey State Codes --
# (as derived from their data dictionary -- doesn't change from year to year)
acs_states   <- read_csv("./constructed/acs_state_codes.csv")

# Now let's join the ACS state codes with our city mapping 
# of the 2010 PUMA Boundaries
city_join    <- inner_join(city_mapping, acs_states, by=c("State" = "STATE_NAME")) %>%
  mutate(STPUMA = paste(`STATE CODE`, `PUMA ID`))

# -- Read in PUMA 2000 Mapping File, to get the city mappings --
#The fields and content of the file is described below:
# FIELD     DESCRIPTION
# 
# A       Summary Level Code (described above)
# B       FIPS State Code
# C       SuperPUMA Code
# D       PUMA Code
# E       FIPS County Code
# F       FIPS County Subdivision Code
# G       FIPS Place Code
# H       Central City Indicator:
#   0 = Not in central city
# 1 = In central city
# I       Census Tract Code
# J       Metropolitan Statistical Area/Consolidated Statistical Area Code
# K       Primary Metropolitan Statistical Area Code
# L       Census 2000 100% Population Count
# M       Area Name
ascii_puma_2000 <- read_fwf("./data/2000PUMAsASCII.txt", 
                            fwf_widths(c(4, 3, 6, 6, 4, 6, 6, 2, 7, 5, 7,7, NA)))
colnames(ascii_puma_2000) <- ascii_puma_2000[1,]
colnames(ascii_puma_2000)[6] <- "F"
ascii_puma_2000 <- ascii_puma_2000[-1,]

# Filters the PUMA codes from the year 2000 to only include the relevant cities
pumaf <- filter(ascii_puma_2000,
                      grepl("Fresno city", M)        |
                        grepl("Los Angeles city", M)   |
                        grepl("Chicago city", M)       |
                        grepl("New York city", M)      |
                        grepl("Houston city", M)       |
                        grepl("Philadelphia city", M)  |
                        grepl("San Antonio city", M)   |
                        grepl("San Diego city", M)     |
                        grepl("Dallas city", M)        |
                        grepl("San Jose city", M)      |
                        grepl("Austin city", M)        |
                        grepl("Indianapolis city", M)  |
                        grepl("Jacksonville city", M)  |
                        grepl("San Francisco city", M) |
                        grepl("Columbus city", M)      |
                        grepl("Charlotte city", M)     | 
                        grepl("Fort Worth city", M)    |
                        grepl("Detroit city", M) |
                        grepl("Memphis city", M) |
                        grepl("Seattle city", M) |
                        grepl("Denver city", M) |
                        grepl("Washington city", M) |
                        grepl("Boston city", M) |
                        grepl("Nashville city", M) |
                        grepl("Oklahoma City city", M) |
                        grepl("Phoenix city", M) |
                        grepl("Louisville city", M) |
                        grepl("Portland city", M) |
                        grepl("Las Vegas city", M) |
                        grepl("Milwaukee city", M) |
                        grepl("Albuquerque city", M) |
                        grepl("Tucson city", M) |
                        grepl("Sacramento city", M) |
                        grepl("Long Beach city", M) |
                        grepl("Kansas City city", M) |
                        grepl("Mesa city", M) |
                        grepl("Virginia Beach city", M) |
                        grepl("Atlanta city", M) |
                        grepl("Colorado Springs city", M) |
                        grepl("Omaha city", M) |
                        grepl("Raleigh city", M) |
                        grepl("Miami city", M) |
                        grepl("Oakland city", M) |
                        grepl("Minneapolis city", M) |
                        grepl("Tulsa city", M) |
                        grepl("Cleveland city", M) |
                        grepl("Wichita city", M) |
                        grepl("Baltimore city", M) |
                        grepl("Arlington city", M)) %>% 
  select(B, D, M) %>%
  distinct(B, D, M) %>%
  mutate(City=gsub(" city.*", "", M)) %>%
  filter(City %in% unique(city_join$`ASSOCIATED CITY`)) %>%
  mutate(BD = paste(B, D))

rm(ascii_puma_2000)

# This function grabs all relevant data from a given ACS datafile, with PUMA
# formatting associated with the census in the year 2000
# Input:
#     path_a - path to first part of USA ACS data
#     path_b - path to second part of USA ACS data (autogenerated if not given)
# Output:
#     Dataframe containing relevant ACS data, with city information, for our 
#     metropolitan areas of interest.
get_acs_data_2000 <- function(path_a, path_b=-1) {
  if(path_b == -1) {
    path_b <- gsub("usa", "usb", path_a)
  }
  
  message(paste("Opening csv part A from", path_a))
  dfa <- read_csv(path_a, col_types=cols()) %>%
    filter(PUMA %in% unique(pumaf$D)) %>%
    filter(as.numeric(ST) %in% as.numeric(unique(pumaf$B))) %>%
    mutate(STPUMA = paste(ST, PUMA))
  
  message(paste("Opening csv part B from", path_b))
  dfb <- read_csv(path_b, col_types=cols()) %>%
    filter(PUMA %in% unique(pumaf$D)) %>%
    filter(ST %in% unique(pumaf$B)) %>%
    mutate(STPUMA = ifelse(ST < 10, paste0("0", ST, " ", PUMA), paste(ST, PUMA))) %>%
    filter(STPUMA %in% unique(pumaf$BD))
  
  message("Binding rows from both parts")
  df <- rbind(dfa, dfb)
  rm(dfa, dfb)
  
  message("Inner joining to PUMA boundaries")
  df <- inner_join(df, pumaf, by=c("STPUMA"="BD"))
  return(df)
}


# This function grabs all relevant data from a given ACS datafile, with PUMA
# formatting associated with the census in the year 2010
# Input:
#     path_a - path to first part of USA ACS data
#     path_b - path to second part of USA ACS data (autogenerated if not given)
# Output:
#     Dataframe containing relevant ACS data, with city information, for our 
#     metropolitan areas of interest.
get_acs_data_2010 <- function(path_a, path_b=-1) {
  
  if(path_b == -1) {
    path_b <- gsub("usa", "usb", path_a)
  }
  
  message(paste("Opening csv part A from", path_a))
  dfa <- read_csv(path_a, col_types = cols()) %>%
    filter(PUMA %in% unique(city_join$`PUMA ID`))
  
  message(paste("Opening csv part B from", path_b))
  dfb <- read_csv(path_b, col_types = cols()) %>%
    filter(PUMA %in% unique(city_join$`PUMA ID`))
  
  df <- rbind(dfa, dfb) %>%
    mutate(STPUMA = paste(ST, PUMA)) %>%
    filter(STPUMA %in% unique(city_join$STPUMA))
  
  rm(dfa, dfb)
  return(df)
}

#https://usa.ipums.org/usa/volii/2000PUMAsASCII.txt

# -- Get ACS Datasets for our metro regions of interest, from 2008 to 2014 --
# Get Metro Region Data using 2000 PUMA boundaries
df08 <- get_acs_data_2000("./data/csv_pus2008/ss08pusa.csv")
df09 <- get_acs_data_2000("./data/csv_pus2009/ss09pusa.csv")
df10 <- get_acs_data_2000("./data/csv_pus2010/ss10pusa.csv")
df11 <- get_acs_data_2000("./data/csv_pus2011/ss11pusa.csv")
# Get Metro Region Data using 2010 PUMA boundaries
df12 <- get_acs_data_2010("./data/csv_pus2012/ss12pusa.csv")
df13 <- get_acs_data_2010("./data/csv_pus2013/ss13pusa.csv")
df14 <- get_acs_data_2010("./data/csv_pus2014/ss14pusa.csv")

# This function reduces a given year's ACS dataframe into a dataframe of 
# summary statistics for that year (as can be seen within the Project
# Appendix, as well as the README)
# Input:
#     df - ACS dataframe of a given year, with associated city data,
#          in PUMA format for the year 2000
# Output:
#     Dataframe containing relevant ACS metadata, by city, for a given year
get_agg_data_2000 <- function(df) {
  df <- inner_join(df, pumaf, c("STPUMA"="BD")) %>%
    group_by(City.y) %>%
    summarize(income=mean(as.numeric(PERNP), na.rm=T),
              racaian= mean(as.numeric(RACAIAN), na.rm=T),
              racasn= mean(as.numeric(RACASN), na.rm=T),
              racblk= mean(as.numeric(RACBLK), na.rm=T),
              racsor= mean(as.numeric(RACSOR), na.rm=T),
              racwht= mean(as.numeric(RACWHT), na.rm=T),
              selfcare_diff = mean(as.numeric(DDRS), na.rm=T),
              ind_liv_diff  = mean(as.numeric(DOUT), na.rm=T),
              amb_diff      = mean(as.numeric(DOUT), na.rm=T),
              is_medicare   = mean(as.numeric(HINS3), na.rm=T),
              is_va         = mean(as.numeric(HINS6), na.rm=T),
              public_assist_inc = mean(as.numeric(PAP), na.rm=T),
              ret_income    = mean(as.numeric(RETP), na.rm=T),
              avg_schl      = mean(as.numeric(SCHL), na.rm=T),
              ss_income     = mean(as.numeric(SSP), na.rm=T),
              age=mean(as.numeric(AGEP), na.rm=T),
              disabled=mean(as.numeric(DIS), na.rm=T),
              is_insured=mean(as.numeric(HICOV), na.rm=T),
              is_married=mean(as.numeric(MAR == 1)),
              inc_pov_ratio=mean(as.numeric(POVPIP), na.rm=T),
              avg_weight=mean(as.numeric(pwgtp1), na.rm=T) %>%
                mutate(City=City.y) %>%
                select(-City.y))
  
  return(df)
}

# This function reduces a given year's ACS dataframe into a dataframe of 
# summary statistics for that year (as can be seen within the Project
# Appendix, as well as the README)
# Input:
#     df - ACS dataframe of a given year, with associated city data,
#          in PUMA format for the year 2010
# Output:
#     Dataframe containing relevant ACS metadata, by city, for a given year
get_agg_data_2010 <- function(df) {
  df <- inner_join(df, city_join, c("STPUMA"="STPUMA")) %>%
    group_by(`ASSOCIATED CITY`) %>%
    summarize(income=mean(as.numeric(PERNP), na.rm=T),
              racaian= mean(as.numeric(RACAIAN), na.rm=T),
              racasn= mean(as.numeric(RACASN), na.rm=T),
              racblk= mean(as.numeric(RACBLK), na.rm=T),
              racsor= mean(as.numeric(RACSOR), na.rm=T),
              racwht= mean(as.numeric(RACWHT), na.rm=T),
              selfcare_diff = mean(as.numeric(DDRS), na.rm=T),
              ind_liv_diff  = mean(as.numeric(DOUT), na.rm=T),
              amb_diff      = mean(as.numeric(DOUT), na.rm=T),
              is_medicare   = mean(as.numeric(HINS3), na.rm=T),
              is_va         = mean(as.numeric(HINS6), na.rm=T),
              public_assist_inc = mean(as.numeric(PAP), na.rm=T),
              ret_income    = mean(as.numeric(RETP), na.rm=T),
              avg_schl      = mean(as.numeric(SCHL), na.rm=T),
              ss_income     = mean(as.numeric(SSP), na.rm=T),
              age=mean(as.numeric(AGEP), na.rm=T),
              disabled=mean(as.numeric(DIS), na.rm=T),
              is_insured=mean(as.numeric(HICOV), na.rm=T),
              is_married=mean(as.numeric(MAR == 1)),
              inc_pov_ratio=mean(as.numeric(POVPIP), na.rm=T),
              avg_weight=mean(as.numeric(pwgtp1), na.rm=T)
               )  %>%
    mutate(City=`ASSOCIATED CITY`) %>%
    select(-`ASSOCIATED CITY`)
  
  return(df)
}

# Gets Aggregate Data for Each Year in the Analysis, and tags it with the year
df08_panel <- get_agg_data_2000(df08) %>% mutate(year = "2008")
df09_panel <- get_agg_data_2000(df09) %>% mutate(year = "2009")
df10_panel <- get_agg_data_2000(df10) %>% mutate(year = "2010")
df11_panel <- get_agg_data_2000(df11) %>% mutate(year = "2011")
df12_panel <- get_agg_data_2010(df12) %>% mutate(year = "2012")
df13_panel <- get_agg_data_2010(df13) %>% mutate(year = "2013")
df14_panel <- get_agg_data_2010(df14) %>% mutate(year = "2014")

# Combines all of our data, so that we have data in bone fide panel format
df_panel <- rbind(df08_panel, df09_panel, df10_panel,
                  df11_panel, df12_panel, df13_panel, df14_panel)

# Writes the resulting data to CSV, allowing for access without having to run 
# all of this involved computation (which takes some time)
write_csv(df_panel, "./data/acs_panel_data.csv")
