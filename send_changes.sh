#!/bin/bash

# Enable verbose output if VERBOSE is true
if [ "$VERBOSE" = "true" ]; then
  set -x  # Enable debugging
fi

# Exit if any command fails
set -e

echo "Webhook URL: $WEBHOOK_URL"
echo "File Type: $FILE_TYPE"
echo "Mode: $MODE"
echo "Verbose Mode: $VERBOSE"

# Ensure FILE_TYPE and MODE are set
if [ -z "$FILE_TYPE" ]; then
  echo "FILE_TYPE variable is not set. Please provide a file extension (e.g., 'mdx', 'json')."
  exit 1
fi

if [ -z "$MODE" ]; then
  echo "MODE variable is not set. Please provide a mode: 'full-refresh' or 'incremental'."
  exit 1
fi

# Fetch all history for the branch
git fetch --depth=2 origin $GITHUB_REF:refs/remotes/origin/$GITHUB_REF

# Cache file to track processed files for incremental mode
cache_file=".file_cache_$FILE_TYPE.txt"

# Get the list of files to process based on mode
if [ "$MODE" = "full-refresh" ]; then
  # Full refresh mode: always process all files
  files_to_send=$(find . -type f -name "*.$FILE_TYPE")

elif [ "$MODE" = "incremental" ]; then
  if [ ! -f "$cache_file" ]; then
    # First run of incremental mode: send all files and create cache
    files_to_send=$(find . -type f -name "*.$FILE_TYPE")
    echo "$files_to_send" > "$cache_file"
  else
    # Subsequent runs of incremental mode: send only changed files
    changed_files=$(git diff --name-only HEAD^ HEAD | grep "\.$FILE_TYPE$" || true)
    
    if [ -n "$changed_files" ]; then
      # Add changed files to send list
      files_to_send="$changed_files"
      # Update the cache with new/modified files only
      printf "%s\n" "$changed_files" >> "$cache_file"
      # Remove duplicates in cache
      sort -u -o "$cache_file" "$cache_file"
    else
      echo "No new or modified .$FILE_TYPE files to send."
      exit 0
    fi
  fi
else
  echo "Invalid MODE: $MODE. Valid options are 'full-refresh' or 'incremental'."
  exit 1
fi

# Iterate over each file and send its content to the webhook
for file in $files_to_send; do
  if [ ! -f "$file" ]; then
    echo "The file $file does not exist or has been deleted."
    continue
  fi

  # Prepare the JSON payload by reading file content into jq
  payload=$(jq -Rs --arg fn "$file" '{filename: $fn, content: .}' "$file")

  # Write the payload to a temporary file
  tmpfile=$(mktemp /tmp/payload.XXXXXX)
  echo "$payload" > "$tmpfile"

  # Send the JSON content to the webhook and capture the response
  response=$(curl -s -w "\n%{http_code}" -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $WEBHOOK_KEY" -d @"$tmpfile" "$WEBHOOK_URL")
  rm "$tmpfile"
  
  http_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')

  # Check the response status code
  if [ "$http_code" -ne 200 ]; then
    echo "Failed to send data for $file to the webhook, server responded with status code: $http_code"
    echo "Response body: $body"
    exit 1
  else
    echo "Successfully sent data for $file to the webhook."
    echo "Response body: $body"
  fi
done

# Disable verbose output if it was enabled
if [ "$VERBOSE" = "true" ]; then
  set +x
fi
