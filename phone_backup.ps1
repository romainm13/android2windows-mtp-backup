#this is an enhanced version of https://github.com/nosalan/powershell-mtp-file-transfer/blob/master/phone_backup.ps1
#it supports backing up nested folders

# Administrateur PowerShell to print stdout in Python
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted

# GLOBAL VARIABLES
function Get-PhoneMainDir($phoneName)
{
  $o = New-Object -com Shell.Application
  $rootComputerDirectory = $o.NameSpace(0x11)
  $phoneDirectory = $rootComputerDirectory.Items() | Where-Object {$_.Name -eq $phoneName} | select -First 1
    
  if($phoneDirectory -eq $null)
  {
    throw "Not found '$phoneName' folder in This computer. Connect your phone."
  }
  
  return $phoneDirectory;
}

$phoneName = "Galaxy S20 FE de Romain" #Phone name as it appears in This PC
$phoneRootDir = Get-PhoneMainDir $phoneName

# Adding date threshold to only copy files that are newer than a certain date
$dateThreshold = Get-Date "2022-12-01"
Write-Host "Date de reference: $dateThreshold"

############################## CODE ########################################
$ErrorActionPreference = [string]"Continue"
$DestDirBackup = [string]"D:\1-Mes documents\2-Boulot\_Travail\2-Mes Projets\_public\1_android-mtp-backup\android2windows-mtp-backup\_BACKUP_TELEFON"
$Summary = [Hashtable]@{NewFilesCount=0; ExistingFilesCount=0}

function Create-Dir($path)
{
  if(! (Test-Path -Path $path))
  {
    # Write-Host "Creating: $path"
    New-Item -Path $path -ItemType Directory
  }
  else
  {
    Write-Host "Path $path already exist"
  }
}


function Get-SubFolder($parentDir, $subPath)
{
  $result = $parentDir
  foreach($pathSegment in ($subPath -split "\\"))
  {
    $result = $result.GetFolder.Items() | Where-Object {$_.Name -eq $pathSegment} | select -First 1
    if($result -eq $null)
    {
      throw "Not found $subPath folder"
    }
  }
  return $result;
}


function Get-FullPathOfMtpDir($mtpDir)
{
 $fullDirPath = ""
 $directory = $mtpDir.GetFolder
 while($directory -ne $null)
 {
   $fullDirPath =  -join($directory.Title, '\', $fullDirPath)
   $directory = $directory.ParentFolder;
 }
 return $fullDirPath
}

######### My function open windows explorer
function Open-Folder([string]$folderPath)
{
  $dir = Get-SubFolder $phoneRootDir $folderPath
  $dir.InvokeVerb("open")
  Start-Sleep -Seconds 2 # SUPER IMPORTANT POUR LAISSER LE TEMPS DE CHARGER!
  
  $shell = New-Object -ComObject Shell.Application
  $folderBaseName = (Split-Path $folderPath -Leaf)
  $window = $shell.Windows() | Where-Object {$_.LocationName -like $folderBaseName}
  $time_to_load = 0
  While ($window.ReadyState -ne 4) {
    $state = $window.ReadyState
    Write-Host "Waiting for $folderBaseName to be ready (ReadyState = $state)"
    Start-Sleep -Seconds 5
    $time_to_load = $time_to_load + 5
  }
  Write-Host "Folder $folderBaseName is ready in $time_to_load seconds"
  $window | ForEach-Object { $_.Quit() }
}
#########

function Copy-FromPhoneSource-ToBackup($sourceMtpDir, $destDirPath)
{
 Create-Dir $destDirPath
 $destDirShell = (new-object -com Shell.Application).NameSpace($destDirPath)
 $fullSourceDirPath = Get-FullPathOfMtpDir $sourceMtpDir

 # Open-Folder to load the folder in windows explorer
 $startIndex = $fullSourceDirPath.IndexOf("Stockage interne")
 $length = $fullSourceDirPath.Length - $startIndex - 1
 $substring = $fullSourceDirPath.Substring($startIndex, $length)
 Open-Folder $substring

 Write-Host "Copying from: '" $fullSourceDirPath "' to '" $destDirPath "'"
 
 $copiedCount, $existingCount = 0
 
 foreach ($item in $sourceMtpDir.GetFolder.Items())
  {
   $itemName = ($item.Name)
   $itemdate = $item.ExtendedProperty("System.DateModified")
   $fullFilePath = Join-Path -Path $destDirPath -ChildPath $itemName


   if($item.IsFolder)
   {
    # $item.Name is ".thumbnails", skip it
    if($item.GetFolder.Title -ne ".thumbnails")
    {
      Write-Host $item.Name " is folder, stepping into"
      Copy-FromPhoneSource-ToBackup  $item (Join-Path $destDirPath $item.GetFolder.Title)
    }
   }
   elseif(Test-Path $fullFilePath)
   {
      # Write-Host "Element '$itemName' already exists"
      $existingCount++;
   }
   elseif(($itemdate -ge $dateThreshold) -and (-not $item.Name.StartsWith(".")))
   {
      $copiedCount++;
      # Write-Host ("Copying #{0}: {1}{2}" -f $copiedCount, $fullSourceDirPath, $item.Name)
      $destDirShell.CopyHere($item)
   }
  }
  $script:Summary.NewFilesCount += $copiedCount 
  $script:Summary.ExistingFilesCount += $existingCount 
  # Write-Host "Copied '$copiedCount' elements from '$fullSourceDirPath'"
  Write-Host "Copied '$copiedCount' elements from '$fullSourceDirPath'"
}

############################## TRANSFERT ##############################

##############################################
# Download
##############################################

Copy-FromPhoneSource-ToBackup (Get-SubFolder $phoneRootDir "Stockage interne\Download") $DestDirBackup
Write-Host "`n--------------------`n--------------------`n"

##############################################
# DCIM
##############################################

Copy-FromPhoneSource-ToBackup (Get-SubFolder $phoneRootDir "Stockage interne\DCIM") $DestDirBackup
Write-Host "`n--------------------`n--------------------`n"
##############################################
# Snapchat
##############################################

Copy-FromPhoneSource-ToBackup (Get-SubFolder $phoneRootDir "Stockage interne\Snapchat") $DestDirBackup
Write-Host "`n--------------------`n--------------------`n"

##############################################
# Documents
##############################################

Copy-FromPhoneSource-ToBackup (Get-SubFolder $phoneRootDir "Stockage interne\Documents") $DestDirBackup
Write-Host "`n--------------------`n--------------------`n"

##############################################
# Movies
##############################################

Copy-FromPhoneSource-ToBackup (Get-SubFolder $phoneRootDir "Stockage interne\Movies") $DestDirBackup
Write-Host "`n--------------------`n--------------------`n"

##############################################
# Music
##############################################

Copy-FromPhoneSource-ToBackup (Get-SubFolder $phoneRootDir "Stockage interne\Music") $DestDirBackup
Write-Host "`n--------------------`n--------------------`n"

##############################################
# Notifications
##############################################

Copy-FromPhoneSource-ToBackup (Get-SubFolder $phoneRootDir "Stockage interne\Notifications") $DestDirBackup
Write-Host "`n--------------------`n--------------------`n"

##############################################
# Pictures
##############################################

Copy-FromPhoneSource-ToBackup (Get-SubFolder $phoneRootDir "Stockage interne\Pictures") $DestDirBackup
Write-Host "`n--------------------`n--------------------`n"

##############################################
# Recordings
##############################################

Copy-FromPhoneSource-ToBackup (Get-SubFolder $phoneRootDir "Stockage interne\Recordings") $DestDirBackup
Write-Host "`n--------------------`n--------------------`n"

##############################################
# Voice Recorder
##############################################

Copy-FromPhoneSource-ToBackup (Get-SubFolder $phoneRootDir "Stockage interne\Voice Recorder") $DestDirBackup
Write-Host "`n--------------------`n--------------------`n"

##############################################
##############################################

write-host ($Summary | out-string)