# Global Variables
$lastError = @()

# Teams Directory Creation Parameters & Variables
$appName = 'Teams'
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

# Teams WebSocket Download Parameters & Variables
$webSocketsURL = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWQ1UW'
$webSocketsInstallerMsi = 'webSocketSvc.msi'
$outputPath = "$appPath\$webSocketsInstallerMsi"
$InvokeWebRequestParameters = @{
    Uri = $webSocketsURL
    OutFile = $outputPath
    ErrorAction = "Stop"
    ErrorVariable = "lastError"
}

# Teams WebSocket Install Parameters & Variables
$webSocketInstallArgsParameters = @(
    '/i'
    $outputPath
    '/quiet'
    '/norestart'
    "/log $appPath\webSocket.log"
)
$webSocketInstallParameters = @{
    FilePath = "msiexec.exe"
    ArgumentList = $webSocketInstallArgsParameters
    Wait = $true
    ErrorAction = "Stop"
    ErrorVariable = "lastError"
    PassThru = $true
}

# Teams Download Parameters & Variables
$teamsURL = "https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true"
$teamsMsi = 'teams.msi'
$outputPath = $appPath + '\' + $teamsMsi
$teamsWebRequestParameters = @{
    Uri = $teamsURL
    OutFile = $teamsMsi
    ErrorAction = "Stop"
    ErrorVariable = "lastError"
}

#Teams Version Comparison Function
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

# Teams Update Parameters & Variables
$teamsUpdateParameters = @{
    FilePath = "msiexec.exe"
    Args = "/I $outputPath /quiet /norestart /log teamsUpdate.log ALLUSER=1 ALLUSERS=1"
    Wait = $true
    ErrorAction = "Stop"
    ErrorVariable = "lastError"
}

# Teams Media Optimisations Paramets & Variables
$registryPath  = "HKLM:SOFTWARE\Microsoft\Teams"
$optimisationItemPropertyParameters = @{
    registryPath = $registryPath
    vauleName = "IsWVDEnvironment"
    vauleData = "1"
}
$optimisationItemParameters = @{
    registryPath = $registryPath
}

# Teams Optimsation Check Function
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


# Teams Directory Creation
# Creates a new folder in C:\Temp with the name Teams.
try {
    Write-Host -Object "AIB Customisation: Creating Teams directory."
    New-Item @NewItemParameters
    Write-Host -Object "AIB Customisation: Created Teams directory."
}
catch {
    Write-Host -Object "AIB Customisation Error: Unable to create the directory $appPath."
    Write-Host -Object $lastError
    Write-Host -Object "Exit code: $LASTEXITCODE"
}


# Teams WebSocket Download & Install
# Downloads the Teams WebSocket Service into the $appPath directory then updates the WebSocket Service.
try {
    Write-Host -Object "AIB Customisation: Downloading the Microsoft Teams WebSocket Service."
    Invoke-WebRequest @InvokeWebRequestParameters
    Write-Host -Object "AIB Customisation: Downloaded the Microsoft Teams WebSocket Service."
    try {
        Write-Host -Object "AIB Customisation: Updating the Microsoft Teams WebSocket Service"
        Start-Process @webSocketInstallParameters
        Write-Host -Object "AIB Customisation: Updated the Microsoft Teams WebSocket Service"
    }
    catch {
        Write-Host -Object "AIB Customisation Error: Unable to update the Microsoft Teams WebSocket Service."
        Write-Host -Object $lastError
        Write-Host -Object "Exit code: $LASTEXITCODE"    
    }
}
catch {
    Write-Host -Object "AIB Customisation Error: Unable to download the Microsoft Teams WebSocket Service."
    Write-Host -Object $lastError
    Write-Host -Object "Exit code: $LASTEXITCODE"
}


# Teams Update
# Updates the Teams Machine-Wide installer. 
try {
    Write-Host "AIB Customisation: Downloading Microsoft Teams."
    Invoke-WebRequest @teamsWebRequestParameters
    Write-Host "AIB Customisation: Downloaded Microsoft Teams."
}
catch {
    Write-Host -Object "AIB Customisation Error: Unable to download Teams."
    Write-Host -Object $lastError
    Write-Host -Object "Exit code: $LASTEXITCODE"
}


# Teams Version Comparison & Update
# Compares the downloaded version of Teams with the installed version.
try {
    Write-Host -Object "AIB Customisation: Comparing Microsoft Teams versions."
    $downloadedTeamsVersion = Get-MsiVersionNumber -MSIPATH $outputPath
    Write-Host -Object "AIB Customisation: Downloaded Microsoft Teams version number: $downloadedTeamsVersion."
    $installedTeamsVersion = Get-Item "C:\Program Files (x86)\Teams Installer\Teams.exe" | Select-Object VersionInfo
    Write-Host "AIB Customisation: Installed Microsoft Teams version number: $($installedTeamsVersion.VersionInfo.FileVersion)" 
    if ([version]$downloadedTeamsVersion -gt [version]$installedTeamsVersion.VersionInfo.FileVersion) {
        try {
            Write-Host -Object "AIB Customisation: Downloaded Microsoft Teams version is greater than that installed. Updating Microsoft Teams."
            Start-Process @teamsUpdateParameters
            $installedTeamsVersion = Get-Item "C:\Program Files\Teams Installer\Teams.exe" | Select-Object VersionInfo
            Write-Host -Object "AIB Customisation: Installed Microsoft Teams version number is now: $($installedTeamsVersion.VersionInfo.FileVersion)."
            Write-Host -Object "AIB Customisation: Updated Microsoft Teams."
        }
        catch {
            Write-Host -Object "AIB Customisation Error: Unable to update Teams."
            Write-Host -Object $lastError
            Write-Host -Object "Exit code: $LASTEXITCODE"        
        }  else {
            Write-Host -Object "AIB Customisation: Installed Microsoft Teams version matches the downloaded version. Skipping Teams update."
        }      
    }
}
catch {
    Write-Host -Object "AIB Customisation Error: Unable to compare Teams version numbers."
    Write-Host -Object $lastError
    Write-Host -Object "Exit code: $LASTEXITCODE"        
}


# Teams AVD Optimisation Check
# Confirms that AVD Optimisations are enabled, if not, they will be enabled.
try {
    Write-Host -Object "AIB Customisation: Checking if Microsoft Teams Media optimsations are enabled."
    if (!(Test-Path $registryPath)) {
        Write-Host -Object "AIB Customisation: Microsoft Teams media optimisations are not enabled. Enabling Microsoft Teams media optimsations."
        New-Item @optimisationItemParameters
        New-ItemProperty @optimisationItemPropertyParameters        
    } elseif (!(Test-RegistryValue -Path $registryPath -Value $valueName)) {
        Write-Host -Object "AIB Customisation: Microsoft Teams media optimisations are not enabled. Enabling Microsoft Teams media optimsations."
        New-ItemProperty @optimisationItemPropertyParameters
    } else {
        Write-Host "AIB Customisation: Microsoft Teams media optimisation are now enabled."
    }
}
catch {
    Write-Host -Object "AIB Customisation Error: Unable to enable Microsoft Teams optimisations."
    Write-Host -Object $lastError
    Write-Host -Object "Exit code: $LASTEXITCODE"        
}