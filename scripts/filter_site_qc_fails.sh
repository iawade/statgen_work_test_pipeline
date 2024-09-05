#!/bin/bash

module load BCFtools

INPUT="$1"
OUTPUT="$2"

bcftools view -i "%FILTER='PASS'" "$INPUT" -Oz -o "$OUTPUT"
tabix -f -p vcf "$OUTPUT"

