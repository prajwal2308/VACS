# Changelog

All notable changes to VACS are documented here.

## [0.1.2] — 2026-08-05

### Added

- **Installed Packages** finder — Homebrew, npm global, pip, PATH binaries
- **AI & Skills** scanner — Cursor/Codex skills, MCP configs, stale/broken flags
- **Copy** button on package rows — copies uninstall command (`pip uninstall torch`, etc.) for Terminal
- Trash cleanup banner and prompt when Trash dominates reclaimable space

### Changed

- macOS Trash removed from System scan — managed only in Trash sidebar
- Check-first items show red warnings (System category banner + chips)

### Fixed

- Overview not refreshing after move to Trash — empty categories drop off immediately
- Stale Trash rows no longer re-prompt “Move to Trash” after deletion

## [0.1.1] — 2026-08-05

### Added

- Overview category chips sync with **Show more** selections (safe + check first)
- **Deselect all** in category item sheet
- **Uninstall** flow for Installed Apps (app only or complete)
- Back navigation: ← Overview bar, swipe, Backspace, ⌘[
- Auto-select safe items after full scan; tap chips to toggle on overview cards

### Changed

- Scan button uses primary pill style in category detail
- Allowlist link opens GitHub rules.json in browser
- Package.swift: Swift 5.9, bundled Resources

### Fixed

- Overview card not updating when selecting items in Show more dialog

## [0.1.0] — 2026-08-05

### Added

- Native SwiftUI macOS disk cleaner for developers
- **Smart Scan** dashboard with per-category review cards and bulk clean
- Sidebar categories: Developer, Packages, Browsers, Containers, AI Tools, Apps, System, Heavy folders
- **95-path rules engine** (`rules.json`) with plain-English notes and four safety levels
- **Installed Apps** browser with related-file drill-down (caches, containers, preferences)
- **Trash browser** — list, Put Back, delete permanently, empty Trash, Finder sounds
- Docker sparse-file sizing and copy-commands for Docker / Minikube / Colima
- DerivedData per-project breakdown
- `node_modules` and project artifact scanner (18 artifact types)
- Full Disk Access gate before scanning
- Trash-only deletion — nothing permanently erased without explicit action in Trash view
- Zero network access — no telemetry, updates, or analytics

### Security

- Proprietary license — see [LICENSE](LICENSE)
