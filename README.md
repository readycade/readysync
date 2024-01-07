This is for Recalbox / Batocera

Essentially what the script does is offer you an OFFLINE and ONLINE way of playing games

Online = 1, Offline = 2

Default mode is Offline
 
Uncomment / Comment mode_choice and change the value below for the timeout to automatically press 1 or 2
read -t "$timeout_seconds" -r input || input="2"

# Default to Offline Mode if no input within the timeout
mode_choice="${input:-2}"

# Default to Online Mode if no input within the timeout
#mode_choice="${input:-1}"
