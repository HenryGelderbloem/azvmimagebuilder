# Global Variables
$lastError = @()

# FSLogix Directory Creation Parameters & Variables
$appName = 'FSLogix'
$tempDirectory = 'C:\Temp\'
$appPath = $tempDirectory + $appName
$NewItemParameters = @{
    Path = $tempDirectory
    Name = $appName
    ItemType = "Directory"
    ErrorAction = "Stop"
    ErrorVariable = "lastError"
    Force = $true
}

# FSLogix Download Parameters & Variables
$FSLogixURI = "https://aka.ms/fslogix_download"
$downloadedFile = "fslogix_download.zip"
$InvokeWebRequestParameters = @{
    Uri = $FSLogixURI
    OutFile = $downloadedFile
    ErrorAction = "Stop"
    ErrorVariable = "lastError"
}

# FSLogix Unzip Parameters & Variables
$ExpandArchiveParameters = @{
    Path = $downloadedFile
    DestinationPath = $appPath
    Force = $true
    Verbose = $true
    ErrorAction = "Stop"
    ErrorVariable = "lastError"
}

# FSLogix Uninstall Parameters & Variables
$UninstallFSLogixParameters = @{
    FilePath = "$appPath\x64\Release\FSLogixAppsSetup.exe"
    ArgumentList = "/uninstall /quiet /norestart"
    Wait = $true
    Passthru = $true
    ErrorAction = "Stop"
    ErrorVariable = "lastError"
}

# FSLogix Install Parameters & Variables
$InstallFSLogixParameters = @{
    FilePath = "$appPath\x64\Release\FSLogixAppsSetup.exe"
    ArgumentList = "/install /quiet /norestart"
    Wait = $true
    Passthru = $true
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

$downloadedFSLogixVersion = Get-Item $appPath\x64\Release\FSLogixAppsSetup.exe | Select-Object VersionInfo
Write-Host "AIB Customisation: Downloaded FSLogix Version Number $($downloadedFSLogixVersion.VersionInfo.FileVersion)."

$installedFSLogixVersion = Get-Item "C:\Program Files\FSLogix\Apps\frx.exe" -ErrorAction SilentlyContinue | Select-Object VersionInfo
Write-Host -Object "AIB Customisation: Installed FsLogix Version Number: $($installedFSLogixVersion.VersionInfo.FileVersion)."

if ([version]$downloadedFSLogixVersion.VersionInfo.FileVersion -gt [version]$installedFSLogixVersion.VersionInfo.FileVersion) {
    Write-Host -Object "AIB Customisation: Downloaded FSLogix version is greater than that installed. Updating FSLogix."
    try {
        Write-Host -Object "AIB Customisation: Uninstalling FSLogix."    # This is required to be able to install the latest version, if an update is required.
        Start-Process @UninstallFSLogixParameters
        Write-Host -Object "AIB Customisation: Uninstalled FSLogix."
    }
    catch {
        Write-Host -Object "AIB Customisation Error: Unable to uninstall FSLogix."
        Write-Host -Object $lastError
        Write-Host -Object "Exit code: $LASTEXITCODE"
    }
    try {
        Write-Host "AIB Customisation: Installing FSLogix."
        Start-Process @InstallFSLogixParameters
        Write-Host -Object "AIB Customisation: Installed FSLogix."
        $installedFSLogixVersion = Get-Item "C:\Program Files\FSLogix\Apps\frx.exe" | Select-Object VersionInfo
        Write-Host "AIB Customisation: Installed FSLogix version number is now: $($installedFSLogixVersion.VersionInfo.FileVersion)."
        Write-Host "AIB Customisation: Finished installing FSLogix."
    }
    catch {
        Write-Host -Object "AIB Customisation Error: Unable to install FSLogix."
        Write-Host -Object $lastError
        Write-Host -Object "Exit code: $LASTEXITCODE"
    }
} else {
    Write-Host -Object "AIB Customisation: Installed FSLogix version matches the downloaded version. Skipping FSLogix update."
}