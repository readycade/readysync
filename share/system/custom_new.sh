#!/bin/bash
#set -x

## Author Michael Cabral 2024
## Title: Readystream
## GPL-3.0 license
## Description: Downloads or Mounts any HTTP repository of games using httpdirfs, wget, mount-zip, rclone, jq and 7-zip giving you an Online and Offline experience.
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
    local console_name="$3"
    local gamelist_file="/recalbox/share/roms/readystream/$console_name/gamelist.xml"

    local platform_name=$(grep -w "$console_name" "$platforms_file" | cut -d';' -f3 | sed 's/^<p>//;s/<\/p>$//')

    if [ -n "$platform_name" ]; then
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
    else
        echo "ERROR: Failed to extract platform name for '$console_name'"
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
    # Exclude gamelist.xml and gamelist.xml.md5
    if [ "$(basename "$rom_file")" != "gamelist.xml" ] && [ "$(basename "$rom_file")" != "gamelist.xml.md5" ]; then
      rom_name=$(basename "$rom_file")
      game_name="${rom_name%.*}"

      update_or_add_game "$game_name" "$rom_name" "$console_name" "$platform_name"
    fi
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
#disown

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

# Specify the temporary destination path for zip files
destination_path_zip_temp="/recalbox/share/zip"

# Loop through the roms array for normal files
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
        # Create the source and destination paths for normal files
        #source_path="rsync://rsync.myrient.erista.me/files/$console_directory"
        source_path="http://myrient.erista.me/files/$console_directory"
        destination_path="/recalbox/share/roms/readystream/$console_name"

        # Create the destination directory if it doesn't exist
        mkdir -p "$destination_path"

        # Use rsync to download normal files
        #rsync -aP --delete --link-dest="$destination_path" "$source_path/" "$destination_path/"

        # Use httpdirfs to mount normal files (got to test this still)
        #mount -t httpdirfs "$source_path/" "$destination_path/"

        # httpdirfs with caching to mount normal files (got to test this still)
        #httpdirfs --cache --no-range-check --cache-location ~/share/system/.cache/httpdirfs https://myrient.erista.me/files ~/myrient

        # httpdirfs with caching to mount normal files (got to test this still)
        mkdir -p /recalbox/share/system/.cache/httpdirfs
        httpdirfs --cache --no-range-check --cache-location /recalbox/share/system/.cache/httpdirfs "$source_path/" "$destination_path/"
        #httpdirfs --cache --no-range-check --debug --cache-location  /recalbox/share/system/.cache/httpdirfs "http://myrient.erista.me/files/" "/recalbox/share/roms/readystream/"
    fi
done

# Loop through the roms array for zip files
for rom_entry in "${roms[@]}"; do
    # Remove roms+=(" from the beginning of the entry
    rom_entry="${rom_entry#roms+=(\"}"

    # Split the entry into components
    IFS=';' read -r -a rom_data <<< "$rom_entry"

    # Extract console name (first name in the array)
    console_name="${rom_data[0]}"

    # Extract console directory for zip
    console_directory_zip="${rom_data[1]}"

    # Check if the platform is enabled
    if grep -q "^roms+=(\"$console_name;" "/recalbox/share/userscripts/.config/readystream/platforms.txt"; then
        # Create the source and destination paths for zip files
        source_path_zip="http://myrient.erista.me/files/$console_directory_zip"
        source_path_zip_http="http://myrient.erista.me/files/$console_directory_zip"

        # Correct the destination_path_zip to remove the trailing slash
        destination_path_zip="/recalbox/share/zip"

        # Create the destination directory if it doesn't exist
        mkdir -p "$destination_path_zip/$console_name"

        # Extract the filename from the URL
        filename=$(basename "$console_directory_zip")

        # Use curl to download zip files with a unique name
        #curl -u "anonymous:myUcMnWBKX9R-Gya--f8j0K26zYNvaWCqyqL" -o "$destination_path_zip/$console_name/$filename" "$source_path_zip_http/$console_directory_zip"

        # Use unzip to extract the contents of the ZIP file
        #unzip -o -u "$destination_path_zip/$console_name/$filename" -d "/recalbox/share/roms/readystream/$console_name"

        # I think this is the GOOD ONE (copied from unzip)
        mount-zip "$destination_path_zip/$console_name/$filename" "/recalbox/share/roms/readystream/$console_name"

        # Fix the bad regex in the debug output
        echo "Fixed regex for console: $console_name"
        grep -E "^<name>$(echo "$console_name" | sed 's/[][()\.^$?*+|{}\\]/\\&/g')</name>" "$console_directory_zip"
    fi
done





}

# Function to perform actions specific to Offline Mode
offline_mode() {
    # Add your specific actions for Offline Mode here
    # ...
    echo "Performing actions specific to Offline Mode..."

# Check and update systemlist.xml based on user choice
offline_systemlist="/recalbox/share_init/system/.emulationstation/systemlist.xml"
offline_backup="/recalbox/share/userscripts/.config/.emulationstation/systemlist-backup.xml"
offline_online="/recalbox/share/userscripts/.config/.emulationstation/systemlist-online.xml"
offline_offline="/recalbox/share/userscripts/.config/.emulationstation/systemlist-offline.xml"
	
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
#        chvt 1; es start
    else
        echo "Error: systemlist.xml files not found."
    fi
fi	
	
}

# Detect architecture
case $(uname -m) in
  x86_64) sevenzip_arch="x64"; rclone_arch="amd64"; mount_zip_arch="x64" ;;
  aarch64) sevenzip_arch="arm64"; rclone_arch="arm64"; mount_zip_arch="arm64" ;;
  *) echo "Unsupported architecture."; exit 1 ;;
esac

# Download and Install 7zip
if [ ! -f /usr/bin/7za ]; then
  echo "Downloading and installing 7zip..."
  wget -O /usr/bin/7za https://github.com/develar/7zip-bin/raw/master/linux/${sevenzip_arch}/7za
  chmod +x /usr/bin/7za
  echo "7zip installed successfully."
else
  echo "7zip is already installed."
fi

# Download and Install rclone
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

# Download and Install jq 1.7.1
if [ ! -f /usr/bin/jq ]; then
  echo "Downloading jq 1.7.1..."

  # Detect the architecture
  case $(arch) in
    x86_64) jq_arch="amd64" ;;
    aarch64) jq_arch="arm64" ;;
    *) echo "Unsupported jq architecture: $(arch)."; exit 1 ;;
  esac

  jq_url="https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-${jq_arch}"

  # Download and Install jq
  wget -O /usr/bin/jq ${jq_url}
  chmod +x /usr/bin/jq

  echo "jq 1.7.1 installed successfully for architecture: ${jq_arch}."
else
  echo "jq 1.7.1 is already installed."
fi

# Download and Install mount-zip
if [ ! -f /usr/bin/mount-zip ]; then
  echo "Downloading mount-zip..."

  # Detect the architecture
  case $(arch) in
    x86_64) mount_zip_arch="x64" ;;
    aarch64) mount_zip_arch="arm64" ;;
    *) echo "Unsupported mount-zip architecture: $(arch)."; exit 1 ;;
  esac

  mount_zip_url="https://github.com/readycade/readysync/raw/master/share/userscripts/.config/readystream/mount-zip-${mount_zip_arch}/mount-zip"

  # Download and Install mount-zip
  wget -O /usr/bin/mount-zip ${mount_zip_url}
  chmod +x /usr/bin/mount-zip

  echo "mount-zip installed successfully for architecture: ${mount_zip_arch}."
else
  echo "mount-zip is already installed."
fi

# Download and Install httpdirfs
if [ ! -f /usr/bin/httpdirfs ]; then
  echo "Downloading httpdirfs..."

  # Detect the architecture
  case $(arch) in
    x86_64) httpdirfs_arch="x64" ;;
    aarch64) httpdirfs_arch="arm64" ;;
    *) echo "Unsupported httpdirfs architecture: $(arch)."; exit 1 ;;
  esac

  httpdirfs_url="https://github.com/readycade/readysync/raw/master/share/userscripts/.config/readystream/httpdirfs-${httpdirfs_arch}/httpdirfs"

  # Download and Install httpdirfs
  wget -O /usr/bin/httpdirfs ${httpdirfs_url}
  chmod +x /usr/bin/httpdirfs

  echo "httpdirfs installed successfully for architecture: ${httpdirfs_arch}."
else
  echo "httpdirfs is already installed."
fi

# Download rclone.conf if it doesn't exist
if [ ! -e /recalbox/share/userscripts/.config/readystream/rclone.conf ]; then
    wget -O /recalbox/share/userscripts/.config/readystream/rclone.conf https://raw.githubusercontent.com/readycade/readysync/master/share/userscripts/.config/readystream/rclone.conf
    echo "rclone.conf downloaded to /recalbox/share/userscripts/.config/readystream/ successfully."
fi

# Copy rclone.conf to /recalbox/share/system/ if it doesn't exist there
if [ ! -e /recalbox/share/system/rclone.conf ]; then
    cp /recalbox/share/userscripts/.config/readystream/rclone.conf /recalbox/share/system/
    echo "rclone.conf copied to /recalbox/share/system/ successfully."
else
    echo "rclone.conf already exists in /recalbox/share/system/. No need to copy."
fi

# Download platforms.txt if it doesn't exist in /recalbox/share/userscripts/.config/readystream/
if [ ! -e /recalbox/share/userscripts/.config/readystream/platforms.txt ]; then
    wget -O /recalbox/share/userscripts/.config/readystream/platforms.txt https://raw.githubusercontent.com/readycade/readysync/master/share/userscripts/.config/readystream/platforms.txt
    echo "platforms.txt downloaded to /recalbox/share/userscripts/.config/readystream/ successfully."
fi

# Check if files already exist in /recalbox/share/userscripts/.config/.emulationstation/
if [ -e /recalbox/share/userscripts/.config/.emulationstation/systemlist-backup.xml ] && \
   [ -e /recalbox/share/userscripts/.config/.emulationstation/systemlist-online.xml ] && \
   [ -e /recalbox/share/userscripts/.config/.emulationstation/systemlist-offline.xml ]; then
    echo "Files already exist. No need to download."
else
    # Download systemlist-backup.xml
    wget -O /recalbox/share/userscripts/.config/.emulationstation/systemlist-backup.xml https://raw.githubusercontent.com/readycade/readysync/master/share/userscripts/.config/.emulationstation/systemlist-backup.xml

    # Download systemlist-online.xml
    wget -O /recalbox/share/userscripts/.config/.emulationstation/systemlist-online.xml https://raw.githubusercontent.com/readycade/readysync/master/share/userscripts/.config/.emulationstation/systemlist-online.xml

    # Download systemlist-offline.xml
    wget -O /recalbox/share/userscripts/.config/.emulationstation/systemlist-offline.xml https://raw.githubusercontent.com/readycade/readysync/master/share/userscripts/.config/.emulationstation/systemlist-offline.xml

    # Check if files were downloaded successfully
    if [ -e /recalbox/share/userscripts/.config/.emulationstation/systemlist-backup.xml ] && \
       [ -e /recalbox/share/userscripts/.config/.emulationstation/systemlist-online.xml ] && \
       [ -e /recalbox/share/userscripts/.config/.emulationstation/systemlist-offline.xml ]; then
        echo "Files downloaded successfully."
    else
        echo "Failed to download one or more files."
    fi
fi

# Check if /recalbox/share/userscripts/.config/readystream/roms is empty
if [ -z "$(ls -A /recalbox/share/userscripts/.config/readystream/roms)" ]; then
    echo "Downloading gamelist.xml and checksums for ALL Consoles..."
    wget --recursive --no-parent -P /recalbox/share/userscripts/.config/readystream/roms https://github.com/readycade/readysync/tree/master/share/userscripts/.config/readystream/roms
    echo "gamelist.xml and checksums downloaded successfully."
else
    echo "gamelist.xml and checksums directory is not empty. No need to download."
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

if [ ! -d /iso ]; then
    mkdir -p /iso
    echo "Directory /iso created successfully."
else
    echo "Directory /iso already exists. No need to create."
fi

if [ ! -d /recalbox/share/zip ]; then
    mkdir -p /recalbox/share/zip
    echo "Directory /recalbox/share/zip created successfully."
else
    echo "Directory /recalbox/share/zip already exists. No need to create."
fi

delete_disabled_platform_directory() {
  local platform_name="$1"
  local roms_directory="/recalbox/share/roms/readystream/$platform_name"
  local zip_directory="/recalbox/share/zip/$platform_name"

  # Delete ROMs directory
  if [ -d "$roms_directory" ]; then
    echo "Deleting ROMs directory for disabled platform: $platform_name"
    rm -rf "$roms_directory"
  else
    echo "ROMs directory for disabled platform does not exist: $roms_directory"
  fi

  # Delete ZIP directory
  if [ -d "$zip_directory" ]; then
    echo "Deleting ZIP directory for disabled platform: $platform_name"
    rm -rf "$zip_directory"
  else
    echo "ZIP directory for disabled platform does not exist: $zip_directory"
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
    # No-Intro Romsets
    "arduboy 0"
    "atari2600 0"
    "atari5200 0"
    "atari7800 0"
    "atarist 0"
    "jaguar 0"
    "lynx 0"
    "wswan 0"
    "wswanc 0"
    "colecovision 0"
    "c64 0"
    "cplus4 0"
    "vic20 0"
    "scv 0"
    "channelf 0"
    "vectrex 0"
    "o2em 0"
    "intellivision 0"
    "msx1 0"
    "msx2 0"
    "pcengine 0"
    "supergrafx 0"
    "fds 0"
    "gb 0"
    "gbc 0"
    "gba 0"
    "n64 0"
    "nes 0"
    "pokemini 0"
    "satellaview 0"
    "sufami 0"
    "snes 0"
    "virtualboy 0"
    "videopacplus 0"
    "ngp 0"
    "ngpc 0"
    "sega32x 0"
    "gamegear 0"
    "sg1000 0"
    "mastersystem 0"
    "megadrive 0"
    "pico 0"
    "supervision 0"
    "pcv2 0"
    "palm 0"
    "gw 0"
    "64dd 0"
    "nds 0"
    # Redump Romsets (CD/DVD BASED) (WARNING: these are VERY large!)
    "amigacd32 0"
    "amigacdtv 0"
    "amiga1200 0"
    "gamecube 0"
    "wii 0"
    "3do 0"
    "cdi 0"
    "pcenginecd 0"
    "neogeocd 0"
    "dreamcast 0"
    "segacd 0"
    "saturn 0"
    "psx 0"
    "ps2 0"
    "psp 0"
    "pcfx 0"
    "naomi 0"
    "jaguar 0"
    # TOSEC Romsets
    "amstradcpc 0"
    "atari800 0"
    "pet 0"
    "pc88 0"
    "pc98 0"
    "pcengine 0"
    "zxspectrum 0"
    "zx81 0"
    "x1 0"
    "x68000 0"
    "gx4000 0"
    "macintosh 0"
    "apple2gs 0"
    "apple2 0"
    "amiga1200 0"
    "bk 0"
    "msx1 0"
    # MSX 2
    "msx2 0"
    # MSX 2+
    "msx2 0"
    "msxturbor 0"
    # The EYE Romsets
    "dos 0"
    # Add more platforms as needed
)

    # Experimental (DO NOT USE)
    #"analogue 0"
    #"triforce 0"
    #"amiga1200 0"
    
    # No Intro Experimental (DO NO USE)
    # New Nintendo 3DS
    #"3ds 0"
    # Nintendo 3DS
    #"3ds 0"

    # Redump Experimental (DO NOT USE)
    #"naomi 0"
    #"xbox 0"
    #"xbox360 0"
    #"ps3 0"
    #"ps3keys 0"
    #"ps3keystxt 0"


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

chvt 1; es start

exit
