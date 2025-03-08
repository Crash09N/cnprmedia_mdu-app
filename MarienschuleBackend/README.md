# Marienschule Backend

Dieses Backend bietet REST-API-Endpunkte für die MdU App, um Benutzer gegen eine Nextcloud-Instanz zu authentifizieren und Benutzerdaten zu verwalten.

## Funktionen

- Authentifizierung gegen Nextcloud
- Extraktion von Benutzerdaten (Name, E-Mail, Klasse)
- Speicherung der Daten in JSON-Dateien
- REST-API-Endpunkte für die iOS-App

## Voraussetzungen

- Java 11 oder höher
- Maven

## Konfiguration

Die Konfiguration erfolgt über die Datei `src/main/resources/application.properties`. Hier können Sie das Datenverzeichnis und andere Einstellungen anpassen.

```properties
# Datenverzeichnis für JSON-Dateien
app.data.directory=./data
```

## Datenspeicherung

Die Benutzerdaten werden in einer JSON-Datei im konfigurierten Datenverzeichnis gespeichert. Die Datei wird automatisch erstellt, wenn sie nicht existiert.

- Benutzerdaten: `data/users.json`

## Starten des Backends

Sie können das Backend mit dem folgenden Befehl starten:

```bash
./start.sh
```

Oder manuell mit Maven:

```bash
mvn spring-boot:run
```

Alternativ können Sie es auch als JAR-Datei bauen und ausführen:

```bash
mvn clean package
java -jar target/marienschule-backend-1.0.0.jar
```

## API-Endpunkte

### Anmeldung

```
POST /api/login
```

Anfrage:
```json
{
  "username": "benutzername",
  "password": "passwort"
}
```

Antwort:
```json
{
  "success": true,
  "user_id": 1,
  "username": "benutzername",
  "first_name": "Max",
  "last_name": "Mustermann",
  "email": "max.mustermann@example.com",
  "school_class": "Q1",
  "webdav_url": "https://nextcloud.example.com/remote.php/dav/files/benutzername/"
}
```

### Benutzerdaten aktualisieren

```
POST /api/refresh
```

Anfrage:
```json
{
  "username": "benutzername",
  "password": "passwort"
}
```

Antwort: (wie bei /api/login)

### Benutzerdaten abrufen

```
POST /api/user
```

Anfrage:
```json
{
  "username": "benutzername"
}
```

Antwort: (wie bei /api/login) 