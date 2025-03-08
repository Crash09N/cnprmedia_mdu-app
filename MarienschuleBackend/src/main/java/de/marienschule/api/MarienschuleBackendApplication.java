package de.marienschule.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Hauptklasse für die Marienschule Backend-Anwendung
 * Startet den Spring Boot-Server mit allen Diensten
 */
@SpringBootApplication
public class MarienschuleBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(MarienschuleBackendApplication.class, args);
    }
} 