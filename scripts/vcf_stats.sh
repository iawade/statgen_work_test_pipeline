#!/bin/bash

module load BCFtools

INPUT="$1"
OUTPUT="$2"

bcftools stats -s - "$INPUT" > "$OUTPUT"

