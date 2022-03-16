# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with user-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId (Get-AutomationVariable -Name 'userAssignedIdentityAccountId')).context

# Set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext


# Set the required automation account variables 
Set-AutomationVariable `
    -Name 'imageTemplateName' `
    -Value ("imgtemp-avd" + [DateTime]::UtcNow.ToString('yyyyMMdd'))
Set-AutomationVariable `
    -Name 'imageDefVersionNumber' `
    -Value ([DateTime]::UtcNow.ToString('yyyy.MM.dd'))

# Get the template into a variable for use later on
$templateUrl = "https://raw.githubusercontent.com/HenryGelderbloem/azvmimagebuilder/main/2_Building_Images_AVD/imageTemplate.json"
$templateFilePath = "imageTemplate.json"

# Downloading the template
Invoke-WebRequest -Uri $templateUrl -OutFile $templateFilePath -UseBasicParsing

# Submitting the template
New-AzResourceGroupDeployment `
	-ResourceGroupName (Get-AutomationVariable -Name 'imageResourceGroup') `
	-TemplateFile $templateFilePath `
    -TemplateParameterObject @{
        "userManagedIdentityResourceGroup" = (Get-AutomationVariable -Name 'userManagedIdentityResourceGroup')
        "userManagedIdentityName" = (Get-AutomationVariable -Name 'userManagedIdentityName')
        "imageTemplateName" = (Get-AutomationVariable -Name 'imageTemplateName')
        "galleryImageResourceGroup" = (Get-AutomationVariable -Name 'galleryImageResourceGroup')
        "galleryImageName" = (Get-AutomationVariable -Name 'galleryImageName')
        "imageDefName" = (Get-AutomationVariable -Name 'imageDefName')
        "imageDefVersionNumber" = (Get-AutomationVariable -Name 'imageDefVersionNumber')
        }

# Building the image
Start-AzImageBuilderTemplate `
    -ResourceGroupName (Get-AutomationVariable -Name 'imageResourceGroup') `
    -Name (Get-AutomationVariable -Name 'imageTemplateName') `
    -NoWait