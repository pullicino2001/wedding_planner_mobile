#!/bin/bash
set -e

APP_ID="1:1059227629456:android:7e950ce6def2dceb526515"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
TESTERS_FILE="testers.txt"

cd "$(dirname "$0")"

# Check Firebase CLI
if ! command -v firebase &>/dev/null; then
  echo "ERROR: Firebase CLI not found. Install it with: npm install -g firebase-tools"
  exit 1
fi

# Prompt for release notes
echo ""
echo "What changed in this build? (press Enter twice when done)"
NOTES=""
while IFS= read -r line; do
  [[ -z "$line" ]] && break
  NOTES+="$line"$'\n'
done
NOTES="${NOTES%$'\n'}"

if [[ -z "$NOTES" ]]; then
  echo "ERROR: Release notes cannot be empty."
  exit 1
fi

# Build release APK
echo ""
echo "Building release APK..."
flutter build apk --release

# Check APK exists
if [[ ! -f "$APK_PATH" ]]; then
  echo "ERROR: APK not found at $APK_PATH"
  exit 1
fi

# Distribute
echo ""
echo "Uploading to Firebase App Distribution..."

if [[ -f "$TESTERS_FILE" ]]; then
  firebase appdistribution:distribute "$APK_PATH" \
    --app "$APP_ID" \
    --release-notes "$NOTES" \
    --testers-file "$TESTERS_FILE"
else
  firebase appdistribution:distribute "$APK_PATH" \
    --app "$APP_ID" \
    --release-notes "$NOTES"
fi

echo ""
echo "Done! Testers will receive an install link by email."
