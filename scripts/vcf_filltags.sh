#!/bin/bash

module load BCFtools

INPUT="$1"
OUTPUT="$2"

bcftools +fill-tags "$INPUT" -Oz -o "$OUTPUT" -- -t AN,AC,AF,ExcHet,F_MISSING,HWE,MAF 
tabix -f -p vcf "$OUTPUT"
