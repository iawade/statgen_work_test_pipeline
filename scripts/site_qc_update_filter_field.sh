#!/bin/bash

module load BCFtools

INPUT="$1"
OUTPUT="$2"
GENO_MISSING_CUTOFF="$3"
EXC_HET_CUTOFF="$4"
HWE_CUTOFF="$5"
MAF_CUTOFF="$6"

# Apply fill-tags after removing poorly performing samples
# Label sites that don't pass siteQC filters

bcftools +fill-tags "$INPUT" -- -t AN,AC,AF,ExcHet,F_MISSING,HWE,MAF | \
	bcftools filter -e "INFO/F_MISSING > $GENO_MISSING_CUTOFF" -s "HighMissing" \
                | bcftools filter -e "INFO/HWE < $HWE_CUTOFF" -s "HWEViolation" \
                | bcftools filter -e "INFO/ExcHet < $EXC_HET_CUTOFF" -s "ExcessHet" \
                | bcftools filter -e "INFO/MAF < $MAF_CUTOFF" -s "LowMAF" \
                -Oz -o "$OUTPUT"

tabix -f -p vcf "$OUTPUT"

