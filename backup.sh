#!/bin/bash

# Prompt the user for the directory to be backed up
echo "Enter the directory to be backed up: "
read directory

# Get the current date
date=$(date +%F)

# Set the filename for the backup
filename="${directory}_${date}.tar.gz"

# Create the backup
tar -czvf "$filename" "$directory"

echo "Backup created: $filename"
