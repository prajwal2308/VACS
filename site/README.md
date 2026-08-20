# VACS landing page

Static, dependency-free: `index.html` + `assets/css/tokens.css` + `assets/css/styles.css` + `assets/js/app.js`.
No build step, no framework, no npm.

## Nothing here needs editing when you ship

Every version-specific value is fetched from GitHub at page load:

| What the page shows | Source |
|---|---|
| Version pill, hero size/version, all download buttons, sticky bar | `GET /repos/prajwal2308/VACS/releases` |
| Changelog (release notes rendered from markdown) | same call |
| The live rule count (comparison table, self-test line) | `Sources/VACS/Resources/rules.json` on `main` |
| The "N audited paths" figure | same file — counted, not typed |

Cached in `localStorage` for 20 minutes. If GitHub rate-limits anonymous requests (60/hr per IP),
downloads fall back to the [latest release page](https://github.com/prajwal2308/VACS/releases/latest)
and the changelog shows a link instead of an error.

Release flow is unchanged — and the site updates itself:

```bash
./scripts/build-dmg.sh 0.3.0
gh release create v0.3.0 build/VACS-0.3.0.dmg --title "VACS 0.3.0" --notes-file CHANGELOG.md
```

## Design system

Built with [Hallmark](https://github.com/) conventions. The stamp at the top of `styles.css` records the picks:

- **Genre** modern-minimal · **Macrostructure** Workbench · **Theme** Cobalt
- **Nav** minimal bar · **Footer** columned (Product / Docs / Project)
- **Type** Space Grotesk (display) · IBM Plex Sans (body) · JetBrains Mono (paths, sizes, labels)
- **Motion** one-shot stagger reveal, CTA hover/press feedback, install-command caret, count-up on the rule figure

`assets/css/tokens.css` is the portable token set — every colour and font in the build
references it by name. Copy that file to reuse the system elsewhere.
`.hallmark/log.json` at the repo root records this build so a future redesign rotates away from it.

## Screenshots

`assets/img/shot-*.png` are **real captures** — `shot-overview.png` is the 1080p preview recovered
from commit `9413b22`; the other three are frames pulled from `docs/assets/demo.gif` and cropped to
the window. They're 722×442, so they're a little soft on retina. Dropping in fresh 2× captures at the
same filenames is the one upgrade this page would most benefit from — no markup changes needed.

## Local preview

```bash
cd site && python3 -m http.server 4173   # → http://localhost:4173
```

## Deploy

`.github/workflows/pages.yml` publishes this folder on every push to `main` touching `site/`,
and again whenever a release is published.

One-time setup: **Settings → Pages → Build and deployment → Source: GitHub Actions**.
Live at `https://prajwal2308.github.io/VACS/`.
