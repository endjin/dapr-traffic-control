$ErrorActionPreference = "Stop"
Set-StrictMode -Version 4.0

Set-AzContext -SubscriptionName "Microsoft Azure Sponsorship" -TenantId 0f621c67-98a0-4ed5-b5bd-31a35be41e29

az bicep build -f ./deploy.bicep
if ($LASTEXITCODE -ne 0) {
    Write-Error "Bicep buld failed - check previous errors"
}

$params = @{
    # Location = "centraluseuap"
}

New-AzResourceGroupDeployment -Name "traffic-dontrol-deploy" `
                              -ResourceGroupName "rg-workerapps-test" `
                              -TemplateFile ./deploy.json `
                              -Verbose `
                              @params
