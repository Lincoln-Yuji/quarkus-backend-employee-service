#!/bin/bash

# Update system
sudo apt update && sudo apt -y upgrade

# Install Dependencies
sudo apt install -y openjdk-17-jdk openjdk-17-jre maven git

# Clone application repo
git clone https://github.com/Lincoln-Yuji/quarkus-backend-employee-service.git
cd quarkus-backend-employee-service

# Pakcage the Quarkus application
./mvnw clean package -Dquarkus.package.type=uber-jar

# Create the directory for the executable service and copy the packaged app there
sudo mkdir -p /opt/quarkus-backend-employee-service
sudo cp target/quarkus-backend-employee-service-1.0.0-SNAPSHOT-runner.jar /opt/quarkus-backend-employee-service/
sudo cp src/main/resources/application.properties /opt/quarkus-backend-employee-service/

# Copy the service file read by systemd to the system's service directory
sudo cp scripts/quarkus-backend-employee.service /etc/systemd/system
sudo cp scripts/quarkus-backend-config /etc/default/

# Start the service
sudo systemctl daemon-reload
sudo systemctl enable quarkus-backend-employee.service
sudo systemctl start quarkus-backend-employee.service