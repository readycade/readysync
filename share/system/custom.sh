#!/bin/bash
#set -x

## Author Michael Cabral 2024
## Title: Readystream
## GPL-3.0 license
## Description: Downloads or Mounts any HTTP repository of games using httpdirfs, wget, mount-zip, rclone, and 7-zip giving you an Online and Offline experience.
## Online = HTTP/FTP Mounted Games
## Offline = Local Hard Drive Games

ln -s /usr/bin/fusermount /usr/bin/fusermount3
mount -o remount,rw /
echo "mount and unmount as read-write..."

log_file="/recalbox/share/system/.systemstream.log"

# Clear the log file
truncate -s 0 "$log_file"
echo "Log file:..."
echo "/recalbox/share/system/.systemstream.log"
echo "Truncating log file..."


exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>"$log_file" 2>&1

sanitize_dir_name() {
  tr -cd '[:alnum:]' <<< "$1"
}

# Function to perform actions specific to Online Mode
online_mode() {
    # Add your specific actions for Online Mode here
    # ...
    echo "Online Mode Enabled..."
    echo "Performing actions specific to Online Mode..."

# Check and update systemlist.xml based on user choice
offline_systemlist="/recalbox/share_init/system/.emulationstation/systemlist.xml"
offline_backup="/recalbox/share/userscripts/.config/.emulationstation/systemlist-backup.xml"
offline_online="/recalbox/share/userscripts/.config/.emulationstation/systemlist-online.xml"
offline_offline="/recalbox/share/userscripts/.config/.emulationstation/systemlist-offline.xml"

# Online Mode
if [ -f "$offline_systemlist" ] && [ -f "$offline_online" ]; then
# Mount thumbnails with rclone
rclone mount thumbnails: /recalbox/share/thumbs --config=/recalbox/share/system/rclone.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &

echo "Mounting libretro thumbnails..."

# Mount myrient with rclone
rclone mount myrient: /recalbox/share/rom --config=/recalbox/share/system/rclone2.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &
# Mount myrient with httpdirfs
#httpdirfs -d --dl-seg-size=1 --max-conns=20 --retry-wait=1 -o nonempty -o direct_io -o noforget https://myrient.erista.me/files/ /recalbox/share/rom
# Mount myrient with httpdirfs with cache
#httpdirfs -d --cache --dl-seg-size=1 --max-conns=20 --retry-wait=1 -o nonempty -o direct_io -o noforget https://myrient.erista.me/files/ /recalbox/share/rom
echo "Mounting romsets..."
echo "(No-Intro, Redump, TOSEC)..."

# Mount theeye with rclone
#rclone mount theeye: /recalbox/share/rom2 --config=/recalbox/share/system/rclone3.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &
# Mount theeye with httpdirfs
#httpdirfs -f -o debug -o auto_unmount --cache --cache-location=/recalbox/share/system/.cache/httpdirfs --dl-seg-size=1 --max-conns=20 #--retry-wait=1 -o nonempty "https://the-eye.eu/public/" "/recalbox/share/rom2/"
# Mount theeye with httpdirfs with cache
#httpdirfs -d -o debug --cache --cache-location=/recalbox/share/system/.cache/httpdirfs --dl-seg-size=1 --max-conns=20 --retry-wait=1 -o nonempty -o direct_io https://the-eye.eu/public/ /recalbox/share/rom2

#echo "Mounting romsets..."
#echo "(Mixed)..."

# Mount olddos with rclone
#rclone mount olddos: /recalbox/share/rom3 --config=/recalbox/share/system/rclone4.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &
# Mount olddos with httpdirfs
#httpdirfs -d --dl-seg-size=1 --max-conns=20 --retry-wait=1 -o nonempty -o direct_io -o noforget ftp://oscollect:SxrRwRGbMe50XcwMKB53j6LSN9DehYMJag@old-dos.ru/ /recalbox/share/rom3
# Mount olddos with httpdirfs with cache
#httpdirfs -d --cache --dl-seg-size=1 --max-conns=20 --retry-wait=1 -o nonempty -o direct_io -o noforget ftp://oscollect:SxrRwRGbMe50XcwMKB53j6LSN9DehYMJag@old-dos.ru/ /recalbox/share/rom3

#echo "Mounting romsets..."
#echo "(DOS)..."

# Mount thumbnails2 with rclone
#rclone mount thumbnails2: /recalbox/share/thumbs2 --config=/recalbox/share/system/rclone5.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &

#echo "Mounting missing thumbnails..."

# Mount videos with rclone
#rclone mount videos: /recalbox/share/videos --config=/recalbox/share/system/rclone6.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &

#echo "Mounting videos..."


	# Backup the existing systemlist.xml
    echo "Backing up systemlist.xml..."
    cp "$offline_systemlist" "$offline_backup"
    echo "Backup created: $offline_backup"

    # Overwrite systemlist.xml with the online version
    echo "Overwriting systemlist.xml with the online version..."
    cp "$offline_online" "$offline_systemlist"
    echo "Online version applied."

    # Move the contents to online directory
    cp -r /recalbox/share/userscripts/.config/readystream/roms/* /recalbox/share/roms/readystream/
    echo "copied ALL gamelists.xml to online directory."

fi

sleep 5
chvt 1; es start
}


# Function to perform actions specific to Offline Mode
offline_mode() {
    # Add your specific actions for Offline Mode here
    # ...
    echo "Offline Mode Enabled..."
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
        chvt 1; es start
    else
        echo "Error: systemlist.xml files not found."
    fi
fi	
	
}

# Function to download and install a binary with retries
download_and_install_with_retry() {
  local url=$1
  local output=$2
  local max_retries=3
  local retry_delay=5

  # Check if the binary already exists
  if [ -f "$output" ]; then
    echo "$output is already installed."
    return
  fi

  for ((attempt = 1; attempt <= max_retries; attempt++)); do
    echo "Downloading and installing $output (attempt $attempt/$max_retries)..."
    
    # Retry downloading
    if wget -O "$output" "$url"; then
      chmod +x "$output"
      echo "$output installed successfully."
      return
    else
      echo "Download failed. Retrying in $retry_delay seconds..."
      sleep $retry_delay
    fi
  done

  echo "Max retries reached. Failed to install $output."
  exit 1
}

# Function to download and install 7zip and rclone with retries
download_7zip_and_rclone() {
  local sevenzip_arch
  local rclone_arch

  # Detect architecture
  case $(uname -m) in
    x86_64) sevenzip_arch="x64"; rclone_arch="amd64"; mount_zip_arch="x64" ;;
    aarch64) sevenzip_arch="arm64"; rclone_arch="arm64"; mount_zip_arch="arm64" ;;
    *) echo "Unsupported architecture."; exit 1 ;;
  esac

  local sevenzip_url="https://github.com/develar/7zip-bin/raw/master/linux/${sevenzip_arch}/7za"
  local rclone_url="https://downloads.rclone.org/v1.65.0/rclone-v1.65.0-linux-${rclone_arch}.zip"

  # Download and install 7zip
  download_and_install_with_retry "$sevenzip_url" "/usr/bin/7za"

  # Download and install rclone
  download_and_install_with_retry "$rclone_url" "/usr/bin/rclone.zip"
  if [ $? -eq 0 ]; then
    7za e -y /usr/bin/rclone.zip
    mv rclone /usr/bin
    chmod +x /usr/bin/rclone
    rm /usr/bin/rclone.zip
  fi
}

# Call the function to download and install 7zip and rclone
download_7zip_and_rclone

# Download and Install jq 1.7.1
download_and_install_jq_with_retry() {
  local url=$1
  local output="/usr/bin/jq"
  local max_retries=3
  local retry_delay=5

  # Check if jq is already installed
  if [ -f "$output" ]; then
    echo "jq is already installed."
    return
  fi

  # Detect the architecture
  case $(arch) in
    x86_64) jq_arch="amd64" ;;
    aarch64) jq_arch="arm64" ;;
    *) echo "Unsupported jq architecture: $(arch)."; exit 1 ;;
  esac

  for ((attempt = 1; attempt <= max_retries; attempt++)); do
    jq_url="${url}-linux-${jq_arch}"
    echo "Downloading jq 1.7.1..."

    # Retry downloading
    if wget -O "$output" "$jq_url"; then
      chmod +x "$output"
      echo "jq 1.7.1 installed successfully for architecture: ${jq_arch}."
      return
    else
      echo "Download failed (attempt $attempt/$max_retries). Retrying in $retry_delay seconds..."
      sleep $retry_delay
    fi
  done

  echo "Max retries reached. Failed to install jq."
  exit 1
}

# Base URL for downloading jq
base_url="https://github.com/jqlang/jq/releases/download/jq-1.7.1"

# Call the function with the URL
download_and_install_jq_with_retry "$base_url/jq"


# Download and Install mount-zip
download_mount_zip_with_retry() {
  local url=$1
  local output=$2
  local max_retries=3
  local retry_delay=5

  for ((attempt = 1; attempt <= max_retries; attempt++)); do
    wget -O "$output" "$url"
    if [ $? -eq 0 ]; then
      echo "Download succeeded."
      return 0
    else
      echo "Download failed (attempt $attempt/$max_retries). Retrying in $retry_delay seconds..."
      sleep $retry_delay
    fi
  done

  echo "Max retries reached. Download failed."
  return 1
}

# Check if mount-zip is already installed
if [ ! -f /usr/bin/mount-zip ]; then
  echo "Downloading mount-zip..."

  # Detect the architecture
  case $(arch) in
    x86_64) mount_zip_arch="x64" ;;
    aarch64) mount_zip_arch="arm64" ;;
    *) echo "Unsupported mount-zip architecture: $(arch)."; exit 1 ;;
  esac

  mount_zip_url="https://github.com/readycade/readysync/raw/master/share/userscripts/.config/readystream/mount-zip-${mount_zip_arch}/mount-zip"

  # Download and Install mount-zip with retry
  download_mount_zip_with_retry "$mount_zip_url" "/usr/bin/mount-zip"
  if [ $? -ne 0 ]; then
    exit 1
  fi

  # Make mount-zip executable
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

# Download ratarmount AppImage
download_with_retry() {
  local url=$1
  local output=$2
  local max_retries=3
  local retry_delay=5

  for ((attempt = 1; attempt <= max_retries; attempt++)); do
    wget -O "$output" "$url"
    if [ $? -eq 0 ]; then
      echo "Download succeeded."
      return 0
    else
      echo "Download failed (attempt $attempt/$max_retries). Retrying in $retry_delay seconds..."
      sleep $retry_delay
    fi
  done

  echo "Max retries reached. Download failed."
  return 1
}

# Download ratarmount AppImage with retry
download_with_retry "https://github.com/mxmlnkn/ratarmount/releases/download/v0.15.0/ratarmount-0.15.0-x86_64.AppImage" "/usr/bin/ratarmount"
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Downloading ratarmount-0.15.0-x86_64.AppImage as /usr/bin/ratarmount"

# Make sure the AppImage is executable
chmod +x /usr/bin/ratarmount
echo "chmod +x /usr/bin/ratarmount"

# Extract the AppImage
/usr/bin/ratarmount --appimage-extract
echo "Extracting AppImage's squashfs-root folder"

# Download run_ratarmount.sh with retry
download_with_retry "https://raw.githubusercontent.com/readycade/readysync/master/share/userscripts/.config/readystream/run_ratarmount.sh" "/recalbox/share/userscripts/.config/readystream/run_ratarmount.sh"
if [ $? -ne 0 ]; then
  exit 1
fi

echo "run_ratarmount.sh downloaded to /recalbox/share/userscripts/.config/readystream/ successfully."

# Copy run_ratarmount.sh to /usr/bin/ if it doesn't exist there
if [ ! -e /usr/bin/run_ratarmount.sh ]; then
  cp /recalbox/share/userscripts/.config/readystream/run_ratarmount.sh /usr/bin/
  echo "run_ratarmount.sh copied to /usr/bin/ successfully."
else
  echo "run_ratarmount.sh already exists in /usr/bin/. No need to copy."
fi

# Make sure run_ratarmount.sh is executable
chmod +x /usr/bin/run_ratarmount.sh
echo "chmod +x /usr/bin/run_ratarmount.sh"

echo "ratarmount installed successfully."

# Function to download and copy files with retry
download_and_copy_file_with_retry() {
  local filename=$1
  local url=$2
  local target_directory=$3

  # Check if the file exists
  if [ ! -e "$target_directory/$filename" ]; then
    echo "Downloading $filename..."
    mkdir -p "$target_directory"
    
    # Retry downloading
    if ! wget -O "$target_directory/$filename" "$url"; then
      echo "Failed to download $filename."
      return 1
    fi

    echo "$filename downloaded successfully."
  else
    echo "$filename already exists. No need to download."
  fi

  # Copy the file to the system directory if it doesn't exist there
  if [ ! -e "/recalbox/share/system/$filename" ]; then
    cp "$target_directory/$filename" "/recalbox/share/system/"
    echo "$filename copied to /recalbox/share/system/ successfully."
  else
    echo "$filename already exists in /recalbox/share/system/. No need to copy."
  fi
}

# List of files to download and copy
files=(
  "rclone.conf"
  "rclone2.conf"
  "rclone3.conf"
  "rclone4.conf"
  "rclone5.conf"
  "rclone6.conf"
  "platforms.txt"
)

# Base URL for downloading files
base_url="https://raw.githubusercontent.com/readycade/readysync/master/share/userscripts/.config/readystream/"

# Iterate over each file and call the function
for file in "${files[@]}"; do
  download_and_copy_file_with_retry "$file" "${base_url}${file}" "/recalbox/share/userscripts/.config/readystream"
done

    # Download systemlist-backup.xml
    mkdir -p /recalbox/share/userscripts/.config/.emulationstation/

    echo "Downloading systemlist-backup.xml, systemlist-online.xml and systemlist-offline.xml"
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
        echo "Failed to download systemlist-backup.xml, systemlist-online.xml and systemlist-offline.xml..."
    fi

# Download LATEST Gamelist.xml's from github
# (remove the TARGET_DIR from your recalbox and the script will download the latest gamelists)

# Target directory
TARGET_DIR="/recalbox/share/userscripts/.config/readystream/roms"

# Check if the directory is empty
if [ -z "$(ls -A $TARGET_DIR)" ]; then
    echo "Downloading gamelist.xml and checksums for ALL Consoles..."

    # Ensure the target directory exists
    mkdir -p $TARGET_DIR

    # Navigate to the parent directory
    cd /recalbox/share/userscripts/.config/readystream

    # Download the ZIP file from GitHub
    wget -O readysync.zip https://github.com/readycade/readysync/archive/refs/heads/master.zip

    # Unzip the downloaded file
    unzip readysync.zip

    # Move the contents of the desired directory to the target location
    mv readysync-master/share/userscripts/.config/readystream/roms/* $TARGET_DIR/

    # Clean up
    rm -rf readysync.zip readysync-master

    echo "gamelist.xml and checksums downloaded successfully."
else
    echo "gamelist.xml and checksums directory is not empty. No need to download."
fi

# Define directories to create
directories=(
  "/recalbox/share/roms/readystream"
  "/recalbox/share/rom"
  "/recalbox/share/rom2"
  "/recalbox/share/rom3"
  "/recalbox/share/rom4"
  "/recalbox/share/thumbs"
  "/recalbox/share/thumbs2"
  "/iso"
  "/recalbox/share/zip"
)

# Loop through each directory and create it if it doesn't exist
for dir in "${directories[@]}"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    echo "Directory $dir created successfully."
  else
    echo "Directory $dir already exists. No need to create."
  fi
done

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
    "arduboy 1"
    "atari2600 1"
    "atari5200 1"
    "atari7800 1"
    "atarist 1"
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
    # Old-DOS Romsets
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
            #delete_disabled_platform_directory "$platform_name"
            ;;
        *)
            echo "Invalid status. Use '1' for enable and '0' for disable."
            ;;
    esac
done

# Function to handle online mode
online_mode() {
    echo "Online Mode Selected"
    # Add your online mode logic here
}

# Function to handle offline mode
offline_mode() {
    echo "Offline Mode Selected"
    # Add your offline mode logic here
}

# Function to check for keyboard input
check_keyboard_input() {
    local input
    local event_number
    # Continuously listen for keyboard input on events 0 to 30
    for event_number in {0..30}; do
        while true; do
            # Read a single character from the keyboard device
            if read -rsn 1 input < "/dev/input/event$event_number"; then
                mode_choice="$input"
                return  # Exit the loop if input received
            fi
        done
    done
    # Default to offline mode if no input is received
    mode_choice="2"
}

# Display menu
echo "Please select a mode:"
echo "1. Online Mode"
echo "2. Offline Mode"

# Capture input or default to offline mode
check_keyboard_input

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

# Other commands after mode selection
chvt 1; es start

exit
