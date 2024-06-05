#!/bin/bash
log_file="/recalbox/share/system/.systemstream.log"

# Clear the log files
truncate -s 0 "$log_file"
echo "Log file:..."
echo "/recalbox/share/system/.systemstream.log"
echo "Truncating log file..."

#-----------START OF USER EDIT-------------#
# Define whether to enable or disable each console directly within the script
# Syntax: console_name=enabled|disabled
declare -A console_status
console_status=(
    [atari800]=enabled
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
    [thomson]=enabled
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
    [x1]='https://myrient.erista.me/files/TOSEC/Sharp/X1/Games/%5BTAP%5D/Sharp%20X1%20-%20Games%20-%20%5BTAP%5D.zip'
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
            echo "Files already exist for $console. Skipping download."
            continue
        fi

        echo "Downloading $console..."
        success=1
        retries=3
        while [ $success -ne 0 ] && [ $retries -gt 0 ]; do
            wget --no-check-certificate --accept '*.zip' --reject '*.html' -r -c -P "/recalbox/share/zip/$console" "${download_urls[$console]}"
            success=$?
            if [ $success -ne 0 ]; then
                echo "Downloading $console... Retry attempt $((4 - retries))"
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
                echo "Failed to find the downloaded zip file for $console."
                rm -rf "/recalbox/share/zip/$console/myrient/*"
            fi
        else
            echo "Downloading $console... Failed after multiple retries"
            rm -rf "/recalbox/share/zip/$console"
        fi
    else
        echo "$console is disabled."
        rm -rf "/recalbox/share/zip/$console"
    fi
done

echo "All TOSEC files downloaded and extracted successfully!"

