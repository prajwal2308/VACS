<p align="center">
  <img src="Assets/icon-1024.png" width="128" alt="VACS icon" />
</p>

<h1 align="center">VACS</h1>

<p align="center">
  <strong>See what's eating your Mac — and what's safe to remove.</strong><br/>
  Native macOS disk cleaner for developers. Plain English. Trash-only. Zero telemetry.
</p>

<p align="center">
  <a href="docs/INSTALL.md"><strong>Install guide</strong></a> ·
  <a href="https://github.com/prajwal2308/VACS/releases"><strong>Download</strong></a> ·
  <a href="docs/COMPARISON.md">Comparison</a> ·
  <a href="SECURITY.md">Security</a> ·
  <a href="docs/PRIVACY.md">Privacy</a> ·
  <a href="SUPPORT.md">Support</a>
</p>

<p align="center">
  <a href="https://github.com/prajwal2308/VACS/releases/latest"><img src="https://img.shields.io/github/v/release/prajwal2308/VACS?label=latest%20release" alt="Latest release" /></a>
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/arch-arm64-blue" alt="Apple Silicon" />
</p>

---

Your Mac quietly accumulates tens of gigabytes of **developer caches** — Xcode DerivedData, Docker VM disks, npm stores, Playwright browsers, Ollama models — plus everyday app temp files from Zoom, Discord, and Slack.

Most cleaners call it all "junk." **VACS tells you what each folder actually is**, labels what's safe, and never permanently deletes without your explicit action.

> **Nothing is silently erased.** Normal cleanup moves items to the **Trash**. You can Put Back until you empty Trash.

---

<p align="center">
  <video src="https://github.com/prajwal2308/VACS/releases/download/v0.1.3/VACS_Demo.mp4" controls="controls" width="100%" style="max-width: 800px; border-radius: 8px;">
  </video>
</p>


## Features

### Smart Scan

- One scan across all categories
- Post-scan dashboard: reclaimable total, per-category review cards, checkboxes
- **Clean Selected** — one pass for checked safe categories

### Developer & dev-tool caches

| Category | Examples |
|----------|----------|
| **Developer** | Xcode DerivedData (per-project breakdown), simulators, JetBrains, VS Code, Cursor |
| **Packages** | npm, Homebrew, pip, Cargo, Gradle, pnpm, uv, Conda |
| **Browsers** | Puppeteer, Playwright, Selenium downloads |
| **Containers** | Docker (real APFS size), Minikube, Colima — **copy CLI commands**, not risky folder deletes |
| **AI Tools** | Ollama models, Hugging Face, AI IDE caches |
| **Apps** | Zoom, Discord, Slack, Perplexity, Spotify — consumer app temp files |
| **System** | Shared caches and logs under `~/Library` |
| **Heavy folders** | Unknown folders over 1 GB — surfaced for review |

**95 known paths** in auditable [`rules.json`](Sources/VACS/Resources/rules.json).

### Installed Apps

- Lists `.app` bundles in `/Applications` (including nested: TeX, Python, Adobe utilities)
- Drill into related files: caches, containers, preferences, logs
- Move selected files to Trash with confirmation

### Trash browser

- View macOS Trash contents inside VACS
- **Put Back** · **Delete Permanently** · **Empty Trash**
- Finder-style sounds on clean actions

### Safety model

| Level | UI behavior | Example |
|-------|-------------|---------|
| `safe` | One-click → Trash | Xcode DerivedData |
| `check` | Confirm with explanation first | `~/go/pkg/mod` |
| `command` | Copy CLI to clipboard — **no delete button** | Docker Desktop VM |
| `never` | Size only | — |

Filter pills: **All** · **Safe to clean** · **Check first**. Select-all bar on every category.

---

## Quick start

### Option A — Download (recommended)

1. Go to **[Releases](https://github.com/prajwal2308/VACS/releases/latest)** and download `VACS-x.y.z.dmg`
2. Open the DMG → drag **VACS.app** to **Applications**
3. **First launch:** macOS may block unsigned apps — **right-click VACS → Open**, or run:
   ```bash
   xattr -cr /Applications/VACS.app
   ```
4. Grant **Full Disk Access** when prompted → run **Smart Scan** from Overview

> Current builds are **ad-hoc signed**, not Apple-notarized. See [Code signing & notarization](#code-signing--notarization) below.

### Option B — Build from source

```bash
git clone https://github.com/prajwal2308/VACS.git
cd VACS
./scripts/build-app.sh --run
```

Grant **Full Disk Access** when prompted → run **Smart Scan** from Overview.

Full steps: **[docs/INSTALL.md](docs/INSTALL.md)**

---

## Build from source

### Prerequisites

- macOS 14+
- Xcode **Command Line Tools** only (`xcode-select --install`) — full Xcode optional

### Build

```bash
./scripts/build-app.sh          # → build/VACS.app
./scripts/build-app.sh --run    # build + self-test + open
```

The build uses plain `swiftc` (no Xcode project required). Self-test must pass:

```
VACS self-test: OK (95 rules loaded)
```

### Build a release DMG (maintainers)

```bash
./scripts/build-dmg.sh          # default version 0.1.0 → build/VACS-0.1.0.dmg
./scripts/build-dmg.sh 0.2.0    # custom version tag
```

Then attach the DMG to a [GitHub Release](https://github.com/prajwal2308/VACS/releases):

```bash
gh release create v0.2.0 build/VACS-0.2.0.dmg \
  --title "VACS 0.2.0" \
  --notes-file CHANGELOG.md
```

### Project layout

```
VACS/
├── Assets/                 # App icon (icns + source PNG)
├── docs/
│   ├── INSTALL.md          # Full installation & FDA guide
│   ├── PRIVACY.md          # Privacy policy
│   └── COMPARISON.md       # vs PureMac, Purge, ClearDisk, …
├── scripts/
│   ├── build-app.sh        # Primary build (swiftc → VACS.app)
│   ├── build-dmg.sh        # Build app + pack DMG for Releases
│   └── generate-icon.swift
├── Sources/VACS/
│   ├── Resources/rules.json
│   ├── Views/              # SwiftUI screens
│   └── …                   # Scanner, AppModel, Trash, etc.
├── Package.swift           # Optional: open in Xcode
├── README.md
├── LICENSE                 # Proprietary
├── SECURITY.md
├── SUPPORT.md
└── CHANGELOG.md
```

---

## Code signing & notarization

| | Current release | Fully notarized (future) |
|---|---|---|
| **Cost** | Free (ad-hoc sign) | **$99 USD/year** — [Apple Developer Program](https://developer.apple.com/programs/) |
| **Gatekeeper** | User may need right-click → Open on first launch | Opens normally after download |
| **Certificate** | None (`codesign -`) | **Developer ID Application** (from Apple) |
| **Notarization** | Not submitted | Required for distribution outside Mac App Store |

**Is notarization free?** No. Apple does not charge per notarization request, but you must enroll in the **Apple Developer Program ($99/year)** to get a Developer ID certificate and use Apple's `notarytool`. There is no free tier for shipping signed/notarized Mac apps to other people.

Rough pipeline when you have a paid account:

```bash
# 1. Sign the app with Developer ID
codesign --force --options runtime --sign "Developer ID Application: Your Name (TEAMID)" build/VACS.app

# 2. Notarize (uploads to Apple, usually minutes)
xcrun notarytool submit build/VACS-0.1.0.dmg --apple-id "you@email.com" --team-id TEAMID --password "@keychain:AC_PASSWORD" --wait

# 3. Staple the ticket so offline Gatekeeper passes
xcrun stapler staple build/VACS.app
```

Until then, ad-hoc builds from `./scripts/build-app.sh` or the [release DMG](https://github.com/prajwal2308/VACS/releases/latest) work fine for personal use and trusted testers — with the one-time Gatekeeper workaround in [Quick start](#quick-start).

---

## Requirements

| | |
|---|---|
| **OS** | macOS 14.0+ |
| **Permission** | Full Disk Access (one-time, before scan) |
| **Network** | None required — app makes zero requests |

---

## Privacy

VACS runs entirely on your Mac. No analytics, no update pings, no cloud. See **[docs/PRIVACY.md](docs/PRIVACY.md)**.

---

## Security

Trash-by-default. Allowlist rules. No sudo. See **[SECURITY.md](SECURITY.md)**.

---

## How VACS compares

Feature matrix vs PureMac, Purge, ClearDisk, Cacheout, and others: **[docs/COMPARISON.md](docs/COMPARISON.md)**

---

## License

**Proprietary — all rights reserved.** VACS is not open source.

See **[LICENSE](LICENSE)**. Unauthorized copying, modification, or distribution is prohibited. This repository is published for authorized use and transparency by the copyright holder — not for unsolicited contributions or forks.

Support: **[SUPPORT.md](SUPPORT.md)**

---

<p align="center">Made by Prajwal · © 2026</p>
