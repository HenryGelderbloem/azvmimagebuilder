# Global Variables
$lastError = @()

# FSLogix Directory Creation Variables
$appName = 'FsLogix'
$tempDirectory = 'C:\Temp\'
$appPath = $tempDirectory + $appName
$NewItemParameters = @{
    Path = $tempDirectory
    Name = $appName
    ItemType = "Direcotry"
    ErrorAction = "Stop"
    ErrorVariable = "lastError"
}

# FSLogix Download Parameters
$fsLogixURI = "https://aka.ms/fslogix_download"
$downloadedFile = "fslogix_download.zip"
$InvokeWebRequestParameters = @{
    Uri = $fsLogixURI
    OutFile = $downloadedFile
    ErrorAction = "Stop"
    ErrorVariable = "lastError"
}

# FSLogix Unzip Parameters
$ExpandArchiveParameters = @{
    Path = $downloadedFile
    DestinationPath = $appPath
    Force = $true
    Verbose = $true
    ErrorAction = "Stop"
    ErrorVariable = "lastError"
}

# FSLogix Directory Creation
# Creates a new folder in C:\Temp with the name FSLogix.
try {
    Write-Host -Object "AIB Customisation: Creating FSLogix directory."
    New-Item @NewItemParameters
    Write-Host -Object "AIB Customisation: Created FSLogix directory."
}
catch {
    Write-Host -Object "AIB Customisation Error: Unable to create the directory $appPath."
    Write-Host -Object $lastError
    Write-Host -Object "Exit code: $LASTEXITCODE"
}


# FSLogix Download
# Downloads FSLogix into the $appPath directory
try {
    Write-Host -Object "AIB Customisation: Downloading FSLogix."
    Invoke-WebRequest @InvokeWebRequestParameters
    Write-Host -Object "AIB Customisation: Downloaded FSLogix."
}
catch {
    Write-Host -Object "AIB Customisation Error: Unable to download FSLogix."
    Write-Host -Object $lastError
    Write-Host -Object "Exit code: $LASTEXITCODE"
}


# FSLogix Unzip
# Unzips the downloaded file to the $appPath directory.
try {
    Write-Host -Object "AIB Customisation: Unzipping $downloadedFile."
    Expand-Archive @ExpandArchiveParameters
    Write-Host -Object "AIB Customisation: Unzipped $downloadedFile."
}
catch {
    Write-Host -Object "AIB Customisation Error: Unable to unzip $downloadedFile."
    Write-Host -Object $lastError
    Write-Host -Object "Exit code: $LASTEXITCODE"
}


# FSLogix Version Comparison
# Compares the downloaded version of FSLogix with the installed version.
Write-Host -Object "AIB Customisation: Comparing FSLogix versions."

$downloadedFslogixVersion = Get-Item $appPath\x64\Release\FSLogixAppsSetup.exe | Select-Object VersionInfo
Write-Host "AIB Customisation: Downloaded FSLogix Version Number $downloadedFsLogixVersion.VersionInfo.FileVersion."

$installedFslogixVersion = Get-Item "C:\Program Files\FSLogix\Apps\frx.exe" | Select-Object VersionInfo
Write-Host -Object "AIB Customisation: Installed FsLogix Version Number: $installedFSlogixVersion.VersionInfo.FileVersion."

if ([version]$downloadedFsLogixVersion.VersionInfo.FileVersion -gt [version]$installedFsLogixVersion.VersionInfo.FileVersion) {
    Write-Host -Object "AIB Customisation: Downloaded FsLogix version is greater than that installed. Updating FSLogix."
    try {
        Write-Host -Object "AIB Customisation: Uninstalling FsLogix."    # This is required to be able to install the latest version.
        Start-Process -FilePath $LocalPath\x64\Release\FSLogixAppsSetup.exe -ArgumentList "/uninstall /quiet /norestart" -Wait -PassThru -ErrorAction Stop -ErrorVariable $lastError
        Write-Host -Object "AIB Customisation: Uninstalled FsLogix."
    }
    catch {
        Write-Host -Object "AIB Customisation Error: Unable to uninstall FSLogix."
        Write-Host -Object $lastError
        Write-Host -Object "Exit code: $LASTEXITCODE"
    }
    try {
        Write-Host "AIB Customisation: Installing FsLogix."
        Start-Process -FilePath $LocalPath\x64\Release\FSLogixAppsSetup.exe -ArgumentList "/install /quiet /norestart" -Wait -PassThru -ErrorAction Stop -ErrorVariable $lastError
        Write-Host -Object "AIB Customisation: Installed FsLogix."
        $installedFsLogixVersion = Get-Item "C:\Program Files\FSLogix\Apps\frx.exe" | Select-Object VersionInfo
        Write-Host "AIB Customisation: Installed FsLogix version number is now: $installedFSLogixVersion.VersionInfo.FileVersion."
        Write-Host "AIB Customisation: Finished Fslogix installer."
    }
    catch {
        Write-Host -Object "AIB Customisation Error: Unable to install FSLogix."
        Write-Host -Object $lastError
        Write-Host -Object "Exit code: $LASTEXITCODE"
    }
} else {
    Write-Host -Object "AIB Customisation: Installed FsLogix version matches the downloaded version. Skipping FsLogix update."
}