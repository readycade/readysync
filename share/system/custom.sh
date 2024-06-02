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
online_mode_flag_file="/recalbox/share/system/.online_mode_enabled.log"

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

# Initialize online_mode_enabled flag file
echo "false" > "$online_mode_flag_file"

# Function to switch to online mode
online_mode() {
    echo "Online Mode Enabled..."
    echo "DEBUG: Online Mode Enabled..."
    echo "Online Mode Enabled..."
    echo "Performing actions specific to Online Mode..."

    # Check and update systemlist.xml based on user choice
    offline_systemlist="/recalbox/share_init/system/.emulationstation/systemlist.xml"
    offline_backup="/recalbox/share/userscripts/.config/.emulationstation/systemlist-backup.xml"
    offline_online="/recalbox/share/userscripts/.config/.emulationstation/systemlist-online.xml"
    offline_offline="/recalbox/share/userscripts/.config/.emulationstation/systemlist-offline.xml"

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

        # Move the contents to online directory
        cp -r /recalbox/share/userscripts/.config/readystream/roms/* /recalbox/share/roms/readystream/
        echo "copied ALL gamelists.xml to online directory."

# Function to download a file with retries
download_with_retry() {
    local url=$1
    local output=$2
    local max_retries=3
    local retry_delay=5

    for ((attempt = 1; attempt <= max_retries; attempt++)); do
        wget -q --show-progress -O "$output" "$url"
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

# Function to download and install a binary file
install_binary() {
    local binary_name=$1
    local url=$2
    local output=$3

    if [ -f "$output" ]; then
        echo "$binary_name is already installed."
    else
        download_with_retry "$url" "$output"
        chmod +x "$output"  # Ensure the binary is executable
        mv "$output" "/usr/bin/$binary_name"  # Move the binary to /usr/bin
        echo "$binary_name installed."
    fi
}

# Determine architecture
case $(uname -m) in
    x86_64) arch="x64"; rclone_arch="amd64"; jq_arch="amd64"; ratarmount_arch="x86_64";;
    aarch64) arch="arm64"; rclone_arch="arm64"; jq_arch="arm64"; ratarmount_arch="x86_64";;
    *) echo "Unsupported architecture."; exit 1 ;;
esac

# Install 7zip
install_binary "7za" "https://github.com/develar/7zip-bin/raw/master/linux/${arch}/7za" "/usr/bin/7za"
if [ $? -eq 0 ]; then
    chmod +x /usr/bin/7za  # Make the binary executable
fi

# Download rclone
curl -O https://github.com/readycade/readysync/raw/master/share/userscripts/.config/readystream/rclone-${rclone_arch}/rclone
if [ $? -eq 0 ]; then
    echo "rclone binary downloaded successfully."
    # Move the binary to /usr/bin
    sudo cp rclone /usr/bin/
    if [ -f "/usr/bin/rclone" ]; then
        echo "rclone binary successfully moved to /usr/bin."
        # Set permissions
        sudo chown root:root /usr/bin/rclone
        sudo chmod 755 /usr/bin/rclone
    else
        echo "Error: rclone binary not found in /usr/bin after moving."
    fi
    # Clean up
    rm rclone
else
    echo "Error: Failed to download rclone."
fi

# Install jq
install_binary "jq" "https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-${jq_arch}" "/usr/bin/jq"

# Install mount-zip
install_binary "mount-zip" "https://github.com/readycade/readysync/raw/master/share/userscripts/.config/readystream/mount-zip-${arch}/mount-zip" "/usr/bin/mount-zip"

# Install ratarmount
install_binary "ratarmount" "https://github.com/mxmlnkn/ratarmount/releases/download/v0.15.0/ratarmount-0.15.0-${ratarmount_arch}.AppImage" "/usr/bin/ratarmount.AppImage"
if [ $? -eq 0 ]; then
    chmod +x "/usr/bin/ratarmount.AppImage"  # Ensure the binary is executable
fi

        # Mount thumbnails with rclone
        #rclone mount thumbnails: /recalbox/share/thumbs --config=/recalbox/share/system/rclone.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &
        rclone mount thumbnails: /recalbox/share/thumbs --http-no-head --no-checksum --no-modtime --attr-timeout 365d --dir-cache-time 365d --poll-interval 365d --allow-non-empty --daemon --no-check-certificate

        echo "Mounting libretro thumbnails..."

        # Mount myrient with rclone
        #rclone mount myrient: /recalbox/share/rom --config=/recalbox/share/system/rclone2.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &
        rclone mount myrient: /recalbox/share/rom --http-no-head --no-checksum --no-modtime --attr-timeout 365d --dir-cache-time 365d --poll-interval 365d --allow-non-empty --daemon --no-check-certificate

        echo "Mounting romsets..."
        echo "(No-Intro, Redump, TOSEC)..."

        # Exit the script after online mode is enabled
        exit 0
    fi

    # Mark online mode as enabled
    echo "true" > "$online_mode_flag_file"

    # Start EmulationStation
    chvt 1; es start

    # Exit the script after online mode is enabled
    exit 0

}

# Function to switch to offline mode
offline_mode() {
# Check if online mode is already enabled
if [ "$online_mode_enabled" = true ]; then
        echo "Online mode already enabled. Skipping offline mode."
        return
    fi

    echo "Offline Mode Enabled..."
    echo "DEBUG: Offline Mode Selected..."
    echo "Offline Mode Enabled..."
    echo "Performing actions specific to Offline Mode..."

    # Check and update systemlist.xml based on user choice
    offline_systemlist="/recalbox/share_init/system/.emulationstation/systemlist.xml"
    offline_backup="/recalbox/share/userscripts/.config/.emulationstation/systemlist-backup.xml"
    offline_offline="/recalbox/share/userscripts/.config/.emulationstation/systemlist-offline.xml"
    
    # Offline Mode
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
}

# Monitor keyboard input and switch modes accordingly
monitor_keyboard_input() {
    evtest /dev/input/event3 --grab | while read -r line; do
        echo "DEBUG: Keyboard event detected: $line"
        if [[ $line == *"BTN_TOP"* ]]; then
            echo "DEBUG: B button pressed. Switching to online mode..."
            online_mode
            echo "true" > "$online_mode_flag_file"
            echo "DEBUG: online_mode_enabled set to true"
            break
        fi
    done
}

# Start monitoring keyboard input in the background
monitor_keyboard_input &

# Wait for the background process to finish
wait

exit 0
