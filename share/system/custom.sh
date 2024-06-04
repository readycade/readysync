#!/bin/bash
#set -x

#################################################################################################################
## Author Michael Cabral 2024
## Title: Readysync
## GPL-3.0 license
## Description: Mounts any HTTP/FTP repository of Romsets giving you an Online and Offline experience.
## Online = HTTP/FTP Mounted Games
## Offline = Local Hard Drive Games
## Supported Romsets: (No-Intro, Redump, TOSEC and more)
## Applications Used using rclone, httpdirfs, wget, mount-zip, 7zip

## DISCLAIMER: This script is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement.

## This script is intended for educational and informational purposes only. The authors and ReadyCade, Inc. do not support or condone the illegal downloading or distribution of video games. Downloading video games
## without proper authorization is illegal and can result in severe penalties. Users are solely responsible for ensuring that their actions comply with applicable laws.

## This script does not actually download or store any video games. It is solely for mounting an online source, and no content will remain on your ReadyCade upon reboot.

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

# Initialize online_mode_enabled flag file
echo "false" > "$online_mode_flag_file"
echo "DEBUG $online_mode_flag_file set to false"

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>"$log_file" 2>&1

sanitize_dir_name() {
  tr -cd '[:alnum:]' <<< "$1"
}

# Function to switch to online mode
online_mode() {
    echo "Online Mode Enabled..."
    echo "DEBUG: Online Mode Enabled..."
    echo "Online Mode Enabled..."
    echo "Performing actions specific to Online Mode..."

    # Online Mode
    if [ -f "$offline_systemlist" ] && [ -f "$offline_online" ]; then

        # Backup the existing systemlist.xml
        echo "Backing up systemlist.xml..."
        for source in "$offline_systemlist" "$offline_systemlist2"; do
    if cp "$source" "$offline_backup"; then
        break
    fi
done

        echo "Backup created: $offline_backup"

        # Overwrite systemlist.xml with the online version
        echo "Overwriting systemlist.xml with the online version..."
        for destination in "$offline_systemlist" "$offline_systemlist2"; do
    cp "$offline_online" "$destination"
done
        echo "Online version applied."

        # Move the contents to online directory
        cp -r /recalbox/share/userscripts/.config/readystream/roms/* /recalbox/share/roms/readystream/
        echo "copied ALL gamelists.xml to online directory."
fi

# Function to download a file with retries
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

# Function to download a file with retries
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

# Function to download a file with retries
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
rclone mount myrient:  /recalbox/share/rom --config "/recalbox/share/system/rclone2.conf" --http-no-head --no-checksum --no-modtime --attr-timeout 365d --dir-cache-time 365d --poll-interval 365d --allow-non-empty --daemon --no-check-certificate

#rclone mount nointro: /recalbox/share/rom/No-Intro --config=/recalbox/share/system/rclone2.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &
#rclone mount redump: /recalbox/share/rom/Redump --config=/recalbox/share/system/rclone2.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &
#rclone mount tosec: /recalbox/share/rom/TOSEC --config=/recalbox/share/system/rclone2.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &


echo "Mounting romsets..."
echo "(No-Intro, Redump, TOSEC)..."

wait

# Mount thumbnails with rclone
rclone mount thumbnails: /recalbox/share/thumbs --config=/recalbox/share/system/rclone.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty &
#rclone mount thumbnails: --config "/recalbox/share/system/rclone.conf" /recalbox/share/thumbs --http-no-head --no-checksum --no-modtime --attr-timeout 365d --dir-cache-time 365d --poll-interval 365d --allow-non-empty --daemon --no-check-certificate

# Mount thumbnails with httpdirfs
#httpdirfs -d -f -o debug --cache --cache-location=/recalbox/share/system/.cache/httpdirfs --dl-seg-size=1 --max-conns=20 --retry-wait=1 -o nonempty -o direct_io https://thumbnails.libretro.com/ /recalbox/share/thumbs
#httpdirfs -f -o debug --dl-seg-size=1 --max-conns=20 --retry-wait=1 -o nonempty -o direct_io -o no_cache https://thumbnails.libretro.com/ /recalbox/share/thumbs

#WIZARDS COMMAND
#mkdir /recalbox/share/system/.cache/httpdirfs
#httpdirfs --cache --cache-location /recalbox/share/system/.cache/httpdirfs https://thumbnails.libretro.com "/recalbox/share/thumbs"

echo "Mounting libretro thumbnails..."

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

# Define TOSEC Romsets Array
declare -A consoles
consoles=(
    ["Atari_8bit"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Atari/8bit/Games/[XEX]/Atari 8bit - Games - [XEX].zip\" \"/recalbox/share/zip/atari800/\""
    ["NEC_PC-8801"]="mount-zip -v \"/recalbox/share/rom/TOSEC/NEC/PC-8801/Games/[D88]/NEC PC-8801 - Games - [D88].zip\" \"/recalbox/share/zip/pc88/\""
    ["NEC_PC-9801"]="mount-zip -v \"/recalbox/share/rom/TOSEC/NEC/PC-9801/Games/[FDD]/NEC PC-9801 - Games - [FDD].zip\" \"/recalbox/share/zip/pc98/\""
    ["Sinclair_ZX81"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Sinclair/ZX81/Games/[P]/Sinclair ZX81 - Games - [P].zip\" \"/recalbox/share/zip/zx81/\""
    ["Sharp_X1"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Sharp/X1/Games/[TAP]/Sharp X1 - Games - [TAP].zip\" \"/recalbox/share/zip/x1/\""
    ["Sharp_X68000"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Sharp/X68000/Games/[DIM]/Sharp X68000 - Games - [DIM].zip\" \"/recalbox/share/zip/x68000/\""
    ["Elektronika_BK-0011-411"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Elektronika/BK-0011-411/Games/Elektronika BK-0011-411 - Games.zip\" \"/recalbox/share/zip/bk/\""
    ["MSX_TurboR"]="mount-zip -v \"/recalbox/share/rom/TOSEC/MSX/TurboR/Games/MSX TurboR - Games.zip\" \"/recalbox/share/zip/msxturbor/\""
    ["Acorn_BBC"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Acorn/BBC/Games/[SSD]/Acorn BBC - Games - [SSD].zip\" \"/recalbox/share/zip/bbcmicro/\""
    ["Dragon_Data_Dragon"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Dragon Data/Dragon/Games/[CAS]/Dragon Data Dragon - Games - [CAS].zip\" \"/recalbox/share/zip/dragon/\""
    ["MGT_Sam_Coupe"]="mount-zip -v \"/recalbox/share/rom/TOSEC/MGT/Sam Coupe/Games/[DSK]/MGT Sam Coupe - Games - [DSK].zip\" \"/recalbox/share/zip/samcoupe/\""
    ["Thomson_TO8_TO8D_TO9_TO9+"]="/mount-zip -v \"/recalbox/share/rom/TOSEC/Thomson/TO8, TO8D, TO9, TO9+/Games/[FD]/Thomson TO8, TO8D, TO9, TO9+ - Games - [FD].zip\" \"/recalbox/share/zip/thomson/\""
    ["Texas_Instruments_TI-99_4A"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Texas Instruments/TI-99 4A/Games/[DSK]/Texas Instruments TI-99 4A - Games - [DSK].zip\" \"/recalbox/share/zip/ti994a/\""
    ["Tandy_TRS-80_CoCo"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Tandy Radio Shack/TRS-80 Color Computer/Games/[DSK]/Tandy Radio Shack TRS-80 Color Computer - Games - [DSK].zip\" \"/recalbox/share/zip/trs80coco/\""
    ["Philips_VG5000"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Philips/VG 5000/Games/Philips VG 5000 - Games.zip\" \"/recalbox/share/zip/vg5000/\""
    ["Infocom_Z-Machine"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Infocom/Z-Machine/Games/Infocom Z-Machine - Games.zip\" \"/recalbox/share/zip/zmachine/\""
    ["Commodore_PET"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Commodore/PET/Games/[PRG]/Commodore PET - Games - [PRG].zip\" \"/recalbox/share/zip/pet/\""
    ["Amstrad_CPC"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Amstrad/CPC/Games/[DSK]/Amstrad CPC - Games - [DSK].zip\" \"/recalbox/share/zip/amstradcpc/\""
    ["Amstrad_GX4000"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Amstrad/GX4000/Games/Amstrad GX4000 - Games.zip\" \"/recalbox/share/zip/gx4000/\""
    ["Sinclair_ZX_Spectrum"]="mount-zip -v \"/recalbox/share/rom/TOSEC/Sinclair/ZX Spectrum/Games/[TAP]/Sinclair ZX Spectrum - Games - [TAP].zip\" \"/recalbox/share/zip/zxspectrum/\""

)

# Most TOSEC romsets are disabled by default (# = disabled)

# Enable the desired consoles by uncommenting the relevant lines

#-----------START OF USER EDIT-------------#

# Atari 8bit
#enabled_consoles+=("Atari_8bit")
# NEC PC-8801
#enabled_consoles+=("NEC_PC-8801")
# NEC PC-9801
#enabled_consoles+=("NEC_PC-9801")
# Sinclair ZX81
#enabled_consoles+=("Sinclair_ZX81")
# Sharp X1
#enabled_consoles+=("Sharp_X1")
# Sharp X68000
#enabled_consoles+=("Sharp_X68000")
# Elektronika BK-0011-411
#enabled_consoles+=("Elektronika_BK-0011-411")
# MSX TurboR
#enabled_consoles+=("MSX_TurboR")
#Acorn BBC
#enabled_consoles+=("Acorn_BBC")
# Dragon Data Dragon
#enabled_consoles+=("Dragon_Data_Dragon")
# MGT Sam Coupe
#enabled_consoles+=("MGT_Sam_Coupe")
# Thomson TO8, TO8D, TO9, TO9+
#enabled_consoles+=("Thomson_TO8_TO8D_TO9_TO9+")
# Texas Instruments TI-99 4A
#enabled_consoles+=("Texas_Instruments_TI-99_4A")
# Tandy TRS-80 CoCo
#enabled_consoles+=("Tandy_TRS-80_CoCo")
# Philips VG5000
#enabled_consoles+=("Philips_VG5000")
# Infocom Z-Machine
#enabled_consoles+=("Infocom_Z-Machine")

# Below are very big romsets and take a very long time to mount.
# Enable at your own risk.

# Amstrad CPC
#enabled_consoles+=("Amstrad_CPC")
# Amstrad GX4000
#enabled_consoles+=("Amstrad_GX4000")
# Sinclair ZX Spectrum
#enabled_consoles+=("Sinclair_ZX_Spectrum")

# Commodore PET (NOT SUPPORTED BY RECALBOX)
#enabled_consoles+=("Commodore_PET")

#------------END OF USER EDIT--------------#

# Mount enabled consoles
for console in "${enabled_consoles[@]}"; do
    if [[ -n "${consoles[$console]}" ]]; then
        echo "Mounting $console..."
        eval "${consoles[$console]}"
    else
        echo "Invalid console: $console"
    fi
done


echo "Selected consoles have been mounted."

# Mark online mode as enabled
echo "true" > "$online_mode_flag_file"

sleep 10

# Start Emulationstation (twice incase it doesn't populate)
chvt 1; es start

sleep 10

# Start Emulationstation (twice incase it doesn't populate)
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

    # Offline Mode
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
        echo "Overwriting systemlist.xml with the offline version..."
        for destination in "$offline_systemlist" "$offline_systemlist2"; do
    cp "$offline_offline" "$destination"
done

        echo "Installation complete. Log saved to: $log_file"

        # Mark offline mode as enabled
        echo "false" > "$online_mode_flag_file"

        # Sleep to let everything sync up
        sleep 5

        # Replace the following line with the actual command to start emulation station
        chvt 1; es start
    else
        echo "Error: systemlist.xml files not found."
    fi
}

monitor_keyboard_input() {
    prev_button_state=""

    evtest /dev/input/event3 --grab | while read -r line; do
        echo "DEBUG: Keyboard event detected: $line"
        if [[ $line == *"type 4 (EV_MSC), code 4 (MSC_SCAN), value 90004"* ]]; then
            button_state="online"
        elif [[ $line == *"type 4 (EV_MSC), code 4 (MSC_SCAN), value 90003"* ]]; then
            button_state="online"
        elif [[ $line == *"type 4 (EV_MSC), code 4 (MSC_SCAN), value 7001e"* ]]; then
            button_state="online"
        else
            button_state="offline"
        fi

        if [ "$button_state" != "$prev_button_state" ]; then
            if [ "$button_state" = "online" ]; then
                echo "DEBUG: Button Press detected. Switching to online mode..."
                echo "true" > "$online_mode_flag_file"
                echo "DEBUG: online_mode_enabled set to true"
                online_mode
            else
                echo "DEBUG: No button press detected. Offline mode enabled."
                offline_mode
            fi
            prev_button_state="$button_state"
        fi
    done
}

# Start monitoring keyboard input in the background and capture the PID
monitor_keyboard_input &
evtest_pid=$!

# Wait for the background process to finish
wait

# Kill the evtest process
kill -TERM $evtest_pid

exit 0