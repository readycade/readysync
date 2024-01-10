

# Readystream (Every Game, All at Once)

Essentially what the script does is offer you an OFFLINE and ONLINE way of playing games

It mounts whatever FTP/HTTP directory to your arcade (Recalbox) and makes it playable instantly.

For our examples in the rclone.conf
```
[myrient]
type = http
url = https://myrient.erista.me/files/

#[thumbnails]
#type = http
#url = http://thumbnails.libretro.com

#[dos]
#type = ftp
#host = old-dos.ru
#user = oscollect
#pass = SxrRwRGbMe50XcwMKB53j6LSN9DehYMJag
```

```
----------------------------------------------------------------------------------------
Online = 1, Offline = 2

Default mode is Offline
----------------------------------------------------------------------------------------
in the custom.sh file

# Display menu
echo "Please select a mode:"
echo "1. Online Mode"
echo "2. Offline Mode"

# Capture input with timeout
# change mode_choice="2" to "1" if you wish to enable Online
timeout_seconds=5
read -t "$timeout_seconds" -r input || mode_choice="2"
----------------------------------------------------------------------------------------
```
