# Setup of the required environment variables
$appName = 'VDOT'
$tempDirectory = 'C:\Temp\'
New-Item `
  -Path $tempDirectory `
  -Name $appName `
  -ItemType Directory `
  -ErrorAction SilentlyContinue
$localPath = $tempDirectory + $appName

# Download Virtual Desktop Optimisation Tool (VDOT)
Write-Host 'AIB Customisation: Downloading VDOT Files'
$vdotUrl = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/master.zip'
$installerFile = 'Windows_10_VDI_Optimize-master.zip'
$outputPath = $localPath + '\' + $installerFile
(New-Object System.Net.WebClient).DownloadFile("$vdotUrl","$outputPath")
Expand-Archive `
  -Path $outputPath `
  -DestinationPath $localPath `
  -Force `
  -Verbose
$vdotScriptUrl = 'https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/master/Win10_VirtualDesktop_Optimize.ps1'
$scriptFile = 'optimise.ps1'
$outputScriptPath = $localPath + '\' + $scriptFile 
(New-Object System.Net.WebClient).DownloadFile("$vdotScriptUrl","$outputScriptPath")
Write-Host 'AIB Customisation: Downloading of VDOT Files finished'

# Optimising Windows 
Write-Host 'AIB Customisation: Starting OS Optimisations script'
Set-ExecutionPolicy `
  -ExecutionPolicy RemoteSigned `
  -Force `
  -Verbose
Set-Location `
  -Path $localPath\Virtual-Desktop-Optimization-Tool-main
  
# Patch: Overide the Windows_VDOT.ps1 setting - 'Set-NetAdapterAdvancedProperty' as this is not a Hyper-V environment.
Write-Host 'AIB Customisation Patch: Disabling Set-NetAdapterAdvancedProperty'
$scriptFilePath = $outputScriptPath
((Get-Content `
  -Path $scriptFilePath `
  -Raw) `
  -replace 'Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB','#Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB') | `
  Set-Content `
    -Path $scriptFilePath

# Patch: overide the REG UNLOAD, needs GC before, otherwise will Access Deny unload(see readme.md)
[System.Collections.ArrayList]$file = Get-Content $scriptFilePath
$insert = @()
for ($i=0; $i -lt $file.count; $i++) {
  if ($file[$i] -like "*& REG UNLOAD HKLM\DEFAULT*") {
    $insert += $i-1 
  }
}

# Add GC and sleep
$insert | ForEach-Object { $file.insert($_,"                 Write-Host 'Patch closing handles and runnng GC before reg unload' `n              `$newKey.Handle.close()` `n              [gc]::collect() `n                Start-Sleep -Seconds 15 ") }
Set-Content $outputScriptPath $file 


# Run script
.\Windows_VDOT.ps1 `
  -WindowsVersion 2009 `
  -Verbose
Write-Host 'AIB Customisation: Finished OS Optimisations script'