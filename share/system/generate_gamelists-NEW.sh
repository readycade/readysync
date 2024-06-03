#!/bin/bash

# Function to escape special characters for XML
xml_escape() {
  echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'\''/\&apos;/g'
}

# Function to update or add games to the gamelist.xml
update_or_add_games() {
  local source_directory="$1"
  local gamelist_file="$2"
  local log_file="$3"

  # Check if source directory exists
  if [ ! -d "$source_directory" ]; then
    echo "ERROR: Source directory '$source_directory' does not exist." >> "$log_file"
    exit 1
  fi

  # Check if gamelist.xml already exists
  if [ -f "$gamelist_file" ]; then
    echo "INFO: Updating gamelist.xml in '$source_directory'" >> "$log_file"
  else
    echo "INFO: Creating gamelist.xml in '$source_directory'" >> "$log_file"
    echo "<gamelist>" > "$gamelist_file"  # Adding <gamelist> at the top
  fi

  # Iterate through all files in the source directory
  for rom_file in "$source_directory"/*; do
    if [ -f "$rom_file" ]; then
      rom_name=$(basename "$rom_file")
      game_name="${rom_name%.*}"  # Remove file extension to get game name

      # Check if the game already exists in gamelist.xml
      if grep -q "<name>$(xml_escape "$game_name")</name>" "$gamelist_file"; then
        # Update existing game entry
        echo "DEBUG: Updating existing entry for '$game_name' in '$gamelist_file'" >> "$log_file"
        sed -i "s|<name>$(xml_escape "$game_name")</name>|<name>$(xml_escape "$game_name")</name>|g" "$gamelist_file"
      else
        # Add new game entry
        echo "DEBUG: Adding new entry for '$game_name' in '$gamelist_file'" >> "$log_file"
        echo "  <game>" >> "$gamelist_file"
        echo "    <path>/recalbox/share/rom/No-Intro/$(xml_escape "$rom_name")</path>" >> "$gamelist_file"
        echo "    <name>$(xml_escape "$game_name")</name>" >> "$gamelist_file"
        echo "    <image>/recalbox/share/thumbs/Named_Titles/$(xml_escape "$game_name").png</image>" >> "$gamelist_file"
        echo "    <video>/recalbox/share/videos/$(xml_escape "$game_name").mp4</video>" >> "$gamelist_file"
        echo "  </game>" >> "$gamelist_file"
      fi
    fi
  done

  # Close gamelist.xml file
  if ! grep -q "</gamelist>" "$gamelist_file"; then
    echo "</gamelist>" >> "$gamelist_file"  # Adding </gamelist> at the bottom if it doesn't exist
  fi

  # Create or update MD5 checksum for gamelist.xml
  if [ ! -f "$gamelist_file.md5" ] || ! md5sum -c "$gamelist_file.md5" >/dev/null 2>&1; then
    md5sum "$gamelist_file" | sed "s|$source_directory/gamelist.xml| *gamelist.xml|" > "$gamelist_file.md5"
    echo "INFO: Gamelist.xml MD5 checksum created: '$gamelist_file.md5'" >> "$log_file"
  else
    echo "INFO: Gamelist.xml MD5 checksum matches existing checksum for '$source_directory'" >> "$log_file"
  fi
}

# Example usage:
source_directory="/recalbox/share/zip/amstradcpc"
gamelist_file="/recalbox/share/roms/readystream/amstradcpc/gamelist.xml"
log_file="/recalbox/share/roms/readystream/amstradcpc/gamelist.log"

mkdir -p "/recalbox/share/roms/readystream/amstradcpc/"
mkdir -p "/recalbox/share/zip/"

# httpdirfs -f -o debug -o auto_unmount --cache --cache-location=/recalbox/share/system/.cache/httpdirfs --dl-seg-size=1 --max-conns=20 #--retry-wait=1 -o nonempty "https://myrient.erista.me/files/" "/recalbox/share/rom/"

sleep 5

update_or_add_games "$source_directory" "$gamelist_file" "$log_file"
