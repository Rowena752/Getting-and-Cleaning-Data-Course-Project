# Getting-and-Cleaning-Data-Course-Project
# After Getting and Loading the Data Set:
## Merge the training and testing sets
### Concatenate the data tables 
```{r message=FALSE, results='hide'}
Subject <- rbind(SubjectTrain, SubjectTest)
setnames(Subject, "V1", "subject")
Activity <- rbind(ActivityTrain, ActivityTest)
setnames(Activity, "V1", "activity_num")
dtbl <- rbind(Train, Test)
```

### Merge the columns and make sure dtbl is a data.table object (in order to set the key)
```{r message=FALSE, results='hide'}
Subject <- cbind(Subject, Activity)
dtbl <- cbind(Subject, dtbl)
dtbl <- as.data.table(dtbl)
```

### Set the key for the data for use later
```{r message=FALSE, results='hide'}
setkey(dtbl, subject, activity_num)
```

## Extract mean and std
### Read the features.txt file, which tells us which varibles in dtbl are measurements for the mean and std
```{r message=FALSE, results='hide'}
Features <- fread(file.path(pathIn, "features.txt"))
setnames(Features, names(Features), c("feat_num", "feat_name"))
```
### Subset the measurements for mean and standard deviation using grepl
```{r message=FALSE, results='hide'}
Features <- Features[grepl("mean\\(\\)|std\\(\\)", feat_name)]
```
### Convert the column numbers to a vector of variable names which match the columns of dtbl
```{r message=FALSE, results='hide'}
Features$feat_code <- Features[, paste0("V", feat_num)]
```
### Subset these variables from above using the variable names 
```{r message=FALSE, results='hide'}
select <- c(key(dtbl), Features$feat_code)
dtbl <- dtbl[, select, with=FALSE]
```

## Descriptive Activity Names
### Read the activity_labels.txt file which can be used to add descriptive names to label the activities
```{r message=FALSE, results='hide'}
ActivityNames <- fread(file.path(pathIn, "activity_labels.txt"))
setnames(ActivityNames, names(ActivityNames), c("activity_num", "activity_name"))
```

### Merge the activity labels 
```{r message=FALSE, results='hide'}
dtbl <- merge(dtbl, ActivityNames, by="activity_num", all.x=TRUE)
```

### Add activity_name as a key for the data for later access ease 
```{r message=FALSE, results='hide'}
setkey(dtbl, subject, activity_num, activity_name)
```

### Melt the data.table in order to reshape it into a short and wide format
```{r message=FALSE, results='hide'}
dtbl <- data.table(melt(dtbl, key(dtbl), variable.name="feat_code"))
```

### Merge the data
```{r message=FALSE, results='hide'}
dtbl <- merge(dtbl, Features[, list(feat_num, feat_code, feat_name)], by="feat_code", all.x=TRUE)
```

### Create new variable called activity, which is equivalent to activity_name, as a factor class. Also create a new variable feature in dtbl, which is equivalent to feat_name, as a factor class
```{r message=FALSE, results='hide'}
dtbl$activity <- factor(dtbl$activity_name)
dtbl$feature <- factor(dtbl$feat_name)
```

### Helper function grepthis helps separate features from feature_name for labeling purposes, creating the variables for the tidy data set.  The variables are described later in this CodeBook.
```{r message=FALSE, results='hide'}
grepthis <- function (regex) {
  grepl(regex, dtbl$feature)
}
```

### Using the helper function on features with 2 categories
```{r message=FALSE, results='hide'}
n <- 2
y <- matrix(seq(1, n), nrow=n)
x <- matrix(c(grepthis("^t"), grepthis("^f")), ncol=nrow(y))
dtbl$featDomain <- factor(x %*% y, labels=c("Time", "Freq"))
x <- matrix(c(grepthis("Acc"), grepthis("Gyro")), ncol=nrow(y))
dtbl$featInstrument <- factor(x %*% y, labels=c("Accelerometer", "Gyroscope"))
x <- matrix(c(grepthis("BodyAcc"), grepthis("GravityAcc")), ncol=nrow(y))
dtbl$featAcceleration <- factor(x %*% y, labels=c(NA, "Body", "Gravity"))
x <- matrix(c(grepthis("mean()"), grepthis("std()")), ncol=nrow(y))
dtbl$featVariable <- factor(x %*% y, labels=c("Mean", "SD"))
```

### using the helper function on features with 1 category
```{r message=FALSE, results='hide'}
dtbl$featJerk <- factor(grepthis("Jerk"), labels=c(NA, "Jerk"))
dtbl$featMagnitude <- factor(grepthis("Mag"), labels=c(NA, "Magnitude"))
```

### Using the helper function on features with 3 categories
```{r message=FALSE, results='hide'}
n <- 3
y <- matrix(seq(1, n), nrow=n)
x <- matrix(c(grepthis("-X"), grepthis("-Y"), grepthis("-Z")), ncol=nrow(y))
dtbl$featAxis <- factor(x %*% y, labels=c(NA, "X", "Y", "Z"))
```

#Create a tidy data set, which features the average of each variable for every activity and subject
```{r message=FALSE, results='hide'}
setkey(dtbl, subject, activity, featDomain, featAcceleration, featInstrument, featJerk, featMagnitude, featVariable, featAxis)
tidy_data <- dtbl[, list(count = .N, average = mean(value)), by=key(dtbl)]
```
