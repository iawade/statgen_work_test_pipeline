#!/bin/bash

INPUT="$1"
OUTPUT="$2"
PROPORTION_MISSING_CUTOFF="$3"

NUMBER_OF_SITES=$(awk -F'\t' '/number of records:/ {print $4}' "$INPUT")
N_MISSING_CUTOFF=$(echo "$PROPORTION_MISSING_CUTOFF * $NUMBER_OF_SITES" | bc)

(echo -e "sample\tnmissing"; grep ^PSC "$INPUT" | awk -v cutoff="$N_MISSING_CUTOFF" '{if ($14 > cutoff) print $3 "\t" $14 }') > "$OUTPUT"

