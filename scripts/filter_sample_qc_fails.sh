#!/bin/bash

module load BCFtools

INPUT="$1"
OUTPUT="$2"
GENO_FAILS="$3"
EXC_HET_FAILS="$4"

# Obtain list of samples to retain
cut -f 1 <(cat "$GENO_FAILS" "$EXC_HET_FAILS" ) > sample_qc_fails.txt # not completely safe but works for most situtations
grep -Fvxf <(cat sample_qc_fails.txt)  <(bcftools query -l "$INPUT") > sample_qc_passes.txt

# Apply filter
bcftools view --force-samples -S sample_qc_passes.txt  -Oz -o "$OUTPUT" "$INPUT" 
tabix -f -p vcf "$OUTPUT"

# Clean up
rm sample_qc_passes.txt sample_qc_fails.txt

