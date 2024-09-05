#!/bin/bash

# Ideally would have a container for BCFtools for reproducibilty
module load BCFtools

INPUT="$1"
OUTPUT="$2"

# Function to check if the file is BGZF compressed
is_bgzip() {
    file "$INPUT" | grep -q "BGZF compressed"
}

# Function to check if the file is gzip compressed
is_gzip() {
    file "$INPUT" | grep -q "gzip compressed"
}

# Step 1: Check if the VCF is BGZF compressed
if is_bgzip "$INPUT"; then
    mv $INPUT $OUTPUT
else
    echo "The file $INPUT is not BGZF compressed."
    
    # If it's gzipped, gunzip it first
    if is_gzip "$INPUT"; then
        echo "Unzipping the gzip-compressed file..."
        gunzip "$INPUT"
        BGZIP_INPUT="${INPUT%.gz}"  # Remove the .gz extension to get the unzipped file name
    fi

    # BGZIP compress the file
    echo "Compressing the file with bgzip..."
    bgzip "$BGZIP_INPUT" -c > $OUTPUT
fi

# Step 2: Check if a .tbi index exists for the file
if [ -f "${INPUT}.tbi" ]; then
    mv "${INPUT}.tbi" "$OUTPUT.tbi"
else
    echo "The index file ${OUTPUT}.tbi does not exist. Creating it with tabix..."
    tabix -f -p vcf "$OUTPUT"  # Force tabix to create a new index
fi

echo "Done."

