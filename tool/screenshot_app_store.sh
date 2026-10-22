#!/bin/zsh
# Screenshot per App Store Connect su simulatore iOS, alla risoluzione nativa.
#
#   EMAIL=... PASSWORD=... [FLUTTER=/percorso/flutter] tool/screenshot_app_store.sh <udid-simulatore> <cartella>
#
# Simulatori consigliati: iPhone 16 Pro Max (6,9", 1320x2868) e
# iPad Pro 13-inch M4 (13", 2064x2752). Il test apre le schermate e stampa
# "SCATTA:<nome>"; questo script cattura lo schermo con simctl, barra di
# stato inclusa (9:41, Wi-Fi e batteria piena come negli screenshot Apple).
set -euo pipefail

udid=${1:?udid del simulatore}
out=${2:?cartella di destinazione}
mkdir -p "$out"
log="$out/flutter_drive.log"

xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null
xcrun simctl status_bar "$udid" override --time 9:41 --dataNetwork wifi \
  --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 \
  --batteryState charged --batteryLevel 100
xcrun simctl ui "$udid" appearance light

: > "$log"
(
  tail -n +1 -F "$log" 2>/dev/null | while IFS= read -r riga; do
    if [[ $riga == *SCATTA:* ]]; then
      nome=${riga##*SCATTA:}
      nome=${nome//[^A-Za-z0-9_-]/}
      xcrun simctl io "$udid" screenshot --type=png "$out/$nome.png" >/dev/null 2>&1 &&
        echo "catturato $out/$nome.png"
    fi
  done
) &
cattura=$!
trap 'kill $cattura 2>/dev/null; pkill -P $cattura 2>/dev/null; xcrun simctl status_bar "$udid" clear' EXIT

"${FLUTTER:-flutter}" drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_app_store_test.dart \
  -d "$udid" \
  --dart-define=SCREENSHOT_APP_STORE=true \
  --dart-define=TEST_EMAIL="$EMAIL" \
  --dart-define=TEST_PASSWORD="$PASSWORD" >> "$log" 2>&1
