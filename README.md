

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

# Uncomment / Comment mode_choice and change the value below for the timeout to automatically press 1 or 2
read -t "$timeout_seconds" -r input || input="2"

# Default to Offline Mode if no input within the timeout
mode_choice="${input:-2}"

# Default to Online Mode if no input within the timeout
#mode_choice="${input:-1}"
----------------------------------------------------------------------------------------
```
