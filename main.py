#%%
import os
import shutil
import time
from pathlib import Path
import subprocess

#######################
# GLOBAL VARIABLES
#######################

DestDirBackup = "D:\\1-Mes documents\\2-Boulot\\_Travail\\2-Mes Projets\\_public\\1_android-mtp-backup\\android2windows-mtp-backup\\_BACKUP_TELEFON"

#######################
# RUN POWERSHELL SCRIPT TO BACKUP PHONE
#######################

start_time = time.perf_counter()

cmd = ["PowerShell.exe",'-File', ".\phone_backup.ps1"]
def execute(cmd):
    popen = subprocess.Popen(cmd, stdout=subprocess.PIPE, bufsize=1, universal_newlines=True, text=True)
    for stdout_line in iter(popen.stdout.readline, ""):
        yield stdout_line 
    popen.stdout.close()
    return_code = popen.wait()
    if return_code:
        raise subprocess.CalledProcessError(return_code, cmd)

for path in execute(cmd):
    print(path, end="")
    
print("PowerShell script is done in {} seconds".format(time.perf_counter() - start_time))

#######################
# MOVE FILES TO FOLDERS
#######################

#%%
fdcim = "dcim"
extdcim = [".jpg", ".jpeg", ".png", ".gif", ".jfif", ".webp", ".bmp", ".tiff", ".psd", ".raw", ".heif", "svg", ".mp4", ".mov"]
fmusic = "music"
extmusic = [".mp3", ".wav", ".m4a", "m3u"]
fdoc = "doc"
extdoc = [".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", ".txt", ".csv"]
fautre = "autre"
extother = [".gpx"] # add more extensions if needed

list_folders = [fdcim, fmusic, fdoc, fautre]
list_ext = [extdcim, extmusic, extdoc, extother]

# Create folders (remove if already exist)
for folder in list_folders:
    if os.path.isdir(folder):
        shutil.rmtree(folder)
    os.mkdir(folder)

# Browse files in BACKUP_TELEPHON and move them in the right folder
for path in Path(DestDirBackup).rglob('*.*'):
    ext = "." + str(path).split(".")[-1]
    if ".trashed" not in str(path):
        if ext in extdcim:
            shutil.move(str(path), fdcim)
        elif ext in extmusic:
            shutil.move(str(path), fmusic)
        elif ext in extdoc:
            shutil.move(str(path), fdoc)
        elif ext in extother:
            shutil.move(str(path), fautre)

import datetime
names_used = []

#######################
# DCIM FOLDER -> RENAME FILES BY DATE
#######################

for path in Path(fdcim).rglob('*.*'):
    extension = "." + str(path).split(".")[-1]
    date = os.path.getmtime(path)
    format_time = datetime.datetime.fromtimestamp(date)
    format_time_string = format_time.strftime("%Y-%m-%d_%Hh%Mm%Ss")
    newfile = format_time_string + extension
    comp = 1
    while newfile in names_used:
        newfile = format_time_string + "-" + str(comp) + extension
        comp += 1
    names_used.append(newfile)
    print(fdcim + "\\" + newfile)
    os.rename(path, fdcim + "\\" + newfile)
