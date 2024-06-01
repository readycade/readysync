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

online_mode_enabled=false

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

        # Mount thumbnails with rclone
        rclone mount thumbnails: /recalbox/share/thumbs --config=/recalbox/share/system/rclone.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &

        echo "Mounting libretro thumbnails..."

        # Mount myrient with rclone
        rclone mount myrient: /recalbox/share/rom --config=/recalbox/share/system/rclone2.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &

        echo "Mounting romsets..."
        echo "(No-Intro, Redump, TOSEC)..."

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

# Define the URL and output path
url="https://github.com/mxmlnkn/ratarmount/releases/download/v0.15.0/ratarmount-0.15.0-x86_64.AppImage"
output="/usr/bin/ratarmount"

# Check if file already exists
if [ -f "$output" ]; then
    echo "File already exists. Skipping download."
else
    # Download ratarmount AppImage with retry
    download_with_retry "$url" "$output"
fi

# Set execute permissions if the file exists
if [ -f "$output" ]; then
    chmod +x "$output"
    echo "ratarmount installed."
fi


        # Switch to the appropriate TTY
        #chvt 2

        # Start EmulationStation
        chvt 1; es start
    fi
    online_mode_enabled=true
}

# Function to switch to offline mode
offline_mode() {
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
            break
        fi
    done
}

# Start monitoring keyboard input in the background
monitor_keyboard_input &

# Wait for the background process to finish
wait

# If online mode is enabled, exit the script
if [ "$online_mode_enabled" = true ]; then
    exit 0
fi

# Otherwise, switch to offline mode
offline_mode

exit 0
