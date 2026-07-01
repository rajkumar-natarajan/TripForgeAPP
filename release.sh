#!/usr/bin/env bash
#
# release.sh — Archive TripForge and upload the build to TestFlight.
#
# Prerequisites (see TESTFLIGHT.md for full details):
#   • Apple Developer Program membership (paid)
#   • An App record created in App Store Connect with bundle id com.rajkumar.tripforge
#   • xcodegen + Xcode command line tools installed
#   • An App Store Connect API key OR an app-specific password for uploading
#
# Usage:
#   TEAM_ID=ABCDE12345 ./release.sh
#
# Optional environment variables:
#   MARKETING_VERSION   Public version string (e.g. 1.0.1). Default: keep project value.
#   BUILD_NUMBER        Build number (must be unique per version). Default: unix timestamp.
#   API_KEY_ID / API_ISSUER_ID   App Store Connect API key credentials for upload.
#   APPLE_ID / APP_PASSWORD      Alternative: Apple ID + app-specific password for upload.
#
set -euo pipefail

SCHEME="TripForge"
PROJECT="TripForge.xcodeproj"
BUNDLE_ID="com.rajkumar.tripforge"
ARCHIVE_PATH="build/TripForge.xcarchive"
EXPORT_DIR="build/export"

: "${TEAM_ID:?Set TEAM_ID to your 10-character Apple Developer Team ID}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%s)}"

echo "==> Regenerating Xcode project"
xcodegen generate

echo "==> Cleaning previous build output"
rm -rf build && mkdir -p build

echo "==> Archiving (Release, generic iOS device)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  ${MARKETING_VERSION:+MARKETING_VERSION="$MARKETING_VERSION"} \
  clean archive

echo "==> Preparing ExportOptions.plist with team id"
sed "s/TEAM_ID_HERE/$TEAM_ID/" ExportOptions.plist > build/ExportOptions.plist

echo "==> Exporting signed .ipa"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist build/ExportOptions.plist

IPA=$(find "$EXPORT_DIR" -name '*.ipa' | head -1)
echo "==> Built: $IPA"

echo "==> Uploading to App Store Connect / TestFlight"
if [[ -n "${API_KEY_ID:-}" && -n "${API_ISSUER_ID:-}" ]]; then
  xcrun altool --upload-app -f "$IPA" -t ios \
    --apiKey "$API_KEY_ID" --apiIssuer "$API_ISSUER_ID"
elif [[ -n "${APPLE_ID:-}" && -n "${APP_PASSWORD:-}" ]]; then
  xcrun altool --upload-app -f "$IPA" -t ios \
    -u "$APPLE_ID" -p "$APP_PASSWORD"
else
  echo "No upload credentials provided."
  echo "IPA is ready at: $IPA"
  echo "Upload it manually with Transporter.app, or set API_KEY_ID/API_ISSUER_ID"
  echo "(or APPLE_ID/APP_PASSWORD) and re-run."
  exit 0
fi

echo "==> Done. The build will appear in App Store Connect > TestFlight in a few minutes."
