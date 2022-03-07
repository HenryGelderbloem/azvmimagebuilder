# install webSoc svc - To-do
Write-Host 'AIB Customisation: Downloading the Teams WebSocket Service'
$webSocketsURL = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt'
$webSocketsInstallerMsi = 'webSocketSvc.msi'
$outputPath = $LocalPath + '\' + $webSocketsInstallerMsi
(New-Object System.Net.WebClient).DownloadFile("$webSocketsURL","$outputPath")
Write-Host 'AIB Customisation: Downloading of the Teams WebSocket Service finished'

Write-Host 'AIB Customisation: Comparing Teams WebSocket Service versions'
$downloadedWebSocketVersion = Get-Item $outputPath | Select-Object VersionInfo
Write-Host 'AIB Customisation: Downloaded version number:' $downloadedWebSocketVersion.VersionInfo.FileVersion
$installedWebSocketVersion = Get-Item "???" | Select-Object VersionInfo
Write-Host 'AIB Customisation: Installed version number:' $installedWebSocketVersion.VersionInfo.FileVersion

if ([version]$downloadedWebSocketVersion.VersionInfo.FileVersion -gt [version]$installedWebSocketVersion.VersionInfo.FileVersion) {
    Write-Host 'AIB Customisation: Downloaded version is greator than that installed. Updating Microsoft Teams.'
    Start-Process `
    -FilePath msiexec.exe `
    -Args "/I $outputPath /quiet /norestart /log webSocket.log" `
    -Wait
    $installedWebSocketVersion = Get-Item "???" | Select-Object VersionInfo
    Write-Host 'AIB Customisation: Installed version number is now:' $installedWebSocketVersion.VersionInfo.FileVersion
    Write-Host 'AIB Customisation: Finished updating the Teams WebSocket Services' 
    } else {
    Write-Host 'AIB Customisation: Installed version matches the downloaded version. Skipping WebSocket Service update.'
}

# Update Microsoft Teams
Write-Host 'AIB Customisation: Downloading Microsoft Teams'
$teamsURL = 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true'
$teamsMsi = 'teams.msi'
$outputPath = $LocalPath + '\' + $teamsMsi
(New-Object System.Net.WebClient).DownloadFile("$teamsURL","$outputPath")
Write-Host 'AIB Customisation: Downloading of Microsoft Teams installer finished'

Write-Host 'AIB Customisation: Comparing Microsoft Teams versions'
$downloadedTeamsVersion = Get-Item $outputPath | Select-Object VersionInfo
Write-Host 'AIB Customisation: Downloaded version number:' $downloadedTeamsVersion.VersionInfo.FileVersion
$installedTeamsVersion = Get-Item "C:\Program Files\Teams Installer\Teams.exe" | Select-Object VersionInfo
Write-Host 'AIB Customisation: Installed version number:' $installedTeamsVersion.VersionInfo.FileVersion

if ([version]$downloadedTeamsVersion.VersionInfo.FileVersion -gt [version]$installedTeamsVersion.VersionInfo.FileVersion) {
    Write-Host 'AIB Customisation: Downloaded version is greator than that installed. Updating Microsoft Teams.'
    Start-Process `
    -FilePath msiexec.exe `
    -Args "/I $outputPath /quiet /norestart /log teamsUpdate.log ALLUSER=1 ALLUSERS=1" `
    -Wait
    $installedTeamsVersion = Get-Item "C:\Program Files\Teams Installer\Teams.exe" | Select-Object VersionInfo
    Write-Host 'AIB Customisation: Installed version number is now:' $installedTeamsVersion.VersionInfo.FileVersion
    Write-Host 'AIB Customisation: Finished updating MS Teams' 
    } else {
    Write-Host 'AIB Customisation: Installed version matches the downloaded version. Skipping Teams update.'
}

# Confirm registry is set correctly
Write-Host 'AIB Customisation: Checking if Microsoft Teams media optimsation is set'
$registryPath = "HKLM:SOFTWARE\Microsoft\Teams"
$valueName = "IsWVDEnvironment"
$vauleData = "1"
function Test-RegistryValue {
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Path,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Value
    )
    try {

        Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
        return $true
         }
    catch {
        return $false
        }
}

if (!(Test-Path $registryPath)) {
    Write-Host 'AIB Customisation: Microsoft Teams media optimisation not set. Enabling Microsoft Teams media optimsation'
    New-Item `
        -Path $registryPath `
        -Force | Out-Null
    New-ItemProperty `
        -Path $registryPath `
        -Name $valueName `
        -Value $vauleData `
        -PropertyType Dword
        -Force | Out-Null
} elseif (!(Test-RegistryValue -Path $registryPath -Value $valueName)) {
    Write-Host 'AIB Customisation: Microsoft Teams media optimisation not set. Enabling Microsoft Teams media optimsation'
} else {
    Write-Host 'AIB Customisation: Microsoft Teams media optimisation set correctly'
}