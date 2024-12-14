library(tidyverse)

# Function to save the final dataset and manage directories
save_csv_data_files <- function(final_df, data_directory) {
  # Adjust paths to write to ../data/test directory
  test_directory <- file.path(data_directory, "test")  # Changed to point to "test" directory
  processed_directory <- file.path(data_directory, "processed")
  wrangled_dataset_file <- file.path(test_directory, "wrangled_data.csv")  # Save to test directory
  index_dataset_file <- file.path(test_directory, "random_training_index.csv")  # Save index to test directory
  
  # Debugging: Print paths to verify
  print(paste("Saving wrangled data to:", wrangled_dataset_file))
  print(paste("Saving random index file to:", index_dataset_file))
  
  # Print current working directory
  print(paste("Current working directory:", getwd()))
  
  # Ensure the test directory exists
  tryCatch({
    if (!dir.exists(test_directory)) {
      message(paste("Directory does not exist. Creating test directory:", test_directory))
      dir.create(test_directory, recursive = TRUE)
    } else {
      message(paste("Directory already exists:", test_directory))
    }
  }, error = function(e) {
    message(paste("Error in creating directory:", e$message))
  })
  
  # Attempt to write the CSV file with error handling
  tryCatch({
    write_csv(final_df, wrangled_dataset_file)  # Save the wrangled data to the test directory
    message("CSV successfully written.")
  }, error = function(e) {
    message(paste("Error writing CSV:", e$message))
  })
  
  # If the index file doesn't exist, generate it
  if (!file.exists(index_dataset_file)) {
    message("Generating random training index...")
    generate_indices_for_test_selection_30(test_directory)  # Ensure indices are saved in test directory
  }
  
  # Split the data into training and evaluation datasets
  split_data_frame(test_directory, processed_directory)  # Use test directory for splitting
}

# Main code
df_raw <- read.csv("../data/external/layoffs_data.csv")
wrangle_output <- wrangle_dataset(df_raw, accounting_counter)
df.final <- wrangle_output[[1]]
acct_iteration <- wrangle_output[[2]]

# Check if df.final is empty
if (nrow(df.final) == 0) {
  message("Warning: The dataframe is empty. CSV will not be written.")
} else {
  save_csv_data_files(df.final, "../data")
}


# Function to split the data into exploration and confirmation datasets
# Split the dataframe into exploration and confirmation files
split_data_frame <- function(source_directory, save_directory) {
  file_name_for_training_index <- file.path(source_directory, "random_training_index.csv")
  file_name_for_training_data <- file.path(source_directory, "interim_partitioned_dataset_for_splitting.csv")
  
  # Read data
  interim_selection_indices <- read_csv(file_name_for_training_index)
  interim_partitioned_dataframe <- read_csv(file_name_for_training_data)
  
  # Debugging: Print the columns of the data being split
  print("Columns of interim_partitioned_dataframe:")
  print(colnames(interim_partitioned_dataframe))
  
  # Split into training and evaluation sets
  train_df <- interim_partitioned_dataframe %>% 
    filter(row_number() %in% interim_selection_indices$random_selection_sample)
  
  eval_df <- interim_partitioned_dataframe %>%
    filter(!(row_number() %in% interim_selection_indices$random_selection_sample))
  
  # Debugging: Check the columns of the training and evaluation data
  print("Columns of train_df:")
  print(colnames(train_df))
  print("Columns of eval_df:")
  print(colnames(eval_df))
  
  # Write the split data
  write_csv(train_df, file.path(save_directory, "exploration.csv"))
  write_csv(eval_df, file.path(save_directory, "confirmation.csv"))
  
  return(list(train_df, eval_df))
}

# Function to generate the indices for test selection and partition the data
generate_indices_for_test_selection_30 <- function(directory) {
  data_source_file <- file.path(directory, "wrangled_data.csv")
  file_name_for_training_index <- file.path(directory, "random_training_index.csv")
  file_name_for_training_data <- file.path(directory, "interim_partitioned_dataset_for_splitting.csv")
  
  # Debugging: Check if function is being entered
  message("Starting generate_indices_for_test_selection_30")
  
  # Read the wrangled data
  df.wrangled <- read_csv(data_source_file)
  message("Columns of wrangled data:")
  print(colnames(df.wrangled))  # Check columns to ensure 'Percentage' is still there
  
  # Partition by 'Industry'
  partitioned_list <- split(df.wrangled, df.wrangled$Industry)
  message("Partitioned data by industry: ", length(partitioned_list), " partitions created.")
  
  # Ensure Percentage is included and do the selection
  sampled_selection_data <- lapply(partitioned_list, function(df.industry) {
    max_index <- nrow(df.industry)
    selection_amount <- ceiling(max_index * 0.3)
    
    # Mark selected rows (ensure 'Percentage' is retained in the df)
    df.industry$Selected <- ifelse(1:max_index %in% sample(1:max_index, size=selection_amount), 1, 0)
    
    return(df.industry)
  })
  
  # Ensure that the 'Percentage' column is retained in the final unified dataset
  df.unified <- bind_rows(sampled_selection_data) %>%
    mutate(random_selection_sample = row_number()) %>%
    select(Industry, Stage, Laid_Off_Count, Funds_Raised, 
           # Percentage, 
           random_selection_sample, Selected)
  
  # Debugging: Check if 'df.unified' has all required columns
  message("Columns in unified data:")
  print(colnames(df.unified))  # Make sure 'Percentage' is included
  
  # Save the selection index and the partitioned data
  write_csv(df.unified, file_name_for_training_data)  # Save partitioned data
  write_csv(df.unified %>% filter(Selected == 1) %>% select(random_selection_sample), file_name_for_training_index)  # Save selection index
  
  # Debugging: Confirm file is saved
  message("Saving training data and index files...")
}
