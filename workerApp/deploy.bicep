param workerAppLocation string = 'centraluseuap'

// stubs
var ServiceBusNamespace = ''
var PolicyName = ''
var Key = ''
var ServiceBus = ''


var daprComponents = [
  // email
  {
    // email
    name: 'sendmail'
    type: 'bindings.smtp'
    version: 'v1'
    metadata: [
      {
        name: 'host'
        value: 'maildev'
      }
      {
        name: 'port'
        value: 25
      }
      {
        name: 'user'
        secretKeyRef: {
          name: 'smtp.user'
          key: 'smtp.user'
        }
      }
      {
        name: 'password'
        secretKeyRef: {
          name: 'smtp.password'
          key: 'smtp.password'
        }
      }
      {
        name: 'skipTLSVerify'
        value: true
      }
    ]
  }
  // entrycam
  {
    name: 'entrycam'
    type: 'bindings.azure.storagequeues'
    version: 'v1'
    metadata: [
      {
        name: 'storageAccount'
        value: 'account1'
      }
      {
        name: 'storageAccessKey'
        value: '<key>'
      }
      {
        name: 'queue'
        value: 'trafficcontrol/entrycam'
      }
      {
        name: 'ttlInSeconds'
        value: '60'
      }
    ]
  }
  // exitcam
  {
    name: 'exitcam'
    type: 'bindings.azure.storagequeues'
    version: 'v1'
    metadata: [
      {
        name: 'storageAccount'
        value: 'account1'
      }
      {
        name: 'storageAccessKey'
        value: '<key>'
      }
      {
        name: 'queue'
        value: 'trafficcontrol/exitcam'
      }
      {
        name: 'ttlInSeconds'
        value: '60'
      }
    ]
  }
  // pubsub
  {
    name: 'pubsub'
    type: 'pubsub.azure.servicebus'
    version: 'v1'
    metadata: [
      {
        name: 'connectionString'
        value: 'Endpoint=sb://${ServiceBusNamespace}.servicebus.windows.net/;SharedAccessKeyName=${PolicyName};SharedAccessKey=${Key};EntityPath=${ServiceBus}'
      }
    ]
  }
  // secrets
  {
    name: 'trafficcontrol-secrets'
    type: 'secretstores.azure.keyvault'
    version: 'v1'
    metadata: [
      {
        name: 'vaultName'
        value: '[your_keyvault_name]'
      }
      {
        name: 'azureTenantId'
        value: '[your_tenant_id]'
      }
      {
        name: 'azureClientId'
        value: '[your_client_id]'
      }
      {
        name: 'azureClientSecret'
        value : '[your_client_secret]'
      }
    ]
  }
  // state
  {
    name: 'statestore'
    type: 'state.azure.blobstorage'
    version: 'v1'
    metadata: [
      {
        name: 'accountName'
        value: '[your_account_name]'
      }
      {
        name: 'accountKey'
        value: '[your_account_key]'
      }
      {
        name: 'containerName'
        value: '[your_container_name]'
      }
    ]
  }
]

var daprSecrets = [
  {
    name: 'smtp.user'
    value: '_username'
  }
  {
    name: 'smtp.password'
    value: '_password'
  }
]

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'workerappslogs'
  location: resourceGroup().location
}

resource storage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'trafficcontrolstorage'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    
  }
}


resource kubeEnvironment 'Microsoft.Web/kubeEnvironments@2021-01-15' = {
  name: 'endjinworkerappsenv'
  location: workerAppLocation
  properties: {
    appLogsConfiguration: {
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
      }
    }
  }
}

resource smtp_worker 'Microsoft.Web/workerApps@2021-02-01' = {
  name: 'maildev'
  kind: 'workerapp'
  location: workerAppLocation
  properties: {
    kubeEnvironmentId: kubeEnvironment.id
    configuration: {
      ingress: {
        external: false
        targetPort: 25
      }
      secrets: daprSecrets
    }
    template: {
      containers: [
        {
          image: 'maildev/maildev:latest'
          name: 'maildev'
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
      dapr: {
        enabled: 'false'
      }
    }
  }
}

resource traffic_control_service 'Microsoft.Web/workerApps@2021-02-01' = {
  name: 'tcs'
  kind: 'workerapp'
  location: workerAppLocation
  properties: {
    kubeEnvironmentId: kubeEnvironment.id
    configuration: {
      ingress: {
        external: false
        targetPort: 00
      }
      secrets: daprSecrets
    }
    template: {
      containers: [
        {
          image: 'maildev/maildev:latest'
          name: 'maildev'
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
      dapr: {
        enabled: 'true'
        appPort: 0
        components: daprComponents
      }
    }
  }
}
