#!/usr/bin/env bash
#
# upload.sh — Upload an already-built TripForge .ipa to App Store Connect / TestFlight.
#
# Use this when the signed .ipa already exists (e.g. build/export/TripForge.ipa produced
# by release.sh or by Xcode's Organizer "Export") and you just need to send it to TestFlight.
#
# Credentials (choose one):
#   • App Store Connect API key:  API_KEY_ID + API_ISSUER_ID
#       (place AuthKey_<KEY_ID>.p8 in ~/.appstoreconnect/private_keys/)
#   • Apple ID + app-specific password:  APPLE_ID + APP_PASSWORD
#       (generate at https://account.apple.com > Sign-In & Security > App-Specific Passwords)
#
# Usage:
#   APPLE_ID="you@example.com" APP_PASSWORD="abcd-efgh-ijkl-mnop" ./upload.sh
#   # or point at a specific ipa:
#   IPA=build/export/TripForge.ipa APPLE_ID=... APP_PASSWORD=... ./upload.sh
#
set -euo pipefail

IPA="${IPA:-$(find build/export -name '*.ipa' 2>/dev/null | head -1)}"
if [[ -z "${IPA:-}" || ! -f "$IPA" ]]; then
  echo "No .ipa found. Build one first with ./release.sh, or set IPA=/path/to/App.ipa" >&2
  exit 1
fi
echo "==> Uploading: $IPA"

# Optional: validate first (catches most App Store rejections before upload).
if [[ "${VALIDATE:-1}" == "1" ]]; then
  echo "==> Validating..."
  if [[ -n "${API_KEY_ID:-}" && -n "${API_ISSUER_ID:-}" ]]; then
    xcrun altool --validate-app -f "$IPA" -t ios \
      --apiKey "$API_KEY_ID" --apiIssuer "$API_ISSUER_ID" || true
  elif [[ -n "${APPLE_ID:-}" && -n "${APP_PASSWORD:-}" ]]; then
    xcrun altool --validate-app -f "$IPA" -t ios \
      -u "$APPLE_ID" -p "$APP_PASSWORD" || true
  fi
fi

echo "==> Uploading to App Store Connect / TestFlight"
if [[ -n "${API_KEY_ID:-}" && -n "${API_ISSUER_ID:-}" ]]; then
  xcrun altool --upload-app -f "$IPA" -t ios \
    --apiKey "$API_KEY_ID" --apiIssuer "$API_ISSUER_ID"
elif [[ -n "${APPLE_ID:-}" && -n "${APP_PASSWORD:-}" ]]; then
  xcrun altool --upload-app -f "$IPA" -t ios \
    -u "$APPLE_ID" -p "$APP_PASSWORD"
else
  echo "No credentials provided."
  echo "Set API_KEY_ID + API_ISSUER_ID, or APPLE_ID + APP_PASSWORD, and re-run."
  echo "Or drag $IPA into Transporter.app (free on the Mac App Store) to upload."
  exit 1
fi

echo "==> Done. The build appears in App Store Connect > TestFlight in a few minutes."
