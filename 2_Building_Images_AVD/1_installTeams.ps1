# Setup of the required environment variables
$appName = 'Teams'
$tempDirectory = 'C:\Temp\'
New-Item `
    -Path $tempDirectory `
    -Name $appName `
    -ItemType Directory `
    -ErrorAction SilentlyContinue
$LocalPath = $tempDirectory + $appName

# Update Microsoft Teams WebSocket Service
Write-Host 'AIB Customisation: Downloading the Microsoft Teams WebSocket Service'
$webSocketsURL = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWQ1UW'
$webSocketsInstallerMsi = 'webSocketSvc.msi'
$outputPath = $LocalPath + '\' + $webSocketsInstallerMsi
(New-Object System.Net.WebClient).DownloadFile("$webSocketsURL","$outputPath")
Write-Host 'AIB Customisation: Downloading of the Microsoft Teams WebSocket Service finished'

Write-Host 'AIB Customisation: Updating the Microsoft Teams WebSocket Service'
Start-Process `
    -FilePath msiexec.exe `
    -Args "/i $outputPath /quiet /norestart /log webSocket.log" `
    -Wait
Write-Host 'AIB Customisation: Finished updating the Microsoft Teams WebSocket Service' 

# Update Microsoft Teams
Write-Host 'AIB Customisation: Downloading Microsoft Teams'
$teamsURL = 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true'
$teamsMsi = 'teams.msi'
$outputPath = $LocalPath + '\' + $teamsMsi
(New-Object System.Net.WebClient).DownloadFile("$teamsURL","$outputPath")
Write-Host 'AIB Customisation: Downloading of Microsoft Teams installer finished'

Write-Host 'AIB Customisation: Comparing Microsoft Teams versions'
function Get-MsiVersionNumber {
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo] $MSIPATH
    )
    try { 
        $WindowsInstaller = New-Object -com WindowsInstaller.Installer 
        $Database = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($MSIPATH.FullName, 0)) 
        $Query = "SELECT Value FROM Property WHERE Property = 'ProductVersion'"
        $View = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $Database, ($Query)) 
        $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null) | Out-Null
        $Record = $View.GetType().InvokeMember( "Fetch", "InvokeMethod", $Null, $View, $Null ) 
        $Version = $Record.GetType().InvokeMember( "StringData", "GetProperty", $Null, $Record, 1 ) 
        return $Version
    } catch { 
        throw "Failed to get MSI file version: {0}." -f $_
    }   
}
$downloadedTeamsVersion = Get-MsiVersionNumber -MSIPATH $outputPath
Write-Host 'AIB Customisation: Downloaded Microsoft Teams version number:' $downloadedTeamsVersion
$installedTeamsVersion = Get-Item "C:\Program Files (x86)\Teams Installer\Teams.exe" | Select-Object VersionInfo
Write-Host 'AIB Customisation: Installed Microsoft Teams version number:' $installedTeamsVersion.VersionInfo.FileVersion

if ([version]$downloadedTeamsVersion -gt [version]$installedTeamsVersion.VersionInfo.FileVersion) {
    Write-Host 'AIB Customisation: Downloaded Microsoft Teams version is greator than that installed. Updating Microsoft Teams.'
    Start-Process `
    -FilePath msiexec.exe `
    -Args "/I $outputPath /quiet /norestart /log teamsUpdate.log ALLUSER=1 ALLUSERS=1" `
    -Wait
    $installedTeamsVersion = Get-Item "C:\Program Files\Teams Installer\Teams.exe" | Select-Object VersionInfo
    Write-Host 'AIB Customisation: Installed Microsoft Teams version number is now:' $installedTeamsVersion.VersionInfo.FileVersion
    Write-Host 'AIB Customisation: Finished updating Microsoft Teams' 
    } else {
    Write-Host 'AIB Customisation: Installed Microsoft Teams version matches the downloaded version. Skipping Teams update.'
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
} elseif (!(Test-RegistryValue -Path $registryPath -Value $valueName)) {
    Write-Host 'AIB Customisation: Microsoft Teams media optimisation not set. Enabling Microsoft Teams media optimsation'
    New-ItemProperty `
        -Path $registryPath `
        -Name $valueName `
        -Value $vauleData `
        -PropertyType Dword
} else {
    Write-Host 'AIB Customisation: Microsoft Teams media optimisation set correctly'
}