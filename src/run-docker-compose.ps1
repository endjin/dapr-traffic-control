docker build -t src_tcs ./TrafficControlService
docker build -t src_vrs ./VehicleRegistrationService
docker build -t src_fcs ./FineCollectionService
docker build -t src_dapr-config ./dapr-compose
docker build -t src_dtc-mosquitto ./Infrastructure/mosquitto

# launch services
docker-compose up -d

# launch visual simulation
push-location ./VisualSimulation
try {
    dotnet run .\VisualSimulation.csproj
}
finally {
    Pop-Location
}