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
  <a href="docs/COMPARISON.md">Comparison</a> ·
  <a href="SECURITY.md">Security</a> ·
  <a href="docs/PRIVACY.md">Privacy</a> ·
  <a href="SUPPORT.md">Support</a>
</p>

---

Your Mac quietly accumulates tens of gigabytes of **developer caches** — Xcode DerivedData, Docker VM disks, npm stores, Playwright browsers, Ollama models — plus everyday app temp files from Zoom, Discord, and Slack.

Most cleaners call it all "junk." **VACS tells you what each folder actually is**, labels what's safe, and never permanently deletes without your explicit action.

> **Nothing is silently erased.** Normal cleanup moves items to the **Trash**. You can Put Back until you empty Trash.

---

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
