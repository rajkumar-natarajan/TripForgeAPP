# 🚀 Deploying TripForge to TestFlight

This guide walks you through getting the **TripForge** iOS app onto **TestFlight**, Apple's beta‑distribution service, so you (and up to 10,000 external testers) can install it on real iPhones/iPads over the air.

There are two paths:

- **Path A — Xcode GUI (recommended for your first upload).** Click‑through, hard to get wrong.
- **Path B — Command line / CI (`release.sh`).** Repeatable, scriptable, good for later.

Both paths produce the same result: a signed build in App Store Connect → TestFlight.

---

## 0. What you need before you start

| Requirement | Notes |
|---|---|
| **Apple Developer Program membership** | **Paid, $99/year.** TestFlight is *not* available on the free personal team. Enroll at <https://developer.apple.com/programs/>. |
| **A Mac with Xcode** | You already have **Xcode 26.5**. ✅ |
| **XcodeGen** | `brew install xcodegen` — this project's `.xcodeproj` is generated. ✅ |
| **Your Team ID** | 10 characters, e.g. `ABCDE12345`. Find it at <https://developer.apple.com/account> → *Membership details*. |
| **An App Store Connect account** | <https://appstoreconnect.apple.com> — comes with your paid membership. |

> ℹ️ **Why paid?** Free Apple IDs can build to a *physically connected* device for 7 days, but TestFlight (over‑the‑air beta distribution) strictly requires the paid Apple Developer Program.

---

## 1. Register the App ID (Bundle ID)

TestFlight needs an App record tied to this app's bundle identifier:

**`com.rajkumar.tripforge`**

1. Go to <https://developer.apple.com/account/resources/identifiers/list>.
2. Click **➕ → App IDs → App**.
3. **Description:** `TripForge`
4. **Bundle ID:** *Explicit* → `com.rajkumar.tripforge`
5. **Capabilities:** you don't need to enable anything special — TripForge only uses **Calendars (EventKit)** and **MapKit**, both of which work without a paid entitlement. Leave defaults. Click **Continue → Register**.

> If you'd rather let Xcode do this, it will offer to register the App ID automatically the first time you enable *Automatically manage signing* (Path A, step 2).

---

## 2. Create the App in App Store Connect

1. Go to <https://appstoreconnect.apple.com/apps>.
2. Click **➕ → New App**.
3. Fill in:
   - **Platform:** iOS
   - **Name:** `TripForge` (must be globally unique across the App Store — if taken, try `TripForge Planner`, etc. This name is only shown to testers on TestFlight, so anything works.)
   - **Primary language:** English (U.S.)
   - **Bundle ID:** select `com.rajkumar.tripforge`
   - **SKU:** any unique string, e.g. `tripforge-ios-001`
   - **User access:** Full Access
4. Click **Create**.

You now have an empty App record. Builds you upload will show up under its **TestFlight** tab.

---

## 3. Set your signing team in the project

The project ships **unsigned** so it builds on the simulator with zero setup. For a device/TestFlight build you must tell it your Team ID. Pick **one**:

**Option 1 — Xcode GUI (easiest):** do it in Path A, step 2 below (just tick a checkbox and choose your team).

**Option 2 — Bake it into `project.yml`:** edit the `DEVELOPMENT_TEAM` line and regenerate:

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: "ABCDE12345"   # <-- your Team ID
```
```bash
xcodegen generate
```

**Option 3 — Pass it on the command line:** `TEAM_ID=ABCDE12345 ./release.sh` (Path B) — no file edits needed.

---

## Path A — Upload with the Xcode GUI (recommended)

### A1. Open the project
```bash
cd TripForgeApp
xcodegen generate      # regenerate the .xcodeproj (it's gitignored)
open TripForge.xcodeproj
```

### A2. Enable signing
1. Select the **TripForge** project in the navigator → **TripForge** target → **Signing & Capabilities** tab.
2. Tick **Automatically manage signing**.
3. **Team:** choose your Apple Developer team from the dropdown.
4. Xcode will create/download the provisioning profile. The "Signing" section should turn green with no errors.

### A3. Pick a real destination
- In the top toolbar's device selector, choose **Any iOS Device (arm64)**.
  *(You can't archive with a Simulator selected — the option will be greyed out.)*

### A4. Archive
- Menu **Product → Archive**.
- Wait for the build. When it finishes, the **Organizer** window opens showing your archive.

> If Archive is greyed out, make sure the destination is *Any iOS Device*, not a simulator.

### A5. Upload to TestFlight
1. In the Organizer, select the new archive → **Distribute App**.
2. Choose **TestFlight & App Store** (or "App Store Connect") → **Next**.
3. **Upload** → keep the default options (*Upload your app's symbols* on) → **Next**.
4. Let Xcode manage signing → **Next** → **Upload**.
5. Wait for "Upload Successful."

### A6. Wait for processing, then invite testers
1. Go to <https://appstoreconnect.apple.com/apps> → **TripForge → TestFlight**.
2. Your build appears with status **Processing** (usually 5–15 min). You'll get an email when it's ready.
3. Once processed, it may say **"Missing Compliance"** — click it and answer the export‑compliance question:
   - TripForge uses only Apple's standard HTTPS/no custom crypto → answer **No** to "Does your app use non‑exempt encryption?" (you can set `ITSAppUsesNonExemptEncryption = NO` in Info to skip this each time — see the Tips section).
4. **Internal testing** (fastest, up to 100 users on your team):
   - Under *Internal Testing*, create a group, add testers (they must be added to your team in App Store Connect users), enable the build.
   - Testers install the **TestFlight** app from the App Store, and the build appears immediately — **no Apple review needed**.
5. **External testing** (up to 10,000 users via public link):
   - Create an external group, add the build. The **first** external build requires a quick **Beta App Review** (usually < 24h). After approval you get a **public invite link** to share with anyone.

🎉 Testers open **TestFlight.app → install TripForge**. Done.

---

## Path B — Upload from the command line (`release.sh`)

Once you've done step 1–2 (App ID + App record) once, you can skip Xcode entirely.

### B1. Get upload credentials (choose one)

**App Store Connect API key (recommended):**
1. <https://appstoreconnect.apple.com/access/integrations/api> → **➕** to generate a key with **App Manager** role.
2. Download the `.p8` file **once** and place it at `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`.
3. Note the **Key ID** and **Issuer ID** shown on that page.

**or — Apple ID + app‑specific password:**
1. <https://account.apple.com> → *Sign‑In & Security → App‑Specific Passwords → Generate*.
2. Save the generated password (looks like `abcd-efgh-ijkl-mnop`).

### B2. Run the release script
```bash
cd TripForgeApp

# Using an API key:
TEAM_ID=ABCDE12345 \
API_KEY_ID=XXXXXXXXXX \
API_ISSUER_ID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee \
MARKETING_VERSION=1.0.0 \
./release.sh

# OR using an Apple ID + app-specific password:
TEAM_ID=ABCDE12345 \
APPLE_ID="you@example.com" \
APP_PASSWORD="abcd-efgh-ijkl-mnop" \
./release.sh
```

The script will:
1. `xcodegen generate`
2. **Archive** the Release configuration for a generic iOS device (signed with your Team ID).
3. **Export** a signed `.ipa` using `ExportOptions.plist`.
4. **Upload** it to App Store Connect via `xcrun altool`.

If you omit the upload credentials, the script still builds the `.ipa` and prints its path so you can drag it into **Transporter.app** (free on the Mac App Store) to upload manually.

### B3. Continue from Path A, step A6 (invite testers).

---

## Version & build numbers

TestFlight rejects a build whose **(version, build number)** pair was already uploaded. Bump one each time:

- **Marketing version** (`MARKETING_VERSION`, e.g. `1.0.1`) — the user‑visible version.
- **Build number** (`CURRENT_PROJECT_VERSION`, e.g. `2`) — must increase within a version.

Set them in `project.yml` (then `xcodegen generate`), or override per build:
```bash
BUILD_NUMBER=$(date +%s) MARKETING_VERSION=1.0.1 TEAM_ID=... ./release.sh
```
(`release.sh` already defaults the build number to a unix timestamp so every run is unique.)

---

## Tips & troubleshooting

| Symptom | Fix |
|---|---|
| **"Archive" is greyed out** | Select **Any iOS Device (arm64)** as the destination, not a Simulator. |
| **"No account for team / no signing certificate"** | Add your Apple ID in **Xcode → Settings → Accounts**, then re‑select the Team in Signing & Capabilities. |
| **"Failed to register bundle identifier"** | The bundle id is taken on another account, or the App ID wasn't created. Do step 1, or change `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` to something unique like `com.<you>.tripforge`. |
| **Build stuck on "Processing" for hours** | Usually clears within 15 min; if it fails you'll get an email. Re‑upload with a new build number. |
| **"Missing Compliance" every upload** | Add `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: "NO"` under the target's `settings.base` in `project.yml`, then regenerate. (Only valid because TripForge uses no non‑standard crypto.) |
| **Icon/asset warnings** | The app already ships a branded **AppIcon** (`TripForge/Assets.xcassets/AppIcon.appiconset`, a single 1024px universal icon that Xcode down-scales). To customize it, replace `AppIcon-1024.png` and rebuild. |
| **`xcodegen: command not found`** | `brew install xcodegen`. |

---

## Quick reference

```bash
# One-time: install tooling
brew install xcodegen

# Every release (GUI path)
cd TripForgeApp && xcodegen generate && open TripForge.xcodeproj
#   → set Team → Any iOS Device → Product > Archive → Distribute > TestFlight

# Every release (script path)
cd TripForgeApp
TEAM_ID=ABCDE12345 API_KEY_ID=XXXX API_ISSUER_ID=uuid ./release.sh
```

Bundle ID: `com.rajkumar.tripforge` · Min iOS: 17.0 · Devices: iPhone + iPad
