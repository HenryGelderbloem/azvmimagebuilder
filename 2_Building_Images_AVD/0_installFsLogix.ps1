# Setup of the required environment variables
$appName = 'FsLogix'
$tempDirectory = 'C:\Temp\'
New-Item `
    -Path $tempDirectory `
    -Name $appName `
    -ItemType Directory `
    -ErrorAction SilentlyContinue
$LocalPath = $tempDirectory + $appName

# Download FsLogix
Write-Host 'AIB Customization: Downloading FsLogix'
$fsLogixURL="https://aka.ms/fslogix_download"
$installerFile="fslogix_download.zip"
$outputPath = $LocalPath + '\' + $installerFile
(New-Object System.Net.WebClient).DownloadFile("$fsLogixURL","$outputPath")
Expand-Archive `
    -Path $outputPath `
    -DestinationPath $LocalPath `
    -Force `
    -Verbose
Write-Host 'AIB Customization: Downloading of FsLogix installer finished'

# Comparing FsLogix Version
Write-Host 'AIB Customization: Comparing FsLogix versions'

$downloadedFsLogixVersion = Get-Item $LocalPath\x64\Release\FSLogixAppsSetup.exe | Select-Object VersionInfo
Write-Host 'AIB Customization: Downloaded FsLogix version number:' $downloadedFsLogixVersion.VersionInfo.FileVersion

$installedFsLogixVersion = Get-Item "C:\Program Files\FSLogix\Apps\frx.exe" | Select-Object VersionInfo
Write-Host 'AIB Customization: Installed FsLogix version number:' $installedFSLogixVersion.VersionInfo.FileVersion

if ([version]$downloadedFsLogixVersion.VersionInfo.FileVersion -gt [version]$installedFsLogixVersion.VersionInfo.FileVersion) {
    Write-Host 'AIB Customization: Downloaded FsLogix version is greator than that installed. Updating FsLogix.'
    Write-Host 'AIB Customization: Uninstalling FsLogix'
    Start-Process `
    -FilePath $LocalPath\x64\Release\FSLogixAppsSetup.exe `
    -ArgumentList "/uninstall /quiet /norestart" `
    -Wait `
    -Passthru

    Write-Host 'AIB Customization: Starting Fslogix installer'
    Start-Process `
    -FilePath $LocalPath\x64\Release\FSLogixAppsSetup.exe `
    -ArgumentList "/install /quiet /norestart" `
    -Wait `
    -Passthru

    $installedFsLogixVersion = Get-Item "C:\Program Files\FSLogix\Apps\frx.exe" | Select-Object VersionInfo
    Write-Host 'AIB Customization: Installed FsLogix version number is now:' $installedFSLogixVersion.VersionInfo.FileVersion
    Write-Host 'AIB Customization: Finished Fslogix installer'
} else {
    Write-Host 'AIB Customization: Installed FsLogix version matches the downloaded version. Skipping FsLogix update.'
}