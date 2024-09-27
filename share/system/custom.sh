#!/bin/bash
#set -x

#################################################################################################################
## Author Michael Cabral 2024
## Title: Readysync
## GPL-3.0 license
## Platforms: Windows 10/11, Linux, MacOS
## Description: Mounts any HTTP/FTP repository of Romsets giving you an Online and Offline experience.
## Online = HTTP/FTP Mounted Games
## Offline = Local Hard Drive Games
## Supported Romsets: (No-Intro, Redump, TOSEC and more)
## Applications Used using rclone, httpdirfs, wget, mount-zip, 7zip

## DISCLAIMER: This script is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement.

## This script is intended for educational and informational purposes only. The authors and ReadyCade, Inc. do not support or condone the illegal downloading or distribution of video games. Downloading video games
## without proper authorization is illegal and can result in severe penalties. Users are solely responsible for ensuring that their actions comply with applicable laws.

## This script does not actually download or store any video games for 69 consoles/systems. It is solely for mounting an online source, and no content will remain on your ReadyCade upon reboot.

## TOSEC Romsets ARE downloaded and extracted to your Readycade as long as they are ENABLED in the script.
## DISABLED consoles/systems will have all their contents deleted next time the script runs (Next Reboot.)

## In no event shall the authors or ReadyCade, Inc. be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the script
## or the use or other dealings in the script. USE AT YOUR OWN RISK. YOU ASSUME ALL LIABILITY FOR ANY ACTIONS TAKEN BASED ON THIS SCRIPT.
#################################################################################################################

ln -s /usr/bin/fusermount /usr/bin/fusermount3
mount -o remount,rw /
echo "mount and unmount as read-write..."

# Fix sound issues in EmulationStation
echo 'default-sample-rate = 48000' >> /etc/pulse/daemon.conf

log_file="/recalbox/share/system/.systemstream.log"
online_mode_flag_file="/recalbox/share/system/.online_mode_enabled.log"
online_mode_enabled=$(cat "$online_mode_flag_file")
keyboard_events="/recalbox/share/system/keyboard_events.txt"
monitor_duration=5

# Check and update systemlist.xml based on user choice
offline_systemlist="/recalbox/share_init/system/.emulationstation/systemlist.xml"
offline_systemlist2="/recalbox/share/system/.emulationstation/systemlist.xml"
offline_backup="/recalbox/share/userscripts/.config/.emulationstation/systemlist-backup.xml"
offline_online="/recalbox/share/userscripts/.config/.emulationstation/systemlist-online.xml"
offline_offline="/recalbox/share/userscripts/.config/.emulationstation/systemlist-offline.xml"

# Clear the log files
truncate -s 0 "$log_file"
echo "Log file:..."
echo "/recalbox/share/system/.systemstream.log"
echo "Truncating log file..."

truncate -s 0 "$keyboard_events"
echo "Log file:..."
echo "/recalbox/share/system/keyboard_events.txt"
echo "Truncating log file..."

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>"$log_file" 2>&1

sanitize_dir_name() {
  tr -cd '[:alnum:]' <<< "$1"
}

mkdir -p /recalbox/share/userscripts/.config/.emulationstation
mkdir -p /recalbox/share/userscripts/.config/readystream
mkdir -p /recalbox/share/userscripts/.config/readystream/roms

mkdir -p /recalbox/share/thumbs
mkdir -p /recalbox/share/dos
mkdir -p /recalbox/share/roms/readystream
mkdir -p /recalbox/share/roms/readystream/tmp

# Wait for internet to connect
# Define the URLs and directories
readysync_roms_url="https://raw.githubusercontent.com/readycade/readysync/master/share/userscripts/.config/readystream/roms.zip"
readysync_tmp_dir="/recalbox/share/userscripts/.config/readystream/tmp"
readysync_roms_dir="/recalbox/share/userscripts/.config/readystream/roms"
readysync_roms_dest="/recalbox/share/roms/readystream"

# Check if the destination directory already contains files
if [ -d "$readysync_roms_dir" ] && [ "$(ls -A $readysync_roms_dir)" ]; then
    echo "Files already exist in $readysync_roms_dir. No need to download."
else
    # Create the temporary directory if it doesn't exist
    mkdir -p "$readysync_tmp_dir"

    # Download the zip file to the temporary directory
    wget -O "$readysync_tmp_dir/roms.zip" "$readysync_roms_url"

    # Check if the download was successful
    if [ $? -ne 0 ]; then
        echo "Failed to download the file."
        # You may choose to exit here or just log the error and continue.
    fi

    # Extract the downloaded zip file to the destination directory
    unzip -o "$readysync_tmp_dir/roms.zip" -d "$readysync_roms_dir"

    # Check if the extraction was successful
    if [ $? -ne 0 ]; then
        echo "Failed to extract the file."
        # You may choose to exit here or just log the error and continue.
    fi
fi

# Clean up the temporary zip file if it exists
rm -f "$readysync_tmp_dir/roms.zip"

# Copy all folders and files from the roms directory to the destination directory
mkdir -p "$readysync_roms_dest"
cp -r "$readysync_roms_dir/"* "$readysync_roms_dest/"

echo "Download and extraction completed successfully, and files copied to $readysync_roms_dest."

# Define the systemlist directory
systemlist_dir="/recalbox/share/userscripts/.config/.emulationstation"

# Initialize online_mode_enabled as false
echo "false" > "$online_mode_flag_file"
echo "online_mode_enabled = false"

# Download systemlist-backup.xml
if [ -f "$systemlist_dir/systemlist-backup.xml" ]; then
    echo "systemlist-backup.xml already exists. Skipping download."
else
    if wget --tries=3 https://raw.githubusercontent.com/readycade/readysync/master/share/userscripts/.config/.emulationstation/systemlist-backup.xml -O "$systemlist_dir/systemlist-backup.xml"; then
        echo "systemlist-backup.xml downloaded successfully."
    else
        echo "Failed to download systemlist-backup.xml after 3 attempts."
    fi
fi

# Download systemlist-online.xml
if [ -f "$systemlist_dir/systemlist-online.xml" ]; then
    echo "systemlist-online.xml already exists. Skipping download."
else
    if wget --tries=3 https://raw.githubusercontent.com/readycade/readysync/master/share/userscripts/.config/.emulationstation/systemlist-online.xml -O "$systemlist_dir/systemlist-online.xml"; then
        echo "systemlist-online.xml downloaded successfully."
    else
        echo "Failed to download systemlist-online.xml after 3 attempts."
    fi
fi

# Download systemlist-offline.xml
if [ -f "$systemlist_dir/systemlist-offline.xml" ]; then
    echo "systemlist-offline.xml already exists. Skipping download."
else
    if wget --tries=3 https://raw.githubusercontent.com/readycade/readysync/master/share/userscripts/.config/.emulationstation/systemlist-offline.xml -O "$systemlist_dir/systemlist-offline.xml"; then
        echo "systemlist-offline.xml downloaded successfully."
    else
        echo "Failed to download systemlist-offline.xml after 3 attempts."
    fi
fi

# Function to switch to online mode
online_mode() {
    echo "Online Mode Selected..."
    echo "DEBUG: Online Mode Enabled..."
    echo "Online Mode Enabled..."
    
    # Mark online mode as enabled
    echo "true" > "$online_mode_flag_file"
    echo "Online mode set to Enabled"

    echo "Performing actions specific to Online Mode..."

# Online Mode
if [ -f "$offline_systemlist" ] && [ -f "$offline_online" ]; then
    # Backup the existing systemlist.xml
    echo "Backing up systemlist.xml..."
    backup_success=false
    for source in "$offline_systemlist" "$offline_systemlist2"; do
        if cp "$source" "$offline_backup"; then
            echo "Backup created: $offline_backup"
            backup_success=true
            break
        else
            echo "Failed to backup $source."
        fi
    done

    if [ "$backup_success" = false ]; then
        echo "Error: Backup failed for both sources."
        exit 1  # Exit if backup fails
    fi

    # Overwrite systemlist.xml with the online version
    echo "Overwriting systemlist.xml with the Online version..."
    for destination in "$offline_systemlist" "$offline_systemlist2"; do
        if cp "$offline_online" "$destination"; then
            echo "$destination overwritten with the online version."
        else
            echo "Failed to overwrite $destination."
        fi
    done
    echo "Online version applied."
else
    echo "Error: Required files are missing."
    exit 1  # Exit if files are missing
fi

# DISCLAIMER: This WILL download these enabled romsets onto your machine!!!
# Disabled romsets will get deleted upon reboot.

#-----------START OF USER EDIT-------------#
# Define whether to enable or disable each console directly within the script
# Syntax: console_name=enabled|disabled
declare -A console_status
console_status=(
    [atari800]=disabled
    [pc88]=enabled
    [pc98]=enabled
    [zx81]=enabled
    [x1]=enabled
    [x68000]=enabled
    [msxturbor]=enabled
    [bbcmicro]=enabled
    [dragon]=enabled
    [bk]=enabled
    [samcoupe]=enabled
    [thomson]=disabled
    [ti994a]=enabled
    [trs80coco]=enabled
    [vg5000]=enabled
    [zmachine]=enabled
    [amstradcpc]=disabled
    [gx4000]=disabled
    [zxspectrum]=disabled
    [pet]=disabled
)

# Array of download URLs
declare -A download_urls
download_urls=(
    [atari800]='https://myrient.erista.me/files/TOSEC/Atari/8bit/Games/%5BXEX%5D/Atari%208bit%20-%20Games%20-%20%5BXEX%5D.zip'
    [pc88]='https://myrient.erista.me/files/TOSEC/NEC/PC-8801/Games/%5BD88%5D/NEC%20PC-8801%20-%20Games%20-%20%5BD88%5D.zip'
    [pc98]='https://myrient.erista.me/files/TOSEC/NEC/PC-9801/Games/%5BFDD%5D/NEC%20PC-9801%20-%20Games%20-%20%5BFDD%5D.zip'
    [zx81]='https://myrient.erista.me/files/TOSEC/Sinclair/ZX81/Games/%5BP%5D/Sinclair%20ZX81%20-%20Games%20-%20%5BP%5D.zip'
    [x1]='https://myrient.erista.me/files/TOSEC/Sharp/X1/Games/%5BD88%5D/Sharp%20X1%20-%20Games%20-%20%5BD88%5D.zip'
    [x68000]='https://myrient.erista.me/files/TOSEC/Sharp/X68000/Games/%5BDIM%5D/Sharp%20X68000%20-%20Games%20-%20%5BDIM%5D.zip'
    [msxturbor]='https://myrient.erista.me/files/TOSEC/MSX/TurboR/Games/MSX%20TurboR%20-%20Games.zip'
    [bbcmicro]='https://myrient.erista.me/files/TOSEC/Acorn/BBC/Games/%5BSSD%5D/Acorn%20BBC%20-%20Games%20-%20%5BSSD%5D.zip'
    [dragon]='https://myrient.erista.me/files/TOSEC/Dragon%20Data/Dragon/Games/%5BCAS%5D/Dragon%20Data%20Dragon%20-%20Games%20-%20%5BCAS%5D.zip'
    [bk]='https://myrient.erista.me/files/TOSEC/Elektronika/BK-0011-411/Games/Elektronika%20BK-0011-411%20-%20Games.zip'
    [samcoupe]='https://myrient.erista.me/files/TOSEC/MGT/Sam%20Coupe/Games/%5BDSK%5D/MGT%20Sam%20Coupe%20-%20Games%20-%20%5BDSK%5D.zip'
    [thomson]='https://myrient.erista.me/files/TOSEC/Thomson/TO8%2C%20TO8D%2C%20TO9%2C%20TO9%2B/Games/%5BFD%5D/Thomson%20TO8%2C%20TO8D%2C%20TO9%2C%20TO9%2B%20-%20Games%20-%20%5BFD%5D.zip'
    [ti994a]='https://myrient.erista.me/files/TOSEC/Texas%20Instruments/TI-99%204A/Games/%5BDSK%5D/Texas%20Instruments%20TI-99%204A%20-%20Games%20-%20%5BDSK%5D.zip'
    [trs80coco]='https://myrient.erista.me/files/TOSEC/Tandy%20Radio%20Shack/TRS-80%20Color%20Computer/Games/%5BDSK%5D/Tandy%20Radio%20Shack%20TRS-80%20Color%20Computer%20-%20Games%20-%20%5BDSK%5D.zip'
    [vg5000]='https://myrient.erista.me/files/TOSEC/Philips/VG%205000/Games/Philips%20VG%205000%20-%20Games.zip'
    [zmachine]='https://myrient.erista.me/files/TOSEC/Infocom/Z-Machine/Games/Infocom%20Z-Machine%20-%20Games.zip'
    [amstradcpc]='https://myrient.erista.me/files/TOSEC/Amstrad/CPC/Games/%5BDSK%5D/Amstrad%20CPC%20-%20Games%20-%20%5BDSK%5D.zip'
    [gx4000]='https://myrient.erista.me/files/TOSEC/Amstrad/GX4000/Games/Amstrad%20GX4000%20-%20Games.zip'
    [zxspectrum]='https://myrient.erista.me/files/TOSEC/Sinclair/ZX%20Spectrum/Games/%5BTAP%5D/Sinclair%20ZX%20Spectrum%20-%20Games%20-%20%5BTAP%5D.zip'
    [pet]='https://myrient.erista.me/files/TOSEC/Commodore/PET/Games/%5BPRG%5D/Commodore%20PET%20-%20Games%20-%20%5BPRG%5D.zip'
)

# Loop through each console and download the file if enabled
for console in "${!download_urls[@]}"; do
    if [ "${console_status[$console]}" = "enabled" ]; then
        # Check if the directory already contains files other than the myrient folder
        if [ -d "/recalbox/share/zip/$console" ] && find "/recalbox/share/zip/$console" -mindepth 1 ! -regex '^/recalbox/share/zip/'"$console"'/myrient.*' -print -quit | grep -q .; then
            echo "TOSEC Rom Files already exist for $console. Skipping download."
            continue
        fi

        echo "Downloading $console..."
        success=1
        retries=3
        while [ $success -ne 0 ] && [ $retries -gt 0 ]; do
            wget --no-check-certificate --accept '*.zip' --reject '*.html' -r -c -P "/recalbox/share/zip/$console" "${download_urls[$console]}"
            success=$?
            if [ $success -ne 0 ]; then
                echo "Downloading Tosec Romset $console... Retry attempt $((4 - retries))"
                ((retries--))
            fi
        done

        if [ $success -eq 0 ]; then
            # Find the downloaded zip file in the nested directory structure
            downloaded_zip=$(find "/recalbox/share/zip/$console" -type f -name "*.zip")
            if [ -n "$downloaded_zip" ]; then
                echo "Extracting $console..."
                unzip -o "$downloaded_zip" -d "/recalbox/share/zip/$console/"
            else
                echo "Failed to find the downloaded TOSEC zip file for $console."
                rm -rf "/recalbox/share/zip/$console/myrient/*"
            fi
        else
            echo "Downloading TOSEC Romset $console... Failed after multiple retries"
            rm -rf "/recalbox/share/zip/$console"
        fi
    else
        echo "TOSEC Romset $console is disabled."
        rm -rf "/recalbox/share/zip/$console"
    fi
done

echo "All TOSEC files downloaded and extracted successfully!"

# Function to download a rclone with retries
download_rclone_with_retry() {
    local url=$1
    local output=$2
    local max_retries=3
    local retry_delay=5

    for ((attempt = 1; attempt <= max_retries; attempt++)); do
        wget --quiet --show-progress --retry-connrefused --waitretry=$retry_delay --timeout=30 --tries=$max_retries -O "$output" "$url"
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

# Determine architecture
architecture=$(uname -m)
if [ "$architecture" == "x86_64" ]; then
    rclone_arch="amd64"
elif [ "$architecture" == "aarch64" ]; then
    rclone_arch="arm64"
else
    echo "Error: Unsupported architecture."
    exit 1
fi

# Check if rclone exists in /usr/bin
if [ -x /usr/bin/rclone ]; then
    echo "rclone already exists in /usr/bin. Skipping download."
else
    # Download rclone with retry
    rclone_url="https://github.com/readycade/readysync/raw/master/share/userscripts/.config/readystream/rclone-${rclone_arch}/rclone"
    download_rclone_with_retry "$rclone_url" "/usr/bin/rclone"
    if [ $? -eq 0 ]; then
        echo "rclone binary downloaded successfully."
        # Set permissions
        chmod +x /usr/bin/rclone
        echo "Execute permission set for rclone binary."
    else
        echo "Error: Failed to download rclone."
    fi
fi

# Function to download a httpdirfs with retries
download_httpdirfs_with_retry() {
    local url=$1
    local output=$2
    local max_retries=3
    local retry_delay=5

    for ((attempt = 1; attempt <= max_retries; attempt++)); do
        wget --quiet --show-progress --retry-connrefused --waitretry=$retry_delay --timeout=30 --tries=$max_retries -O "$output" "$url"
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

# Determine architecture
architecture=$(uname -m)
if [ "$architecture" == "x86_64" ]; then
    httpdirfs_arch="x64"
elif [ "$architecture" == "aarch64" ]; then
    httpdirfs_arch="arm64"
else
    echo "Error: Unsupported architecture."
    exit 1
fi

# Check if httpdirfs exists in /usr/bin
if [ -x /usr/bin/httpdirfs ]; then
    echo "httpdirfs already exists in /usr/bin. Skipping download."
else
    # Download httpdirfs with retry
    httpdirfs_url="https://github.com/readycade/readysync/raw/master/share/userscripts/.config/readystream/httpdirfs-${httpdirfs_arch}/httpdirfs"
    download_httpdirfs_with_retry "$httpdirfs_url" "/usr/bin/httpdirfs"
    if [ $? -eq 0 ]; then
        echo "httpdirfs binary downloaded successfully."
        # Set permissions
        chmod +x /usr/bin/httpdirfs
        echo "Execute permission set for httpdirfs binary."
    else
        echo "Error: Failed to download httpdirfs."
    fi
fi

# Mount myrient with rclone
#rclone mount myrient: /recalbox/share/rom --config=/recalbox/share/system/rclone2.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &

# Attempt to download rclonemyrient.conf
if [ ! -f /recalbox/share/system/rclonemyrient.conf ]; then
    if wget -q --retry-connrefused --tries=3 https://raw.githubusercontent.com/readycade/readysync/refs/heads/master/share/userscripts/.config/readystream/rclonemyrient.conf -O /recalbox/share/system/rclonemyrient.conf; then
        echo "rclonemyrient.conf downloaded successfully."
    else
        echo "Failed to download rclonemyrient.conf after 3 attempts."
    fi
else
    echo "rclonemyrient.conf already exists, skipping download."
fi

    # Attempt to mount rclonemyrient
    if rclone mount myrient: /recalbox/share/rom --config "/recalbox/share/system/rclonemyrient.conf" --http-no-head --no-checksum --no-modtime --attr-timeout 365d --dir-cache-time 365d --poll-interval 365d --allow-non-empty --daemon --no-check-certificate; then
        echo "Rclone mounted myrient successfully."
    else
        echo "Failed to mount myrient."
    fi

#rclone mount nointro: /recalbox/share/rom/No-Intro --config=/recalbox/share/system/rclone2.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &
#rclone mount redump: /recalbox/share/rom/Redump --config=/recalbox/share/system/rclone2.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &
#rclone mount tosec: /recalbox/share/rom/TOSEC --config=/recalbox/share/system/rclone2.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &

# Attempt to download rclone4.conf
if [ ! -f /recalbox/share/system/rclone4.conf ] || [ ! -s /recalbox/share/system/rclone4.conf ]; then
    if wget -q --retry-connrefused --tries=3 --timeout=10 --waitretry=5 --read-timeout=10 --retry-on-http-error=500,502,503,504 https://raw.githubusercontent.com/readycade/readysync/refs/heads/master/share/userscripts/.config/readystream/rclone4.conf -O /recalbox/share/system/rclone4.conf; then
        echo "rclone4.conf downloaded successfully."
    else
        echo "Failed to download rclone4.conf after 3 attempts."
    fi
else
    echo "rclone4.conf already exists and is not empty, skipping download."
fi

    # Attempt to mount rclone4.conf
    if rclone mount olddos: /recalbox/share/dos --config "/recalbox/share/system/rclone4.conf" --http-no-head --no-checksum --no-modtime --attr-timeout 365d --dir-cache-time 365d --poll-interval 365d --allow-non-empty --daemon --no-check-certificate; then
        echo "Rclone mounted old-dos.ru successfully."
    else
        echo "Failed to mount olddos."
    fi

echo "Mounting romsets..."
echo "(No-Intro, Redump, TOSEC)..."
echo "(Old-Dos.ru)..."

#wait

# Wait for a brief moment for the mount to occur
sleep 5

# Check if the mount point exists and contains files
if [ "$(ls -A /recalbox/share/rom)" ]; then
    echo "Mounting successful. Files are mounted in /recalbox/share/rom"
else
    echo "Mounting failed. No files are mounted in /recalbox/share/rom"
fi

# Mount thumbnails with rclone
#rclone mount thumbnails: /recalbox/share/thumbs --config=/recalbox/share/system/rclone.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &

# Attempt to download rclone.conf
if [ ! -f /recalbox/share/system/rclone.conf ]; then
    if wget -q --retry-connrefused --tries=3 https://raw.githubusercontent.com/readycade/readysync/refs/heads/master/share/userscripts/.config/readystream/rclone.conf -O /recalbox/share/system/rclone.conf; then
        echo "rclonemyrient.conf downloaded successfully."
    else
        echo "Failed to download rclonemyrient.conf after 3 attempts."
    fi
else
    echo "rclone.conf already exists, skipping download."
fi

    # Attempt to mount rclone thumbnails
    if rclone mount thumbnails: --config "/recalbox/share/system/rclone.conf" /recalbox/share/thumbs --http-no-head --no-checksum --no-modtime --attr-timeout 365d --dir-cache-time 365d --poll-interval 365d --allow-non-empty --daemon --no-check-certificate; then
        echo "Rclone mounted thumbnails successfully."
    else
        echo "Failed to mount thumbnails."
    fi

# Mount thumbnails with httpdirfs
#httpdirfs -d -f -o debug --cache --cache-location=/recalbox/share/system/.cache/httpdirfs --dl-seg-size=1 --max-conns=20 --retry-wait=1 -o nonempty -o direct_io https://thumbnails.libretro.com/ /recalbox/share/thumbs
#httpdirfs -f -o debug --dl-seg-size=1 --max-conns=20 --retry-wait=1 -o nonempty -o direct_io -o no_cache https://thumbnails.libretro.com/ /recalbox/share/thumbs

#WIZARDS COMMAND
#mkdir /recalbox/share/system/.cache/httpdirfs
#httpdirfs --cache --cache-location /recalbox/share/system/.cache/httpdirfs https://thumbnails.libretro.com "/recalbox/share/thumbs"

echo "Mounting libretro thumbnails..."

# Check if the thumbnails exists and contains files
if [ "$(ls -A /recalbox/share/thumbs)" ]; then
    echo "Mounting successful. Files are mounted in /recalbox/share/thumbs."
else
    echo "Mounting failed. No files are mounted in /recalbox/share/thumbs."
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

# Function to download and install a binary file
install_binary() {
    local binary_name=$1
    local url=$2
    local output=$3

    if [ -f "$output" ]; then
        echo "$binary_name is already installed. Skipping download."
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

# Install jq
install_binary "jq" "https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-${jq_arch}" "/usr/bin/jq"

# Install mount-zip
install_binary "mount-zip" "https://github.com/readycade/readysync/raw/master/share/userscripts/.config/readystream/mount-zip-${arch}/mount-zip" "/usr/bin/mount-zip"

# Install ratarmount
#install_binary "ratarmount" "https://github.com/mxmlnkn/ratarmount/releases/download/v0.15.0/ratarmount-0.15.0-${ratarmount_arch}.AppImage" "/usr/bin/ratarmount.AppImage"
#if [ $? -eq 0 ]; then
#    chmod +x "/usr/bin/ratarmount.AppImage"  # Ensure the binary is executable
#    /usr/bin/ratarmount --appimage-extract

#fi

    # Sleep to let everything sync up
    sleep 5

    # Replace the following line with the actual command to start emulation station
    chvt 1; es start

}

# Function to switch to offline mode
offline_mode() {
    echo "DEBUG: Offline Mode Selected..."
    echo "Performing actions specific to Offline Mode..."

    # Stop evtest if it's running
    pkill -9 evtest

    echo "DEBUG: evtest process killed."

    # Offline Mode actions
    if [ -f "$offline_systemlist" ] && [ -f "$offline_offline" ]; then
        # Backup existing systemlist.xml
        echo "Backing up current systemlist.xml..."
        for source in "$offline_systemlist" "$offline_systemlist2"; do
            if cp "$source" "$offline_backup"; then
                break
            fi
        done
        echo "Backup created: $offline_backup"

        # Overwrite systemlist.xml with the offline version
        echo "Overwriting systemlist.xml with the Offline version..."
        for destination in "$offline_systemlist" "$offline_systemlist2"; do
            cp "$offline_offline" "$destination"
        done

        echo "Installation complete. Log saved to: $log_file"

    else
        echo "Error: systemlist.xml files not found."
    fi

    exit 0
}

# Function to check if a line matches any of the desired patterns
check_event() {
    local line="$1"
    if [[ $line == *"type 4 (EV_MSC), code 4 (MSC_SCAN), value 90004"* || \
          $line == *"type 4 (EV_MSC), code 4 (MSC_SCAN), value 90003"* || \
          $line == *"type 1 (EV_KEY), code 305 (BTN_EAST), value 1"* || \
          $line == *"type 4 (EV_MSC), code 4 (MSC_SCAN), value 7001e"* ]]; then
        echo "online"
    else
        echo "offline"
    fi
}

# Function to monitor keyboard input events
monitor_keyboard_input() {
    # Initialize online mode flag file
    echo "false" > "$online_mode_flag_file"

    # Loop through events /dev/input/event3 to /dev/input/event12
    for dev in $(seq 3 12); do
        # Monitor events in the background
        evtest /dev/input/event"$dev" --grab | while read -r line; do
            echo "DEBUG: Keyboard event detected on /dev/input/event$dev: $line"

            # Check if the line indicates a button press for online mode
            if [ "$(check_event "$line")" = "online" ]; then
                echo "Button press detected. Switching to Online Mode..."
                echo "true" > "$online_mode_flag_file"
                echo "online_mode_enabled set to true"

                # Kill evtest before calling online_mode
                echo "Killing evtest"
                pkill -9 evtest

                # Call online_mode after killing evtest
                online_mode
            fi
        done &
    done

    # Wait for the specified monitoring duration
    sleep "$monitor_duration"

    # Check if online mode was enabled
    if [ "$(cat "$online_mode_flag_file")" = "false" ]; then
        echo "No button press detected. Switching to Offline Mode..."
        # Ensure evtest is killed before launching offline_mode
        pkill -9 evtest
        offline_mode
    fi

    exit 0
}

# Start monitoring keyboard input in the background
monitor_keyboard_input &

# Capture the PID of the background process
monitor_pid=$!

# Wait for the background process to finish
wait "$monitor_pid"

# After the monitor process finishes, proceed with further actions here if needed
# For example:
echo "Script completed."
