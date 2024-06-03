

# Readysync (Ready... Set... Play!)

Mounts any HTTP/FTP repository of Romsets giving you an Online and Offline experience.

It uses rclone to mount any HTTP/FTP directory to your Readycade and makes it playable almost instantly.

It uses httpdirfs to mount the thumbnails from https://thumbnails.libretro.com

It uses zip-mount to mount .zip's to /iso when the emulator doesn't support .zip files (eg. arduboy, gamecube, ps2, wii.. ect)

## INSTALLATION

### Recalbox 9.1+ Supported ONLY:

Download **custom.sh** and place it in **/recalbox/share/system**
```
eg: /recalbox/share/system/custom.sh
```

### Alternative Installation method:

login to your recalbox via ssh (Open a **Command Prompt** on **windows** or **terminal** on **linux/mac**)

**login username and host:**
```
root@recalbox
```
**password:**
```
recalboxroot
```
**run the command to download and auto install**
```
wget -O /recalbox/share/system/custom.sh https://raw.githubusercontent.com/readycade/readysync/master/share/system/custom.sh && chmod +x /recalbox/share/system/custom.sh
```

### The script will run on **every boot**.
Offline will be **ALWAYS** selected if you **do not** press anything during **startup**)

### Selecting Online or Offline Mode (**Offline** is default)
Power on your **Readycade** and wait until after seeing "Booting Recalbox... **press B** repeatedly for **10-15 seconds**"

Known Supported Controllers:
DragonArcade Joystick/Buttons
Sony Playstation 4
Microsoft Xbox 360 (Wired)
Standard Keyboard (Press 1 instead of B)

### If you want the Whole Enchilada (ALL THE GAMES)
Most of the **larger TOSEC romsets** will be **disabled** by default to make things snappy.
If there are any you wish to **enable**. You may do so by **removing** the # **before** the **console/system's name**

In this Example **Amstrad CPC** is **DISABLED**.
```
#enabled_consoles+=("Amstrad_CPC")
```
**Atari 8bit** is **ENABLED**.
```
enabled_consoles+=("Atari_8bit")
```

### Notes:
Default **gamelist.xml's** and **checksums** are provided for **ALL consoles**.

The script should work **automagically**, but incase nothing happens the first time.. it's most likely due to your **internet connection** not being able to download all of the required files in a timely manner.

In this case, **restart** your **Readycade** and **try again**. It should work the **second time**.

### Long Loading Times
If you only use **No-Intro** and **Redump** the boot time should be under **5 minutes**.

Enabling larger **TOSEC romsets** will take **longer to mount**. ex: **amstradcpc, gx4000, zxspectrum, dos...**

### Log File:
```
/recalbox/share/system/.systemstream.log
```

### MORE PROBLEMS?!?!?!
If you experience any OTHER issues, **DELETE** everything in **/recalbox/share/userscripts/.config** and **restart** your **Readycade**.

#### DO NOT RUN THIS: Running the command from the terminal (ADVANCED USERS ONLY)
```
/etc/init.d/S99custom start
```

### Flowchart (Visual Representation)
![ReadySync Flowchart](https://github.com/readycade/readysync/blob/master/ReadySync-FLOWCHART.png)
