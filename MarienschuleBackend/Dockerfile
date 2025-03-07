FROM openjdk:11-jre-slim

WORKDIR /app

# Copy the JAR file
COPY target/marienschule-backend-1.0.0.jar /app/app.jar

# Create cache directories
RUN mkdir -p /app/cache/images

# Expose the port
EXPOSE 8080

# Run the application
CMD ["java", "-jar", "/app/app.jar"] 