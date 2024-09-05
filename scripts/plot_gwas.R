# Script to plot GWAS results

# Load Packages
library(data.table)
library(tidyverse)
library(qqman)

args <- commandArgs(trailingOnly = TRUE)

INPUT <- args[1]
MANHATTAN <- args[2]
QQ <- args[3]

# Read in data
data <- fread(INPUT)

# Generate Manhattan plot
pdf(MANHATTAN)

manhattan(data, chr="#CHROM", bp="POS", snp="ID", p="P",
          main = "Manhattan Plot",
          cex.axis = 0.8,  # Control the size of axis labels
          las = 1,  # Make axis labels horizontal
          xlim = c((min(data$POS) - 50000), max(data$POS)))  # Suppress default x-axis labels


significant_snps <- data[data$P < 5E-08, ]

x_offset <- 5000  # Adjust this value as needed to create sufficient space

# Add labels manually to the plot
with(significant_snps, {
    text(POS - x_offset, -log10(P), labels = ID, cex = 0.75, col = "black", pos = 4)  # 'pos = 4' aligns the text to the right
})

dev.off()

# Generate QQ Plot
## Would want genomic control method and to find genomic inflation factor
pdf(QQ)

qq(data$P, main = "Q-Q plot of GWAS p-values", xlim = c(0, 15),
   ylim = c(0, 80),  col = "blue4", cex = 1.1, las = 1)

dev.off()

