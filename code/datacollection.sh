#!/bin/bash

# Define the base URL and parameters
base_url="https://www.ncei.noaa.gov/access/monitoring/climate-at-a-glance/statewide/time-series"
start_year=2002
end_year=2022
month="06"
parameters=("avgTemp" "minTemp" "precip" "cooling-degree-days")

# Create the CSV file
echo "State,Year,Month,Avg_temp_june_value,Min_temp_june_value,Precipitation_june_value,Avg_cooling_degree_days_june" > ../data/raw_data/climate_data.csv

# Loop through all 50 states
for state_code in {1..50}; do
    state=$(printf "%02d" $state_code)
    
    # Loop through the years
    for year in $(seq $start_year $end_year); do
            
            # Loop through the parameters
            for param in "${parameters[@]}"; do
                
                # Construct the URL and make the request
                url="${base_url}?dataType=${param}&area=statewide&time_scale=monthly&month=${month}&state=${state}&year=${year}"
                response=$(curl -s "$url")
                
                # Parse the HTML to extract the data
                state_name=$(echo "$response" | sed -n 's/.*<h2>\(.*\): .*<\/h2>.*/\1/p')
                value=$(echo "$response" | sed -n "s/.*<td class=\"$param-\">\\s*\\(.*\\)\\s*<\/td>.*/\1/p")
                
                # Write the data to the CSV file
                echo "$state_name,$year,$month,$value" >> ../data/raw_data/climate_data.csv
            done
        done
    done
done