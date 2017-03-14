packages <- c("data.table", "reshape2")
sapply(packages, require, character.only=TRUE, quietly=TRUE)

path <- getwd()
path

#Download the file and put in folder
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
f <- "Dataset.zip"
if (!file.exists(path)) {dir.create(path)}
download.file(url, file.path(path, f))

#Unzip the file
unzip("./Dataset.zip")

#Put unzipped files into UCI HAR Dataset folder
pathIn <- file.path(path, "UCI HAR Dataset")

#Read the subject files

SubjectTrain <- read.table(file.path(pathIn, "train", "subject_train.txt"))
SubjectTest  <- read.table(file.path(pathIn, "test" , "subject_test.txt" ))

#Read the activity files
ActivityTrain <- read.table(file.path(pathIn, "train", "Y_train.txt"))
ActivityTest  <- read.table(file.path(pathIn, "test" , "Y_test.txt" ))

#Read the features files
fileToDataTable <- function (f) {
  df <- read.table(f)
  dtbl <- data.table(df)
}
Train <- fileToDataTable(file.path(pathIn, "train", "X_train.txt"))
Test  <- fileToDataTable(file.path(pathIn, "test" , "X_test.txt" ))

# Merge the training and testing sets

Subject <- rbind(SubjectTrain, SubjectTest)
setnames(Subject, "V1", "subject")
Activity <- rbind(ActivityTrain, ActivityTest)
setnames(Activity, "V1", "activity_num")
dtbl <- rbind(Train, Test)

Subject <- cbind(Subject, Activity)
dtbl <- cbind(Subject, dtbl)
dtbl <- as.data.table(dtbl)

setkey(dtbl, subject, activity_num)

#Extract mean and std
Features <- fread(file.path(pathIn, "features.txt"))
setnames(Features, names(Features), c("feat_num", "feat_name"))

Features <- Features[grepl("mean\\(\\)|std\\(\\)", feat_name)]

Features$feat_code <- Features[, paste0("V", feat_num)]
head(Features)
Features$feat_code

#Descriptive Activity Names
select <- c(key(dtbl), Features$feat_code)
dtbl <- dtbl[, select, with=FALSE]

ActivityNames <- fread(file.path(pathIn, "activity_labels.txt"))
setnames(ActivityNames, names(ActivityNames), c("activity_num", "activity_name"))

dtbl <- merge(dtbl, ActivityNames, by="activity_num", all.x=TRUE)

setkey(dtbl, subject, activity_num, activity_name)

dtbl <- data.table(melt(dtbl, key(dtbl), variable.name="feat_code"))

dtbl <- merge(dtbl, Features[, list(feat_num, feat_code, feat_name)], by="feat_code", all.x=TRUE)

dtbl$activity <- factor(dtbl$activity_name)
dtbl$feature <- factor(dtbl$feat_name)

grepthis <- function (regex) {
  grepl(regex, dtbl$feature)
}

## Features with 2 categories
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

## Features with 1 category
dtbl$featJerk <- factor(grepthis("Jerk"), labels=c(NA, "Jerk"))
dtbl$featMagnitude <- factor(grepthis("Mag"), labels=c(NA, "Magnitude"))

## Features with 3 categories
n <- 3
y <- matrix(seq(1, n), nrow=n)
x <- matrix(c(grepthis("-X"), grepthis("-Y"), grepthis("-Z")), ncol=nrow(y))
dtbl$featAxis <- factor(x %*% y, labels=c(NA, "X", "Y", "Z"))

#Create a tidy data set
setkey(dtbl, subject, activity, featDomain, featAcceleration, featInstrument, featJerk, featMagnitude, featVariable, featAxis)
tidy_data <- dtbl[, list(count = .N, average = mean(value)), by=key(dtbl)]
