<div align="center">

# 🧭 TripForge for iOS

### Build perfect trips in minutes — now a native iOS app

**AI Itineraries • Live Maps • Zero Stress**

A beautiful, **native SwiftUI** trip planner. Describe your trip in plain language and get a
complete, optimized, day-by-day itinerary — with **MapKit maps**, budgets, weather, packing
lists, and one-tap **Apple Calendar** export.

100% **offline & free** — no accounts, no API keys, nothing leaves your device.

</div>

---

## ✨ Highlights

- 🗣️ **Natural-language planning** — type *"5 days in Tokyo in July with my wife, love food and anime, budget $3000"* and get a full itinerary.
- 🧠 **On-device planner** — a deterministic Swift engine with a curated bank of real places (Tokyo, Paris, New York, Rome, Barcelona, Bali) plus a smart generic planner for anywhere else. No network required.
- 🗺️ **Native MapKit** — every day's stops pinned and routed on a real map, with one-tap "Open route in Maps" walking directions. **No Google Maps key needed.**
- 📅 **Apple Calendar export** — add your whole itinerary to the system calendar via **EventKit** (with 30-min reminders), or share a universal `.ics` file.
- 💰 **Budget tracking**, 🎒 **auto packing lists**, ✅ **templates** (Honeymoon / Solo / Family / Foodie).
- ✏️ **Editable itinerary** — reorder, add, and remove activities; check off packing items.
- 💾 **Private by design** — trips persist to a local JSON file in the app's Documents directory.

> This is the native companion to the [TripForge web app](https://github.com/rajkumar-natarajan/TripForge). The offline planning engine and design language are faithfully ported to Swift.

---

## 📱 Requirements

- **Xcode 15+** (built and verified with Xcode 26)
- **iOS 17.0+** target
- [**XcodeGen**](https://github.com/yonaskolb/XcodeGen) to generate the project (`brew install xcodegen`)

---

## 🚀 Run it

```bash
# 1. Generate the Xcode project from project.yml
xcodegen generate

# 2. Open in Xcode
open TripForge.xcodeproj

# 3. Select an iPhone simulator and press ⌘R
```

Or build & launch from the command line:

```bash
xcodegen generate
xcodebuild -project TripForge.xcodeproj -scheme TripForge \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build

xcrun simctl boot "iPhone 15"
xcrun simctl install booted \
  "$(find ~/Library/Developer/Xcode/DerivedData -path '*Debug-iphonesimulator/TripForge.app' -type d | head -1)"
xcrun simctl launch booted com.rajkumar.tripforge
```

> The committed repo does **not** include `TripForge.xcodeproj` (it's generated). Always run
> `xcodegen generate` first after cloning.

---

## 📦 Ship it to TestFlight

Ready to put TripForge on real devices for beta testers? See the full step‑by‑step
**[TestFlight deployment guide → `TESTFLIGHT.md`](TESTFLIGHT.md)**.

It covers both the **Xcode GUI** path and a scripted **command‑line** path
([`release.sh`](release.sh)): registering the App ID, creating the App Store Connect record,
code signing, archiving, exporting a signed `.ipa`, and inviting testers.

```bash
# Scripted release (after one-time App Store Connect setup):
TEAM_ID=ABCDE12345 API_KEY_ID=XXXX API_ISSUER_ID=<uuid> ./release.sh
```

> Requires a **paid Apple Developer Program** membership ($99/yr) — TestFlight isn't available on the free tier.

---

## 🏗️ Architecture

```
        ┌──────────────────────────────────────────────┐
        │                 SwiftUI Views                 │
        │  RootView → DashboardView → NewTripView       │
        │                        └──→ TripDetailView    │
        │  MapPanelView (MapKit) · Components · Theme    │
        └───────────────┬───────────────┬───────────────┘
                        │               │
                 @EnvironmentObject      │ export
                        ▼               ▼
        ┌───────────────────────┐  ┌──────────────────────┐
        │      TripStore        │  │   CalendarExport     │
        │  ObservableObject     │  │  EventKit + .ics      │
        │  JSON file persistence│  └──────────────────────┘
        └───────────┬───────────┘
                    │ createTrip(input)
                    ▼
        ┌───────────────────────────────────────────────┐
        │   Planner  ── curated city bank + generic      │
        │   PromptParser ── NL → structured PlannerInput │
        │   (pure Foundation, fully offline)             │
        └───────────────────────────────────────────────┘
```

### Folder structure

```
TripForgeApp/
├── project.yml                     # XcodeGen spec (target, iOS 17, Info keys)
├── README.md
└── TripForge/
    ├── TripForgeApp.swift          # @main App entry
    ├── Models/Models.swift         # Codable Trip/Day/Activity + enums
    ├── Planner/
    │   ├── Planner.swift           # Offline engine + curated city bank
    │   ├── PromptParser.swift      # Natural-language extractor
    │   └── Utils.swift             # Dates, money, constants, templates
    ├── Store/
    │   ├── TripStore.swift         # State + JSON persistence + coerceInput
    │   └── CalendarExport.swift    # EventKit + .ics generation
    ├── Theme/Theme.swift           # Brand colors + button/card styles
    └── Views/
        ├── RootView.swift
        ├── DashboardView.swift     # My Trips + templates
        ├── NewTripView.swift       # Prompt + smart form
        ├── TripDetailView.swift    # Timeline, budget, packing, export
        ├── MapPanelView.swift      # MapKit map + route
        └── Components.swift        # Logo, chips, flow layout, share sheet
```

---

## 🔐 Permissions

The app requests **write-only Calendar access** only when you tap *Add to Calendar*. The usage
string is declared in `project.yml` (`NSCalendarsUsageDescription` /
`NSCalendarsFullAccessUsageDescription`). No other permissions are used.

---

## 🆓 Free & offline by design

Everything works with **zero paid services**:

| Capability        | Implementation            | Cost |
|-------------------|---------------------------|------|
| Itinerary AI      | On-device Swift planner    | Free |
| Maps & routing    | Apple **MapKit** / Maps app| Free |
| Calendar export   | **EventKit** + `.ics`      | Free |
| Persistence       | Local JSON file            | Free |

---

## 📄 License

MIT — build something wonderful.

<div align="center">
<sub>Made with ☕ and wanderlust · TripForge for iOS</sub>
</div>
