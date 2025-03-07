# Deployment Guide for Marienschule Backend

This guide explains how to deploy the Marienschule Backend service, which provides WordPress articles to the Marienschule Bielefeld app.

## Prerequisites

- Java 11 or higher (for manual deployment)
- Maven 3.6 or higher (for building)
- Docker and Docker Compose (for containerized deployment)

## Option 1: Manual Deployment

### Building the Application

1. Clone the repository
2. Navigate to the project directory
3. Build the application:
   ```
   mvn clean package
   ```
4. The JAR file will be created in the `target` directory

### Running the Application

1. Create cache directories:
   ```
   mkdir -p cache/images
   ```
2. Run the application:
   ```
   java -jar target/marienschule-backend-1.0.0.jar
   ```
3. The server will start on port 8080 by default

### Running as a Service (Linux)

To run the application as a service on Linux, create a systemd service file:

1. Create a file `/etc/systemd/system/marienschule-backend.service`:
   ```
   [Unit]
   Description=Marienschule Backend Service
   After=network.target

   [Service]
   User=your-user
   WorkingDirectory=/path/to/app
   ExecStart=/usr/bin/java -jar /path/to/app/target/marienschule-backend-1.0.0.jar
   SuccessExitStatus=143
   Restart=always
   RestartSec=5

   [Install]
   WantedBy=multi-user.target
   ```
2. Enable and start the service:
   ```
   sudo systemctl enable marienschule-backend
   sudo systemctl start marienschule-backend
   ```
3. Check the status:
   ```
   sudo systemctl status marienschule-backend
   ```

## Option 2: Docker Deployment

### Using Docker Compose (Recommended)

1. Clone the repository
2. Navigate to the project directory
3. Build the application:
   ```
   mvn clean package
   ```
4. Start the Docker container:
   ```
   docker-compose up -d
   ```
5. The server will be available at http://localhost:8080

### Using Docker Directly

1. Build the application:
   ```
   mvn clean package
   ```
2. Build the Docker image:
   ```
   docker build -t marienschule-backend .
   ```
3. Run the Docker container:
   ```
   docker run -d -p 8080:8080 -v marienschule-cache:/app/cache --name marienschule-backend marienschule-backend
   ```

## Configuring the iOS App

After deploying the backend, update the iOS app's NetworkManager to point to your backend server:

1. Open the `NetworkManager.swift` file
2. Update the `backendBaseURL` variable with your server's address:
   ```swift
   private let backendBaseURL = "http://your-server-address:8080/api"
   ```
3. Rebuild and deploy the iOS app

## Monitoring and Maintenance

### Logs

- For manual deployment:
  ```
  tail -f nohup.out
  ```
- For systemd service:
  ```
  journalctl -u marienschule-backend -f
  ```
- For Docker:
  ```
  docker logs -f marienschule-backend
  ```

### Updating the Application

1. Pull the latest code
2. Build the application:
   ```
   mvn clean package
   ```
3. Restart the service:
   - For manual deployment: Stop the current process and start a new one
   - For systemd service: `sudo systemctl restart marienschule-backend`
   - For Docker Compose: `docker-compose down && docker-compose up -d` 