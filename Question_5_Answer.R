# Question 5 - NGS / PCR data merge
# Author: Steven Shideler
# Date: June 23rd, 2022

# The aim of this script is to merge all of the weekly NGS .csv files into one dataframe
# It also imports the monthly PCR results and then exports these results to temp tables in 
# SQL database. The temp tables in the SQL database are then appended to the existing NGS results 
# PCR results relational database tables. The connecting sql key would be the sample ID and allow for
#further report generation. 

library(tidyverse)
library(data.table)
library(odbc)
library(sqldf)

# Reads in all the of the weekly NGS results that are saved in the June month file.
fileList <- list.files(path="./NGS_Results/June", pattern=".csv")
df_list <- vector(model = "list", length = length(fileList))

#iterates over the files and reads them in, one at a time.
for ( i in 1:length(fileList)) {
   df_list[[i]] <- read.csv(fileList[i], header = "True", stringsAsFactors = FALSE)
}

#Combines all the files into one large dataframe containing the NGS files.
NGS_df <- rbindlist(df_list)

#Reads in the monthly PCR results 

pcr_df <- read.csv("June_PCR_results.csv", header = TRUE, stringsAsFactors = FALSE)


#sets up an SQL connections
sql_con <- dbConnect(odbc(),
                 Driver = "SQL Server",
                 Server = "ServerName",
                 Database = "DBName",
                 UID = "UserName",
                 PWD = "Password")


# Drop the temp tables if they already exist
if (dbExistsTable(sql_con, "temp_NGS_results"))
  dbRemoveTable(sql_con, "temp_NGS_results")

if(dbExistsTable(sql_con, "temp_PCR_results"))
  dbRemoveTable(sql_con, "temp_PCR_results")

# Write the data frame to the database
dbWriteTable(sql_con, name = "temp_NGS_results", value = NGS_DF, row.names = FALSE)
dbWriteTable(sql_con, name = "temp_PCR_results", value = pcr_df, row.names = FALSE)

#Append the temp tables created in the sql db to the exisiting NGS_Results and PCR_Results tables

sqlQuery(sql_con, 'insert into NGS_Results select * from temp_NGS_results')
sqlQuery(sql_con, 'insert into PCR_Results select * from temp_PCR_results')

