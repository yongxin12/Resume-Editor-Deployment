#!/bin/bash

# Define an array of log group names
log_groups=(
  "/ecs/market_backend"
  "/ecs/market_frontend"
  "/ecs/editor_backend"
  "/ecs/editor_frontend"
)

# Loop through each log group and create it
for log_group in "${log_groups[@]}"; do
  echo "Creating log group: $log_group"
  aws logs create-log-group --log-group-name "$log_group" --region us-east-2 2>/dev/null
  
  # Check the status of the command
  if [ $? -eq 0 ]; then
    echo "Log group $log_group created successfully."
  else
    echo "Log group $log_group already exists or there was an error."
  fi
done
