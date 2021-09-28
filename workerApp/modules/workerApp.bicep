param location string
param kubeEnvironmentId string
param containerImage string
param name string
param ingressIsExternal bool
param ingressTargetPort int
param daprSecrets object
param daprComponents object

resource traffic_control_service 'Microsoft.Web/workerApps@2021-02-01' = {
  name: name
  kind: 'workerapp'
  location: location
  properties: {
    kubeEnvironmentId: kubeEnvironmentId
    configuration: {
      ingress: {
        external: ingressIsExternal 
        targetPort: ingressTargetPort
      }
      // secrets: daprSecrets
    }
    template: {
      containers: [
        {
          image: containerImage
          name: name
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
      dapr: {
        enabled: 'true'
        // appPort: ingressTargetPort
        // components: daprComponents
      }
    }
  }
}
