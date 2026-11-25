# LEB-Schreibtisch

Web-App zum Schreiben von Lernentwicklungsberichten.

- `index.html` ist verschlüsselt (AES-256-GCM, Schlüssel per PBKDF2-SHA256 mit 600 000 Durchläufen aus dem Passwort). Ohne Passwort ist weder das Programm noch sind die Textbausteine lesbar.
- Schülerdaten liegen nie in diesem Repo. Sie bleiben auf dem jeweiligen Gerät bzw. in der eigenen Datendatei; eine Content-Security-Policy verhindert, dass die App Daten sendet oder etwas nachlädt.
- `werkzeug/` enthält die Sperrseite und das Skript zum Verschlüsseln und Hochladen (`zsh werkzeug/veroeffentlichen.sh`).
- `sw.js` hält die verschlüsselte Seite für den Start ohne Internet bereit.
