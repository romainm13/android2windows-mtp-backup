# Android to Windows MTP Backup Script

## Introduction

This script automates the backup of files (such as images, videos, and PDFs) from an Android phone to a Windows computer using the MTP (Media Transfer Protocol) protocol. The script uses a combination of Python and PowerShell to download the files from the phone, and then moves them to various category folders and renames them based on their last modified date. This script is an improved version of `powershell-mtp-file-transfer` by [@nosalan](https://github.com/nosalan), with new features and bug fixes.

Note: This script has only been tested on a Samsung S20 FE phone and a Legion Y540-15IRH computer running Windows 10. It may not work on other systems.

## How it works

The Python code [main.py](http://main.py) launches a subprocess where a powershell script will download files via MTP. When it finishes, the files are moved to category folders. Pictures and videos are renamed by their modified dates. There are many new features compared to https://github.com/nosalan/powershell-mtp-file-transfer and bug fixes.

## New features

### Powershell

- `dateThreshold` : only files newer than `dateThreshold` will be copied
- The script will not download files from `.thumbnails` folders
- The script will skip trashed files (files starting with a dot)

### Python

- Moves files to category folders
  - dcim (pictures/videos)
  - doc (pdf, word …)
  - music
  - other (whatever you want)
- Rename pictures and videos by “last modified” date

### Bug fixed

In the oldest version of @nolasan's repository, there was an issue where the Shell.Application wouldn't detect all files unless the folder on the phone to be backed up was opened in Windows Explorer previously.

This problem has been solved by opening each Windows Explorer and waiting for all files to be loaded before closing it (recursively).

## Environment

- PC: Legion Y540-15IRH
  - OS: Windows 10 Family (version 21h2)
- Phone: Samsung S20 FE
  - OS: Android
- Connection android2windows: usbc2usb

## Dev Environment & Dependencies

- Python3 (3.11)
- Powershell

## Install

```bash
git clone https://github.com/romainm13/android2windows-mtp-backup.git
```

## Configuration

You have to configure the Powershell and the Python script for your needs.

### Powershell configuration - `phone_backup.ps1`

- `phoneName` : the name of your phone in the Windows Explorer (mine is "Galaxy S20 FE de Romain")
- `dateThreshold` : only files newer than `dateThreshold` should be copied
- `DestDirBackup` : the path where the files will be downloaded (I don't understand why but just creating a short path in the same folder here doesn't work so put a global path just like mine)
- In the "TRANSFERT" area, you can configure the folders to be backed up on your phone by choosing the second parameter of the `Get-SubFolder` function. You can also add or remove folders.

### Python configuration - `main.py`

- `DestDirBackup` : **same as the `DestDirBackup` variable in the Powershell script.**
- Modify `extdcim`, `extdoc`, `extmusic`, `extother` to match your needs

## Credits and references

Thank you to @nosalan for the good base script [powershell-mtp-file-transfer](https://github.com/nosalan/powershell-mtp-file-transfer).

Thanks to OpenAIChat as well :)
