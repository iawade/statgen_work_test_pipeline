#!/bin/bash

module load BCFtools

INPUT="$1"
OUTPUT="$2"

bcftools view -m2 -M2 -v snps "$INPUT" -Oz -o "$OUTPUT" # currently no flexibility
tabix -f -p vcf "$OUTPUT"
