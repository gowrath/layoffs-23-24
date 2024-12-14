library(tidyverse)

# Wrangle_dataset relies on a raw dataframe from the layoffs dataset only
# Each iterative process is then processed accordingly
# Params: Must require a raw datadf and the accounting function that returns a list per 2 dataframe inputs
# Returns: A final wrangled dataframe and the iterative accounting list for the accounting table
# EX:
# wrangled_result <- wrangle_dataset(df, accounting_counter) // Wrangled results
# df.final <- wrangled_result[[1]]          // final dataframe
# accounting_iter <- wrangled_result[[2]]   // Accounting iteration 

wrangle_dataset <- function(raw_df, acct_counter_func) {
  
  
  accounting_counter <- function(df1, df2) {
    # Example logic for tracking row changes
    list(
      initial_rows = nrow(df1),
      filtered_rows = nrow(df2),
      dropped_rows = nrow(df1) - nrow(df2)
    )
  }
  
  # Initialize tracking
  
  accounting_iter_track <- list()
  
  # Track the initial state
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(raw_df, raw_df)))
  
  # Limit observation to only be 2023
  df.dated <- raw_df %>% 
    filter(Date >= as.Date("2023-01-01") & Date <= as.Date("2023-12-31"))
  
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(raw_df, df.dated)))
  
  # See only the United States
  df.country_us <- df.dated %>% 
    filter(Country == "United States")
  
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(df.dated, df.country_us)))
  
  # Remove all rows with any NAs (in any column)
  df.no_unknowns <- df.country_us %>% 
    drop_na()  # Drops rows that have any NA values
    wrangle_dataset <- function(raw_df, acct_counter_func) {
  accounting_iter_track <- list()
  
  # Track the initial state
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(raw_df, raw_df)))
  
  # Limit observation to only be 2023
  df.dated <- raw_df %>% 
    filter(Date >= as.Date("2023-01-01") & Date <= as.Date("2023-12-31"))
  
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(raw_df, df.dated)))
  
  # See only the United States
  df.country_us <- df.dated %>% 
    filter(Country == "United States")
  
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(df.dated, df.country_us)))
  
  # Remove all rows with any NAs (in any column)
  df.no_unknowns <- df.country_us %>% 
    # drop_na()  # Drops rows that have any NA values
    drop_na(Laid_Off_Count, Funds_Raised, Industry, Stage) # Drops rows, excluding percentage
  
  cat("Rows with NA in Percentage are retained:")
  cat(summary(df.no_unknowns))
  
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(df.country_us, df.no_unknowns)))
  
  # Group by Company
  df.grouped_company <- df.no_unknowns %>% 
    group_by(Company, Industry, Stage) %>% 
    summarize(
      Laid_Off_Count = sum(Laid_Off_Count, na.rm=TRUE),
      Funds_Raised = mean(Funds_Raised, na.rm=TRUE)
      # ,
      # Percentage = first(Percentage)
    )
  
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(df.no_unknowns, df.grouped_company)))
  
  # Drop all duplicate companies that had their industry changed in the year
  df.no_dupe_company <- df.grouped_company %>% 
    group_by(Company) %>% 
    filter(n() == 1) %>% 
    ungroup()
  
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(df.grouped_company, df.no_dupe_company)))
  
  # Remove all unknowns in the Stage and Industry columns
  df.known_companies <- df.no_dupe_company %>% 
    filter(Stage != "Unknown" & Industry != "Unknown")
  
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(df.no_dupe_company, df.known_companies)))
  
  other_industry <- c("Aerospace", "AI", "Energy")
  
  # Rename low observation industries to "Other"
  df.final <- df.known_companies %>% 
    mutate(
      Industry = case_when(
        Industry %in% other_industry ~ "Other",
        TRUE ~ Industry
      )
    ) %>% 
    select(Industry, Stage, Laid_Off_Count, Funds_Raised
           # , Percentage
           )
  
  # No new changes made
  
  return(list(df.final, accounting_iter_track))
}

  
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(df.country_us, df.no_unknowns)))
  
  # Group by Company
  df.grouped_company <- df.no_unknowns %>% 
    group_by(Company, Industry, Stage) %>% 
    summarize(
      Laid_Off_Count = sum(Laid_Off_Count, na.rm=TRUE),
      Funds_Raised = mean(Funds_Raised, na.rm=TRUE)
      # ,
      # Percentage = first(Percentage)
    )
  
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(df.no_unknowns, df.grouped_company)))
  
  # Drop all duplicate companies that had their industry changed in the year
  df.no_dupe_company <- df.grouped_company %>% 
    group_by(Company) %>% 
    filter(n() == 1) %>% 
    ungroup()
  
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(df.grouped_company, df.no_dupe_company)))
  
  # Remove all unknowns in the Stage and Industry columns
  df.known_companies <- df.no_dupe_company %>% 
    filter(Stage != "Unknown" & Industry != "Unknown")
  
  accounting_iter_track <- c(accounting_iter_track, list(acct_counter_func(df.no_dupe_company, df.known_companies)))
  
  other_industry <- c("Aerospace", "AI", "Energy")
  
  # Rename low observation industries to "Other"
  df.final <- df.known_companies %>% 
    mutate(
      Industry = case_when(
        Industry %in% other_industry ~ "Other",
        TRUE ~ Industry
      )
    ) %>% 
    select(Industry, Stage, Laid_Off_Count, Funds_Raised
           # , Percentage
           )
  
  # No new changes made
  
  return(list(df.final, accounting_iter_track))
}
