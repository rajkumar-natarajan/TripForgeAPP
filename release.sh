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
#   TEAM_ID=Y62BAT7CF4 ./release.sh
#
# Optional environment variables:
#   MARKETING_VERSION   Public version string (e.g. 1.0.1). Default: keep project value.
#   BUILD_NUMBER        Build number (must be unique per version). Default: unix timestamp.
#   PROFILE_NAME        Name of an "App Store" distribution provisioning profile you created
#                       in the developer portal. Set this to sign WITHOUT a registered device
#                       (recommended for this team). If unset, automatic signing is used, which
#                       requires at least one registered device.
#   API_KEY_ID / API_ISSUER_ID   App Store Connect API key credentials for upload.
#   APPLE_ID / APP_PASSWORD      Alternative: Apple ID + app-specific password for upload.
#
# Device-free example (after creating an "App Store" profile named "TripForge App Store"):
#   TEAM_ID=Y62BAT7CF4 PROFILE_NAME="TripForge App Store" \
#     APPLE_ID="you@example.com" APP_PASSWORD="abcd-efgh-ijkl-mnop" ./release.sh
#
set -euo pipefail

SCHEME="TripForge"
PROJECT="TripForge.xcodeproj"
BUNDLE_ID="com.rajkumar.tripforge"
ARCHIVE_PATH="build/TripForge.xcarchive"
EXPORT_DIR="build/export"

: "${TEAM_ID:=Y62BAT7CF4}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%s)}"

echo "==> Regenerating Xcode project"
xcodegen generate

echo "==> Cleaning previous build output"
rm -rf build && mkdir -p build

echo "==> Archiving (Release, generic iOS device)"
# If PROFILE_NAME is set, use MANUAL "Apple Distribution" signing with that App Store
# provisioning profile — this needs NO registered device. Otherwise fall back to
# automatic signing (which requires at least one registered device on the team).
SIGN_ARGS=(DEVELOPMENT_TEAM="$TEAM_ID")
if [[ -n "${PROFILE_NAME:-}" ]]; then
  echo "    using manual distribution signing with profile: $PROFILE_NAME"
  SIGN_ARGS+=(
    CODE_SIGN_STYLE=Manual
    CODE_SIGN_IDENTITY="Apple Distribution"
    PROVISIONING_PROFILE_SPECIFIER="$PROFILE_NAME"
  )
  EXPORT_SIGNING="manual"
else
  echo "    using automatic signing (requires a registered device)"
  SIGN_ARGS+=(-allowProvisioningUpdates)
  EXPORT_SIGNING="automatic"
fi

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  ${MARKETING_VERSION:+MARKETING_VERSION="$MARKETING_VERSION"} \
  "${SIGN_ARGS[@]}" \
  clean archive

echo "==> Preparing ExportOptions.plist with team id"
sed -e "s/TEAM_ID_HERE/$TEAM_ID/" \
    -e "s/<string>automatic<\/string>/<string>$EXPORT_SIGNING<\/string>/" \
    ExportOptions.plist > build/ExportOptions.plist
# For manual signing, tell the exporter which profile to use for the bundle id.
if [[ "$EXPORT_SIGNING" == "manual" ]]; then
  /usr/libexec/PlistBuddy -c "Add :provisioningProfiles dict" build/ExportOptions.plist 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :provisioningProfiles:$BUNDLE_ID string $PROFILE_NAME" build/ExportOptions.plist 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :provisioningProfiles:$BUNDLE_ID $PROFILE_NAME" build/ExportOptions.plist
fi

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
