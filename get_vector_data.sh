#!/bin/bash

# Array of disease table numbers and names
declare -A diseases=(
    ["220"]="West_Nile"
    ["60"]="Chikungunya_virus_disease"
    ["90"]="Eastern_equine_encephalitis"
    ["110"]="Jamestown_Canyon"
    ["140"]="La_Crosse"
    ["170"]="Powassan"
    ["200"]="St_Louis_encephalitis"
    ["241"]="Western_equine_encephalitis"
    ["250"]="Babesiosis"
    ["460"]="Dengue"
    ["860"]="Malaria"
    ["1000"]="Plague"
    ["1310"]="Tularemia"
    ["1400"]="Yellow_fever"
    ["1412"]="Zika"
)

# Years to process (2008-2024)
years=($(seq 2008 2024))

# Function to get the last week for a given year
get_last_week() {
    local year=$1
    if [ "$year" -eq 2024 ]; then
        echo "45"  # Current week for 2024
    else
        echo "52"  # Last week for previous years
    fi
}

# Create output directory if it doesn't exist
mkdir -p vector_borne_data

# Loop through each disease and year
for table_num in "${!diseases[@]}"; do
    disease_name="${diseases[$table_num]}"
    
    for year in "${years[@]}"; do
        last_week=$(get_last_week $year)
        
        # Construct URL
        url="https://wonder.cdc.gov/nndss/static/$year/$last_week/$year-$last_week-table$table_num.txt"
        output_file="vector_borne_data/${disease_name}_${year}_processed.txt"
        
        echo "Downloading $disease_name data for $year week $last_week..."
        
        # Download and process file
        curl -s "$url" | awk -F'\t' -v year="$year" -v disease="$disease_name" '
            BEGIN {
                OFS="\t"
                print "State\tYear\tDisease\tCases"
            }
            # Skip until we find the tab delimited data line
            /^tab delimited data:/ { start=1; next }
            # Process data lines after "tab delimited data:" and before the explanatory notes
            start==1 && /^[A-Za-z. ()]+/ && !/^U:/ && !/^-:/ && !/^N:/ && !/^NN:/ && !/^NP:/ && !/^NC:/ && !/^Cum:/ && !/^For/ && !/^https/ {
                state = $1
                cases = $4  # Column with Cum YTD current year
                
                # Skip U.S. total, territories, and non-residents
                if (state !~ /^U\.S\.|^Total|^Non-U\.S\.|^Territories|^American|^Commonwealth|^Guam|^Puerto|^U\.S\. Virgin/) {
                    # Clean up state name (remove trailing Ü if present)
                    gsub("Ü$", "", state)
                    
                    # Convert various non-numeric values to 0
                    if (cases == "-" || cases == "N" || cases == "NN" || cases == "U" || cases == "NC") {
                        cases = "0"
                    }
                    
                    # Remove any commas from numbers
                    gsub(",", "", cases)
                    
                    # Only print if we have a valid state
                    if (state != "" && state !~ /^[[:space:]]*$/) {
                        print state, year, disease, cases
                    }
                }
            }
            # Stop processing when we hit the explanatory notes
            /^U:/ { exit }' > "$output_file"

        # Check if file is empty (except for header)
        if [ $(wc -l < "$output_file") -le 1 ]; then
            echo "Warning: No data found for $disease_name in $year"
            rm "$output_file"
        else
            echo "Successfully processed data for $disease_name in $year"
        fi
        
        # Add a small delay to not overwhelm the server
        sleep 2
    done
done

echo "Data collection complete! Results are in vector_borne_data directory"