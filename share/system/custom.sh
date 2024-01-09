#!/bin/bash
#set -x

## Author Michael Cabral 2024
## Title: Readystream
## Description: Mounts any FTP/HTTP repository of games using rclone giving you an Online and Offline experience.
## Online = FTP/HTTP Mounted Games
## Offline = Local Hard Drive Games

ln -s /usr/bin/fusermount /usr/bin/fusermount3
mount -o remount,rw /

log_file="/recalbox/share/system/.systemstream.log"

# Clear the log file
truncate -s 0 "$log_file"

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>"$log_file" 2>&1

# Function to sanitize directory names
sanitize_dir_name() {
  echo "$1" | tr -cd '[:alnum:]'
}

# Function to check if a game already exists in the gamelist.xml
game_exists() {
  local game_name="$1"
  local gamelist_file="$2"

  grep -q "<name>$game_name</name>" "$gamelist_file"
}

# Function to update or add a game to the gamelist.xml
update_or_add_game() {
  local game_name="$1"
  local rom_name="$2"
  local online_dir="$3"
  local gamelist_file="$online_dir/gamelist.xml"

  if game_exists "$game_name" "$gamelist_file"; then
    # Update existing game entry
    sed -i "s|<name>$game_name</name>|<name>$(xml_escape "$game_name")</name>|g" "$gamelist_file"
    sed -i "s|<path>./$rom_name</path>|<path>./$(xml_escape "$rom_name")</path>|g" "$gamelist_file"
    sed -i "s|<image>./media/images/$game_name.png</image>|<image>./media/images/$(xml_escape "$game_name").png</image>|g" "$gamelist_file"
    sed -i "s|<video>./media/videos/$game_name.mp4</video>|<video>./media/videos/$(xml_escape "$game_name").mp4</video>|g" "$gamelist_file"
  else
    # Add new game entry
    echo "  <game>" >> "$gamelist_file"
    echo "    <path>./$(xml_escape "$rom_name")</path>" >> "$gamelist_file"
    echo "    <name>$(xml_escape "$game_name")</name>" >> "$gamelist_file"
    echo "    <image>./media/images/$(xml_escape "$game_name").png</image>" >> "$gamelist_file"
    echo "    <video>./media/videos/$(xml_escape "$game_name").mp4</video>" >> "$gamelist_file"
    echo "  </game>" >> "$gamelist_file"
  fi
}

# Function to generate gamelist.xml
generate_gamelist_xml() {
  local console_directory="$1"
  local online_dir="$2"

  echo "<?xml version=\"1.0\"?>" > "$online_dir/gamelist.xml"
  echo "<gameList>" >> "$online_dir/gamelist.xml"

  for rom_file in "$console_directory"/*; do
    if [ -f "$rom_file" ]; then
      rom_name=$(basename "$rom_file")
      game_name="${rom_name%.*}"

      echo "  <game>" >> "$online_dir/gamelist.xml"
      echo "    <path>./$(echo "$rom_name" | sed 's/\&/\&amp;/g')</path>" >> "$online_dir/gamelist.xml"
      echo "    <name>$(echo "$game_name" | sed 's/\&/\&amp;/g')</name>" >> "$online_dir/gamelist.xml"

      # Add static image and video paths
      echo "    <image>./media/images/$(echo "$game_name" | sed 's/\&/\&amp;/g').png</image>" >> "$online_dir/gamelist.xml"
      echo "    <video>./media/videos/$(echo "$game_name" | sed 's/\&/\&amp;/g').mp4</video>" >> "$online_dir/gamelist.xml"

      echo "  </game>" >> "$online_dir/gamelist.xml"
    fi
  done

  echo "</gameList>" >> "$online_dir/gamelist.xml"
}

# Function to create console directory
create_console_directory() {
  local console_name="$1"
  mkdir -p "/recalbox/share/userscripts/.config/readystream/roms/$console_name"
}

# Use the previously defined console_name variable from create_console_directory
create_console_directory "$console_name"

# Set source and destination directories
source_dir="/recalbox/share/userscripts/.config/readystream/roms/$console_name"
dest_dir="/recalbox/share/roms/readystream/$console_name"

# Check if source directory exists
if [ -d "$source_dir" ]; then
  # Copy everything from source_dir to dest_dir without overwriting existing files
  cp -n "$source_dir/"* "$dest_dir/"
  echo "Copy completed successfully."
else
  echo "Source directory does not exist: $source_dir"
fi


# Function to perform actions specific to Online Mode
online_mode() {
    # Add your specific actions for Online Mode here
    # ...
    echo "Performing actions specific to Online Mode..."
}

# Function to perform actions specific to Offline Mode
offline_mode() {
    # Add your specific actions for Offline Mode here
    # ...
    echo "Performing actions specific to Offline Mode..."
}


# Detect architecture
case $(uname -m) in
  x86_64) sevenzip_arch="x64"; rclone_arch="amd64" ;;
  aarch64) sevenzip_arch="arm64"; rclone_arch="arm64" ;;
  *) echo "Unsupported architecture."; exit 1 ;;
esac

# Install 7zip
if [ ! -f /usr/bin/7za ]; then
  echo "Downloading and installing 7zip..."
  wget -O /usr/bin/7za https://github.com/develar/7zip-bin/raw/master/linux/${sevenzip_arch}/7za
  chmod +x /usr/bin/7za
  echo "7zip installed successfully."
else
  echo "7zip is already installed."
fi

# Install rclone
if [ ! -f /usr/bin/rclone ]; then
  echo "Downloading and installing rclone..."
  wget -O /usr/bin/rclone.zip https://downloads.rclone.org/v1.60.0/rclone-v1.60.0-linux-${rclone_arch}.zip
  7za e -y /usr/bin/rclone.zip
  mv rclone /usr/bin
  chmod +x /usr/bin/rclone
  rm /usr/bin/rclone.zip
  echo "rclone installed successfully."
else
  echo "rclone is already installed."
fi

# Install mount-zip
if [ ! -f /usr/bin/mount-zip ]; then
  echo "Copying mount-zip..."
  cp /recalbox/share/userscripts/.config/readystream/mount-zip /usr/bin/mount-zip
  chmod +x /usr/bin/mount-zip
  echo "mount-zip installed successfully."
else
  echo "mount-zip is already installed."
fi

# If directories don't exist, create them
if [ ! -d /recalbox/share/roms/readystream ]; then
    mkdir -p /recalbox/share/roms/readystream
    echo "Directory /recalbox/share/roms/readystream created successfully."
else
    echo "Directory /recalbox/share/roms/readystream already exists. No need to create."
fi

if [ ! -d /recalbox/share/rom ]; then
    mkdir -p /recalbox/share/rom
    echo "Directory /recalbox/share/rom created successfully."
else
    echo "Directory /recalbox/share/rom already exists. No need to create."
fi

if [ ! -d /recalbox/share/zip ]; then
    mkdir -p /recalbox/share/zip
    echo "Directory /recalbox/share/zip created successfully."
else
    echo "Directory /recalbox/share/zip already exists. No need to create."
fi

# If platforms.txt does not exist, copy it
if [ ! -e /recalbox/share/system/.config/platforms.txt ]; then
    cp /recalbox/share/userscripts/.config/readystream/platforms.txt /recalbox/share/system/.config/
    echo "platforms.txt copied successfully."
else
    echo "platforms.txt already exists. No need to copy."
fi

# If rclone.conf does not exist, copy it
if [ ! -e /recalbox/share/system/rclone.conf ]; then
    cp /recalbox/share/userscripts/.config/readystream/rclone.conf /recalbox/share/system/
    echo "rclone.conf copied successfully."
else
    echo "rclone.conf already exists. No need to copy."
fi

# Display menu
echo "Please select a mode:"
echo "1. Online Mode"
echo "2. Offline Mode"

# Capture input with timeout
timeout_seconds=5
read -t "$timeout_seconds" -r input || mode_choice="1"

# Determine the mode based on user input or timeout
case "$mode_choice" in
    "1")
		# Online Mode
        online_mode
        ;;
    "2")
        # Offline Mode
        offline_mode
        ;;
    *)
        echo "Invalid choice: $mode_choice"
        ;;
esac

# Check and update systemlist.xml based on user choice
offline_systemlist="/recalbox/share_init/system/.emulationstation/systemlist.xml"
offline_backup="/recalbox/share/userscripts/.config/.emulationstation/systemlist-backup.xml"
offline_online="/recalbox/share/userscripts/.config/.emulationstation/systemlist-online.xml"
offline_offline="/recalbox/share/userscripts/.config/.emulationstation/systemlist-offline.xml"

# Online Mode
if [ "$mode_choice" = "1" ]; then

    # Mount rclone using the provided command
    echo "Mounting rclone..."
    # Replace the following line with the actual rclone mount command
    rclone mount myrient: /recalbox/share/rom --config=/recalbox/share/system/rclone.conf --daemon --allow-non-empty --http-no-head

    # Online Mode
    if [ -f "$offline_systemlist" ] && [ -f "$offline_online" ]; then
        # Backup the existing systemlist.xml
        echo "Backing up systemlist.xml..."
        cp "$offline_systemlist" "$offline_backup"
        echo "Backup created: $offline_backup"

        # Overwrite systemlist.xml with the online version
        echo "Overwriting systemlist.xml with the online version..."
        cp "$offline_online" "$offline_systemlist"
        echo "Online version applied."

        # Process the platforms.txt file
        while IFS= read -r roms_entry; do
            console_name=$(echo "$roms_entry" | cut -d ';' -f 1)
            source_directory=$(echo "$roms_entry" | cut -d ';' -f 2)
            target_directory=$(echo "$roms_entry" | cut -d ';' -f 5)

            # Create hard links
            for rom_file in "$source_directory"/*; do
                if [ -f "$rom_file" ]; then
                    rom_name=$(basename "$rom_file")
                    target_path="$target_directory/$rom_name"

                    # Use ln to create hard links
                    ln "$rom_file" "$target_path"
                    echo "Created hard link: $target_path"
                fi
            done
        done < "$offline_online"

    else
        echo "Error: systemlist.xml files not found."
    fi

fi  # Add this line to close the first if block

# Offline Mode
if [ "$mode_choice" != "1" ]; then
    if [ -f "$offline_systemlist" ] && [ -f "$offline_offline" ]; then
        # Backup existing systemlist.xml
        echo "Backing up systemlist.xml..."
        cp "$offline_systemlist" "$offline_backup"
        echo "Backup created: $offline_backup"

        # Overwrite systemlist.xml with offline version
        echo "Overwriting systemlist.xml with offline version..."
        cp "$offline_offline" "$offline_systemlist"
        echo "Offline version applied."

        # Replace the following line with your specific actions for Offline Mode
        echo "Performing actions specific to Offline Mode..."
        # ...

        echo "Installation complete. Log saved to: $log_file"

        # Replace the following line with the actual command to start emulation station
        chvt 1; es start
    else
        echo "Error: systemlist.xml files not found."
    fi
fi

exit
