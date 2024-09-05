#!/bin/bash

INPUT="$1"
OUTPUT="$2"
PHENO_FILE="$3"

# Convert vcf
plink2 --vcf "$INPUT" --make-pgen --out plink_files

# Add phenotype
sed -i "1s/.*/#IID\tPHENO/" "$PHENO_FILE"
plink2 --pfile plink_files --pheno "$PHENO_FILE" --make-pgen --out plink_files_pheno

# Calculate regression
plink2 --pfile plink_files_pheno --glm allow-no-covars --out plink_files_pheno_gwas

cp plink_files_pheno_gwas.PHENO.glm.linear "$OUTPUT"	

