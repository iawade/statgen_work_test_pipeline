# Script to check normality of phenotype

# Load Packages
library(data.table)
library(nortest)

args <- commandArgs(trailingOnly = TRUE)

INPUT <- args[1]
OUTPUT <- args[2]

# Read in data
data <- fread(INPUT)

# Open a PDF file to save the plot
pdf("phenotype_distribution.pdf")

# Create a histogram of the second column of the data
hist(as.numeric(unlist(data[,2])),
     xlab = colnames(data)[2],  # Set x-axis label to the column name
     main = "Histogram of Phenotype Distribution") 

# Close the PDF file
dev.off()

# Statistical test for normality
## stats::shapiro.test(data$pheno) # sample size too large
normal_test <- nortest::ad.test(as.numeric(unlist(data[,2])))

# Check the p-value and decide whether to continue or stop

if (normal_test$p.value > 0.05) {
  # If the p-value is greater than 0.05, write the results to a file
  fwrite(normal_test, OUTPUT)
  print("Test passed, data written to the file.")
} else {
  # If the p-value is less than or equal to 0.05, throw an error and stop the script
  stop("Error: Normality test failed. p-value is less than 0.05.")
}

