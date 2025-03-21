#!/bin/bash

# Exit on any error
set -e

# Default ZIP file path if not provided
DEFAULT_ZIP_PATH="artifactory/libs-release-local/hsm/client.zip"
zip_path="${hsm_zip_file_path:-$DEFAULT_ZIP_PATH}"

# Check if necessary variables are set
if [ -z "$artifactory_url_env" ]; then
  echo "Error: 'artifactory_url_env' is not set!"
  exit 1
fi

if [ -z "$hsm_local_dir_name" ]; then
  echo "Error: 'hsm_local_dir_name' is not set!"
  exit 1
fi

if [ -z "$work_dir" ]; then
  echo "Error: 'work_dir' is not set!"
  exit 1
fi

echo "Downloading HSM client from $artifactory_url_env"
echo "Zip File Path: $zip_path"

# Download the client ZIP file
wget -q --show-progress --tries=3 --timeout=10 "$artifactory_url_env/$zip_path" -O client.zip || {
  echo "Error: Failed to download client.zip"
  exit 1
}

echo "Downloaded successfully"

FILE_NAME="client.zip"
DIR_NAME="$hsm_local_dir_name"

# Check if the zip contains a parent directory
has_parent=$(unzip -l "$FILE_NAME" | awk '{print $4}' | awk -F '/' '{print $1}' | sort -u | grep -v "^$" | wc -l)

if [ "$has_parent" -eq 1 ]; then
  dirname=$(unzip -l "$FILE_NAME" | awk '{print $4}' | awk -F '/' '{print $1}' | sort -u | grep -v "^$" | head -n 1)
  echo "Zip has a parent directory: $dirname"
  unzip -o "$FILE_NAME"
  mv -v "$dirname" "$DIR_NAME"
else
  echo "Zip has no parent directory, extracting directly."
  mkdir -p "$DIR_NAME"
  unzip -o -d "$DIR_NAME" "$FILE_NAME"
fi

# Navigate to installation directory
cd "$DIR_NAME" || {
  echo "Error: Failed to change directory to $DIR_NAME"
  exit 1
}

# Verify directory contents
echo "Current Directory: $(pwd)"
ls -la

# Check if install.sh exists
if [ ! -f "install.sh" ]; then
  echo "Error: install.sh not found!"
  exit 1
fi

# Ensure install.sh is executable and convert line endings if necessary
chmod +x install.sh
sed -i 's/\r$//' install.sh

# Run the installation script
echo "Running installation script..."
bash install.sh || {
  echo "Error: Installation failed"
  exit 1
}

echo "Installation complete."

# Return to working directory
cd "$work_dir" || exit 1

exec "$@"
