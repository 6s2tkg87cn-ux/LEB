#!/bin/zsh
# Verschlüsselt ../LEB-Schreibtisch.html mit deinem Passwort und lädt sie ins Repo LEB hoch.
# Aufruf im Terminal:  zsh werkzeug/veroeffentlichen.sh
set -e
cd "${0:A:h}/.."
APP="../LEB-Schreibtisch.html"
[[ -f "$APP" ]] || { echo "App-Datei $APP nicht gefunden."; exit 1 }

swift werkzeug/verschluesseln.swift "$APP" index.html

# Sicherheitsprüfung: Es darf nie eine unverschlüsselte Fassung hochgeladen werden.
if ! grep -q '/\*DATEN\*/{"v":1' index.html || grep -q 'Lernentwicklung' index.html; then
  echo "Abbruch: index.html ist nicht verschlüsselt."; exit 1
fi

git add -A
git -c user.name="LEB" -c user.email="6s2tkg87cn-ux@users.noreply.github.com" commit -q -m "App aktualisiert ($(date +%d.%m.%Y))"

if [[ -f .git/leb-erstveroeffentlichung ]]; then
  # Erstes Mal: ersetzt den früheren, unverschlüsselten Upload vollständig.
  git push -q --force -u origin main && rm .git/leb-erstveroeffentlichung
else
  git push -q origin main
fi
echo "Hochgeladen. Die Seite ist in ein bis zwei Minuten aktuell."
