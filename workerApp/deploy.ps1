[CmdletBinding()]
[CmdletBinding()]
param (
    [Parameter()]
    [switch] $deployInfra
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 4.0

Set-AzContext -SubscriptionName "Microsoft Azure Sponsorship" -TenantId 0f621c67-98a0-4ed5-b5bd-31a35be41e29
az account set -s "Microsoft Azure Sponsorship"

az bicep build -f ./main.bicep
if ($LASTEXITCODE -ne 0) {
    Write-Error "Bicep build failed - check previous errors"
}

$rgName = "rg-workerapps-test"
$rgLocation = "eastus"
$envName = "endworkerapptest"
$workerAppLocation = "Central US EUAP"

az group create --name $rgName --location $rgLocation

$laWorkspaceName = "workerappslogs"
if ($deployInfra) {
    az monitor log-analytics workspace create -g $rgName -n $laWorkspaceName
    $laWorkspaceId = (& az monitor log-analytics workspace show -g $rgName -n $laWorkspaceName --query customerId -o tsv)
    $laWorkspaceKey = (& az monitor log-analytics workspace get-shared-keys -g $rgName -n $laWorkspaceName --query primarySharedKey -o tsv)

    $aiName = "workerappsai"
    az monitor app-insights component create --app $aiName --location $rgLocation --kind web -g $rgName --application-type web
    $aiKey = $(az resource show -g $rgName -n $aiName --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey -o tsv)

    Write-Host "Creating Worker Apps environment $envName.."
    az workerapp env create -g $rgName `
                            -n $envName `
                            --logs-workspace-id $laWorkspaceId `
                            --logs-workspace-key $laWorkspaceKey `
                            --instrumentation-key $aiKey `
                            --location $workerAppLocation `
                            --no-wait
}

# Wait for environment to be created
& az workerapp env wait -g $rgName -n $envName --created
if ($LASTEXITCODE -ne 0) {
    Write-Error "WorkerApp environment failed to provision"
}
$envId = $(az workerapp env show -g $rgName -n $envName --query id -o tsv)

$params = @{
    workerAppLocation = $workerAppLocation
    kubeEnvironmentId = $envId
}

New-AzResourceGroupDeployment -Name "traffic-control-deploy" `
                              -ResourceGroupName $rgName `
                              -TemplateFile ./main.json `
                              -Verbose `
                              @params
