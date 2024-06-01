#!/bin/sh

# Define paths to the AppImage and the directories
APPIMAGE_PATH="/usr/bin/ratarmount"
EXTRACTED_DIR="/usr/bin/squashfs-root"

# Ensure the AppImage is executable
chmod +x "$APPIMAGE_PATH"

# Extract the AppImage if it hasn't been extracted already
if [ ! -d "$EXTRACTED_DIR" ]; then
  "$APPIMAGE_PATH" --appimage-extract
fi

# Change directory to the extracted AppImage contents
cd "$EXTRACTED_DIR" || exit

# Set up environment variables to use the system's Python
export PYTHONHOME=/usr
export PYTHONPATH=/usr/lib/python3/dist-packages:/usr/lib/python3.12/site-packages
export PATH=/usr/bin:$PATH

# Run the application with provided arguments
/usr/bin/python3 ./opt/python3.12/bin/ratarmount "$@"