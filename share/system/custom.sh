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

sanitize_dir_name() {
  tr -cd '[:alnum:]' <<< "$1"
}


# Function to check if a game already exists in the gamelist.xml
game_exists() {
  local game_name="$1"
  local gamelist_file="$2"

  if grep -q "<name>$game_name</name>" "$gamelist_file"; then
    echo "DEBUG: Game '$game_name' exists in '$gamelist_file'" >> "$log_file"
    return 0  # Game exists
  else
    echo "DEBUG: Game '$game_name' does not exist in '$gamelist_file'" >> "$log_file"
    return 1  # Game does not exist
  fi
}

# Function to escape special characters for XML
xml_escape() {
  echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'\''/\&apos;/g'
}

# Function to update or add a game to the gamelist.xml
update_or_add_game() {
  local game_name="$1"
  local rom_name="$2"
  console_name_escaped=$(xml_escape "$console_name")
  local console_name="$3"
  local platform_name="$4"  # Add platform_name as an argument
  local gamelist_file="/recalbox/share/roms/readystream/$console_name/gamelist.xml"

  if game_exists "$game_name" "$gamelist_file"; then
    # Update existing game entry
    echo "DEBUG: Updating existing entry for '$game_name' in '$gamelist_file'" >> "$log_file"
    sed -i "s|<name>$game_name</name>|<name>$(xml_escape "$game_name")</name>|g" "$gamelist_file"
    sed -i "s|<path>./$rom_name</path>|<path>./$(xml_escape "$rom_name")</path>|g" "$gamelist_file"
    sed -i "s|<video>./media/videos/$game_name.mp4</video>|<video>./media/videos/$(xml_escape "$game_name").mp4</video>|g" "$gamelist_file"
  else
    # Add new game entry
    echo "DEBUG: Adding new entry for '$game_name' in '$gamelist_file'" >> "$log_file"
    echo "  <game>" >> "$gamelist_file"
    echo "    <path>./$(xml_escape "$rom_name")</path>" >> "$gamelist_file"
    echo "    <name>$(xml_escape "$game_name")</name>" >> "$gamelist_file"
    echo "    <video>./media/videos/$(xml_escape "$game_name").mp4</video>" >> "$gamelist_file"
    echo "    <image>/recalbox/share/thumbs/$platform_name/Named_Titles/$(xml_escape "$game_name").png</image>" | sed 's#//#/#g' >> "$gamelist_file"
    echo "  </game>" >> "$gamelist_file"
  fi
}



# Function to generate gamelist.xml
generate_gamelist_xml() {
  local online_dir="$1"
  local platforms_file="/recalbox/share/userscripts/.config/readystream/platforms.txt"

  for console_name_dir in "$online_dir"/*; do
    if [ -d "$console_name_dir" ]; then
      console_name=$(sanitize_dir_name "$(basename "$console_name_dir")")
echo "DEBUG: Console name extracted: '$console_name'" >> "$log_file"

      local console_roms_dir="/recalbox/share/roms/readystream/$console_name"
echo "DEBUG: Console ROMs directory: '$console_roms_dir'" >> "$log_file"

      local gamelist_file="$console_roms_dir/gamelist.xml"

      local log_file="/recalbox/share/roms/readystream/gamelist.log"  # Replace with the actual path to your log file

      # Check if gamelist.xml already exists
      if [ ! -f "$gamelist_file" ]; then
        echo "INFO: Generating gamelist.xml for '$console_name'" >> "$log_file"

        # Create gamelist.xml
        echo "<?xml version=\"1.0\"?>" > "$gamelist_file"
        echo "<gameList>" >> "$gamelist_file"

        # Get the platform name from platforms.txt
        platform_name=$(grep "^$console_name;" "$platforms_file" | cut -d';' -f4)

        # Iterate through rom files
        for rom_file in "$console_roms_dir"/*; do
          if [ -f "$rom_file" ]; then
            rom_name=$(basename "$rom_file")
            game_name="${rom_name%.*}"

            update_or_add_game "$game_name" "$rom_name" "$console_name" "$platform_name"
          fi
        done

        echo "</gameList>" >> "$gamelist_file"

        # Check if MD5 exists and matches, if not, create MD5 checksum for gamelist.xml
        if [ ! -f "$gamelist_file.md5" ] || ! md5sum -c --status "$gamelist_file.md5"; then
          md5sum "$gamelist_file" | sed "s|/recalbox/share/roms/readystream/$console_name/gamelist.xml| *gamelist.xml|" > "$gamelist_file.md5"
          echo "INFO: Gamelist.xml MD5 checksum created: '$gamelist_file.md5'" >> "$log_file"
        else
          echo "INFO: Gamelist.xml MD5 checksum matches existing checksum for '$console_name'" >> "$log_file"
        fi
      else
        echo "INFO: Gamelist.xml already exists for '$console_name'" >> "$log_file"
      fi
    fi
  done
}


# Call the function with the online directory as an argument
generate_gamelist_xml "/recalbox/share/roms/readystream"

# Function to create console directory
create_console_directory() {
  local console_name="$1"
  console_name="${console_name//\/}"  # This removes trailing slashes
  mkdir -p "/recalbox/share/userscripts/.config/readystream/roms/$console_name"
  mkdir -p "/recalbox/share/roms/readystream/$console_name"
}

# Extract console names from platforms.txt using awk
console_names=$(awk -F';' '/^roms\+=/{gsub(/roms\+=\("/, ""); gsub(/".*/, ""); print $1}' /recalbox/share/userscripts/.config/readystream/platforms.txt)

# Display extracted console names for debugging
echo "Console names extracted from platforms.txt: '$console_names'"

# Loop through extracted console names and create directories
IFS=$'\n'  # Set Internal Field Separator to newline to handle multiple console names
for console_name in $console_names; do
  # Use the extracted console name to create the console directory
  create_console_directory "$console_name"

  # Set source and destination directories
  source_dir="/recalbox/share/userscripts/.config/readystream/roms/$console_name"
  dest_dir="/recalbox/share/roms/readystream/$console_name"

  # Display source directory for debugging
  echo "Source directory: '$source_dir'"

  # Check if source directory exists
  if [ -d "$source_dir" ]; then
    # Copy everything from source_dir to dest_dir without overwriting existing files
    cp -n "$source_dir"/* "$dest_dir/"
    echo "Copy completed successfully for '$console_name'."
  else
    echo "Source directory does not exist for '$console_name': $source_dir"
  fi
done


# Function to perform actions specific to Online Mode
online_mode() {
    # Add your specific actions for Online Mode here
    # ...
    echo "Performing actions specific to Online Mode..."

# Check and update systemlist.xml based on user choice
offline_systemlist="/recalbox/share_init/system/.emulationstation/systemlist.xml"
offline_backup="/recalbox/share/userscripts/.config/.emulationstation/systemlist-backup.xml"
offline_online="/recalbox/share/userscripts/.config/.emulationstation/systemlist-online.xml"
offline_offline="/recalbox/share/userscripts/.config/.emulationstation/systemlist-offline.xml"

# Online Mode
if [ -f "$offline_systemlist" ] && [ -f "$offline_online" ]; then
    # Mount rclone using the provided command
	rclone mount thumbnails: /recalbox/share/thumbs --config=/recalbox/share/system/rclone.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h &
	disown

	# Backup the existing systemlist.xml
    echo "Backing up systemlist.xml..."
    cp "$offline_systemlist" "$offline_backup"
    echo "Backup created: $offline_backup"

    # Overwrite systemlist.xml with the online version
    echo "Overwriting systemlist.xml with the online version..."
    cp "$offline_online" "$offline_systemlist"
    echo "Online version applied."
fi

# Read the roms array from platforms.txt
platforms_file="/recalbox/share/userscripts/.config/readystream/platforms.txt"
mapfile -t roms < "$platforms_file"


# Loop through the roms array
for rom_entry in "${roms[@]}"; do
    # Remove roms+=(" from the beginning of the entry
    rom_entry="${rom_entry#roms+=(\"}"

    # Split the entry into components
    IFS=';' read -r -a rom_data <<< "$rom_entry"

    # Extract console name (first name in the array)
    console_name="${rom_data[0]}"

    # Extract console directory
    console_directory="${rom_data[1]}"

    # Check if the platform is enabled
    if grep -q "^roms+=(\"$console_name;" "/recalbox/share/userscripts/.config/readystream/platforms.txt"; then
        # Create the source and destination paths
        source_path="rsync://rsync.myrient.erista.me/files/$console_directory"
        destination_path="/recalbox/share/roms/readystream/$console_name"

        # Create the destination directory if it doesn't exist
        mkdir -p "$destination_path"

        # Use rsync to create hard link backups
        rsync -aP --link-dest="$destination_path" "$source_path/" "$destination_path/"
    fi
done
}

# Function to perform actions specific to Offline Mode
offline_mode() {
    # Add your specific actions for Offline Mode here
    # ...
    echo "Performing actions specific to Offline Mode..."
	
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
  wget -O /usr/bin/rclone.zip https://downloads.rclone.org/v1.65.0/rclone-v1.65.0-linux-${rclone_arch}.zip
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

if [ ! -d /recalbox/share/thumbs ]; then
    mkdir -p /recalbox/share/thumbs
    echo "Directory /recalbox/share/thumbs created successfully."
else
    echo "Directory /recalbox/share/thumbs already exists. No need to create."
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

# Function to delete the directory of a disabled platform
delete_disabled_platform_directory() {
  local platform_name="$1"
  local directory="/recalbox/share/roms/readystream/$platform_name"

  if [ -d "$directory" ]; then
    echo "Deleting directory for disabled platform: $platform_name"
    rm -rf "$directory"
  else
    echo "Directory for disabled platform does not exist: $directory"
  fi
}

# Function to toggle a platform in the array
toggle_platform() {
    local platform_name=$1
    local action=$2

    case $action in
        "enable")
            sed -i "/^#roms+=(\"$platform_name;/ s/^#//" "/recalbox/share/userscripts/.config/readystream/platforms.txt"
            ;;
        "disable")
            sed -i "/^roms+=(\"$platform_name;/ s/^/#/" "/recalbox/share/userscripts/.config/readystream/platforms.txt"
            ;;
        *)
            echo "Invalid action. Use 'enable' or 'disable'."
            ;;
    esac
}

# List of platforms and their status (1 for enabled, 0 for disabled)
platforms=(
    "arduboy 1"
    "channelf 1"
    "vectrex 1"
    "o2em 1"
    "videopacplus 1"
    "intellivision 1"
    "colecovision 1"
    "scv 1"
    "supervision 1"
    "wswan 1"
    "wswanc 1"
    "atari2600 1"
    "atari5200 1"
    "atari7800 1"
    "jaguar 0"
    "lynx 0"
    "nes 0"
    "fds 0"
    "snes 0"
    "satellaview 0"
    "sufami 0"
    "n64 0"
    "gamecube 0"
    "wii 0"
    "pokemini 0"
    "virtualboy 0"
    "gb 0"
    "gbc 0"
    "gba 0"
    "nds 0"
    "3ds 0"
    "sg1000 0"
    "mastersystem 0"
    "megadrive 0"
    "pico 0"
    "sega32x 0"
    "segacd 0"
    "saturn 0"
    "dreamcast 0"
    "gamegear 0"
    "psx 0"
    "ps2 0"
    "psp 0"
    "pcengine 0"
    "pcenginecd 0"
    "supergrafx 0"
    "pcfx 0"
    "cdi 0"
    "3do 0"
    "neogeocd 0"
    "ngp 0"
    "ngpc 0"
    "dos 0"
    "msx1 0"
    "msx2 0"
    "atarist 0"
    "amiga1200 0"
    "amigacd32 0"
    "amigacdtv 0"
    "cplus4 0"
    "vic20 0"
    "c64 0"
    # Zip Array
    "pet 0"
    "pc88 0"
    "pc98 0"
    "x1 0"
    "x68000 0"
    "atari800 0"
    "amstradcpc 0"
    "zx81 0"
    "zxspectrum 0"
    "spectravideo 0"
    # Add more platforms as needed
)

# Loop through platforms
for platform_info in "${platforms[@]}"; do
    platform_name=$(echo "$platform_info" | cut -d ' ' -f 1)
    platform_status=$(echo "$platform_info" | cut -d ' ' -f 2)

    case $platform_status in
        1)
            toggle_platform "$platform_name" "enable"
            ;;
        0)
            toggle_platform "$platform_name" "disable"
            delete_disabled_platform_directory "$platform_name"
            ;;
        *)
            echo "Invalid status. Use '1' for enable and '0' for disable."
            ;;
    esac
done


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

exit
