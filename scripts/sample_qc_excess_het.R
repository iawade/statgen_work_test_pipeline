# Script to Identify Excess Heterozygosity Fails

# Load Packages
library(data.table)
library(dplyr)

args <- commandArgs(trailingOnly = TRUE)

INPUT <- args[1]
OUTPUT <- args[2]
MAD_CUTOFF <- as.numeric(args[3])

# Read in data
new_column_names <- c("PSC", "id", "sample", "nRefHom", "nNonRefHom", "nHets",
		      "nTransitions", "nTransversions", "nIndels", "average_depth",
		      "nSingletons", "nHapRef", "nHapAlt", "nMissing")

data <- fread(INPUT, header=FALSE) %>%
	setNames(new_column_names) %>%
	mutate(het_rate = nHets / ( nHets + nRefHom + nNonRefHom  )) 

# Identify sample fails
mad_value <- mad(data$het_rate)
median_value <- median(data$het_rate)

sample_fails <- data %>%
	filter( het_rate < median_value - MAD_CUTOFF  * mad_value | 
                het_rate > median_value + MAD_CUTOFF * mad_value) %>%
	select(sample, het_rate)
	

# Write output
fwrite(sample_fails, OUTPUT, sep="\t")

