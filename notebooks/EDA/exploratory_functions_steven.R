library(tidyverse)

eda_process <- function(filename, filedir) {
  full_file <- paste(filedir,filename, sep = "")
  dataset <- read.csv(full_file)
  
  print(head(dataset))
  print(tail(dataset))
  print(dim(dataset))
  
  print(data.frame(names=colnames(dataset)))
  print(t(summary(dataset)))
  
  print(str(dataset))
  print(sum(is.na(dataset)))
  
  return(dataset)
}

# Returns the the row count of previous df, current df, and the delta. 
# Assumes current_df is a strict subset of previous df where current <= previous
accounting_counter <- function(previous_df, current_df) {
  prev_rows <- nrow(previous_df)
  curr_rows <- nrow(current_df)
  delta_rows <-  curr_rows - prev_rows # Negative if removed, positive if added, 0 if no change
  return(list(prev_rows, curr_rows, delta_rows))
}


# Directory - will always look for wrangled_data.csv within and save the files into this particular directory
generate_indices_for_test_selection_30 <- function(directory) {
  file_name_for_training_index <- paste(directory,"/random_training_index.csv", sep="")
  file_name_for_training_data <- paste(directory, "/interim_partitioned_dataset_for_splitting.csv", sep="")
  
  data_source_file <- paste(directory, "/wrangled_data.csv", sep="")
  
  # Replicate the divide and conquer algorithms
  # Partitions by the industry to allow equal bearing per the 30ish/70ish split
  df.wrangled <- read_csv(data_source_file)
  partitioned_list <- split(df.wrangled, df.wrangled$Industry)
  
  sampled_selection_data <- list()
  
  # Retrieve the key index in the loop to parititon by the scheme of 30% round up to nearest whole
  for (industry_key in names(partitioned_list)) {
    df.industry <- partitioned_list[[industry_key]]
    max_index <- nrow(df.industry)
    
    selection_amount <- ceiling(max_index * 0.3)
    df.industry$Selected <- random_selection_sample <- ifelse(1:max_index %in% sample(1:max_index, size=selection_amount), 1, 0)
    
    sampled_selection_data[[industry_key]] <- df.industry
  }
  
  df.unified <- bind_rows(sampled_selection_data)
  df.unified_by_row <- df.unified %>% 
    mutate(
      random_selection_sample = row_number()
    )
  
  # Finals output
  df.final_data <- df.unified_by_row %>% 
    select(Industry, Stage, Laid_Off_Count, Funds_Raised)
  
  df.selection_rows <- df.unified_by_row %>% 
    filter(Selected == 1) %>% 
    select(random_selection_sample)
 
  write_csv(df.selection_rows, file_name_for_training_index)
  write_csv(df.final_data, file_name_for_training_data)
}

# Split the dataframe into the files
# Will always look for 2 files: A partitioned file and the index to partition file
# from the source directory
# Save directory will always contain the exploration and confirmation csv files
split_data_frame <- function(source_directory, save_directory) {
  `%not_in%` <- Negate(`%in%`)
  
  file_name_for_training_index <- paste(source_directory,"/random_training_index.csv", sep="")
  file_name_for_training_data <- paste(source_directory, "/interim_partitioned_dataset_for_splitting.csv", sep="")
  
  interim_selection_indices <- read_csv(file_name_for_training_index)
  interim_partitioned_dataframe <- read_csv(file_name_for_training_data)
  
  train_df <- interim_partitioned_dataframe %>%
    filter(row_number() %in% interim_selection_indices$random_selection_sample)

  eval_df <- interim_partitioned_dataframe %>%
    filter(row_number() %not_in% interim_selection_indices$random_selection_sample)

  training_file <- paste(save_directory,"/exploration.csv", sep="")
  evaluation_file <-  paste(save_directory,"/confirmation.csv", sep="")
  write_csv(train_df, training_file)
  write_csv(eval_df, evaluation_file)
  
  return(list(train_df, eval_df))
}
