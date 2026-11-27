#!/bin/zsh
# Legt das App-Passwort im Schlüsselbund dieses Macs ab (Eintrag „LEB-Schreibtisch-App“).
# Danach fragt veroeffentlichen.sh nicht mehr. Entfernen: security delete-generic-password -s LEB-Schreibtisch-App
cd "${0:A:h}/.."
echo "Gib zweimal dein App-Passwort ein. Es wird nur im Schlüsselbund dieses Macs gespeichert."
security add-generic-password -U -a "$USER" -s "LEB-Schreibtisch-App" -l "LEB-Schreibtisch App-Passwort" -T /usr/bin/security -w || exit 1
# gleich prüfen, ob es zur veröffentlichten App passt
PW=$(security find-generic-password -a "$USER" -s "LEB-Schreibtisch-App" -w) || exit 1
T=$(mktemp -d); cp index.html "$T/index.html"
if LEB_PASSWORT="$PW" swift werkzeug/verschluesseln.swift ../LEB-Schreibtisch.html "$T/index.html" >/dev/null; then echo "Gespeichert und geprüft: Das Passwort passt zur veröffentlichten App."
else echo "Achtung: Das Passwort öffnet die veröffentlichte App nicht. Es wurde wieder entfernt."; security delete-generic-password -a "$USER" -s "LEB-Schreibtisch-App" >/dev/null; fi
unset PW; rm -rf "$T"
