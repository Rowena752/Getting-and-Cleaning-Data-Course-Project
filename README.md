# Getting-and-Cleaning-Data-Course-Project

## About the Data Set
The Data Set originally comes from this site: http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones.  
This raw data set contains a training set and a test set of data about human activity as linked to smartphones.  The, unlabeled, features are in the x_test.txt file while the activity labels are in the y_test.txt file.  The test subjects can be found in the subject_test.txt file.  A similiar situation applies to the training set.  

## About the run_analysis.R script and the resulting tidy data
The run_analysis.R script extracts the data from the original source of the unzipped file.  It then merges the training and testing sets and undergoes multiple steps to extract the mean and standard deviation related data, to rearrange the data for the purposes of creating tidy data, and to appropriately relabel the data descriptively.  More details about the transformations can be found in the CodeBook.  

## About the Codebook
The CodeBook features comments on the code in the script to understand the purposes of each step.  It also describes the data and variables created in the resulting tidy data set.  
