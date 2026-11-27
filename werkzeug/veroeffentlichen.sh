#!/bin/zsh
# Verschlüsselt ../LEB-Schreibtisch.html mit deinem Passwort und lädt sie ins Repo LEB hoch.
# Aufruf im Terminal:  zsh werkzeug/veroeffentlichen.sh
# Das Passwort kommt aus dem Schlüsselbund (einmal hinterlegen mit: zsh werkzeug/passwort-merken.sh), sonst wird es abgefragt.
set -e
cd "${0:A:h}/.."
APP="../LEB-Schreibtisch.html"
[[ -f "$APP" ]] || { echo "App-Datei $APP nicht gefunden."; exit 1 }

if PW=$(security find-generic-password -a "$USER" -s "LEB-Schreibtisch-App" -w 2>/dev/null) && [[ -n "$PW" ]]; then
  echo "Passwort aus dem Schlüsselbund."
  LEB_PASSWORT="$PW" swift werkzeug/verschluesseln.swift "$APP" index.html
  unset PW
else
  swift werkzeug/verschluesseln.swift "$APP" index.html
fi

# Sicherheitsprüfung: Es darf nie eine unverschlüsselte Fassung hochgeladen werden.
if ! grep -q '/\*DATEN\*/{"v":1' index.html || grep -q 'Lernentwicklung' index.html; then
  echo "Abbruch: index.html ist nicht verschlüsselt."; git checkout -- index.html 2>/dev/null; exit 1
fi

git add -A
git -c user.name="LEB" -c user.email="6s2tkg87cn-ux@users.noreply.github.com" commit -q -m "App aktualisiert ($(date +%d.%m.%Y))"
git push -q origin main
echo "Hochgeladen. Die Seite ist in ein bis zwei Minuten aktuell."
