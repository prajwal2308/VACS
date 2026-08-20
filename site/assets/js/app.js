/* Hallmark · genre: modern-minimal · macrostructure: Workbench · theme: Cobalt
 *
 * Every version number, file size, changelog entry and cleanup rule on this page
 * is fetched from GitHub at runtime. Nothing here is hand-maintained.
 */

const REPO   = "prajwal2308/VACS";
const API    = `https://api.github.com/repos/${REPO}`;
const RAW    = `https://raw.githubusercontent.com/${REPO}/main`;
const RULES  = `${RAW}/Sources/VACS/Resources/rules.json`;
const LATEST = `https://github.com/${REPO}/releases/latest`;
const TTL    = 20 * 60 * 1000;

const $  = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const gh = (k) => $$(`[data-gh="${k}"]`);
const REDUCED = matchMedia("(prefers-reduced-motion: reduce)").matches;

/* ─────────────── fetch + cache ─────────────── */
async function cachedJSON(url, key) {
  try {
    const hit = JSON.parse(localStorage.getItem(key) || "null");
    if (hit && Date.now() - hit.t < TTL) return hit.d;
  } catch {}
  const res = await fetch(url, { headers: { Accept: "application/vnd.github+json" } });
  if (!res.ok) throw new Error(`${res.status} · ${url}`);
  const d = await res.json();
  try { localStorage.setItem(key, JSON.stringify({ t: Date.now(), d })); } catch {}
  return d;
}

/* ─────────────── formatting ─────────────── */
const bytes = (n) => {
  if (typeof n !== "number") return "—";
  const u = ["B", "KB", "MB", "GB"];
  let i = 0, v = n;
  while (v >= 1024 && i < u.length - 1) { v /= 1024; i += 1; }
  return `${v >= 100 || i < 2 ? Math.round(v) : v.toFixed(1)} ${u[i]}`;
};
const shortDate = (iso) =>
  new Date(iso).toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
const esc = (s = "") =>
  String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

/* Typographic punctuation — straight quotes and `--` are a proof-reading tell. */
const smarten = (s = "") =>
  s.replace(/(^|[\s(\[])"/g, "$1“").replace(/"/g, "”")
   .replace(/(^|[\s(\[])'/g, "$1‘").replace(/'/g, "’")
   .replace(/\s--\s/g, " — ").replace(/\.\.\./g, "…");

/* ─────────────── release-notes markdown ─────────────── */
function md(src) {
  const inline = (t) =>
    smarten(esc(t))
      .replace(/`([^`]+)`/g, "<code>$1</code>")
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>')
      .replace(/(^|\s)#(\d+)\b/g, `$1<a href="https://github.com/${REPO}/issues/$2" target="_blank" rel="noopener">#$2</a>`);

  const out = [];
  let open = false;
  const closeList = () => { if (open) { out.push("</ul>"); open = false; } };

  for (const raw of String(src).replace(/\r/g, "").split("\n")) {
    const line = raw.trim();
    if (!line) { closeList(); continue; }
    const h = line.match(/^#{1,6}\s+(.*)$/);
    if (h) {
      closeList();
      // release notes lead their headings with emoji; the page has its own icon voice
      const text = h[1].replace(/^[\p{Extended_Pictographic}\uFE0F\u200D\s]+/u, "");
      out.push(`<h4>${inline(text)}</h4>`);
      continue;
    }
    const li = line.match(/^(?:[-*+]|\d+\.)\s+(.*)$/);
    if (li) {
      if (!open) { out.push("<ul>"); open = true; }
      out.push(`<li>${inline(li[1])}</li>`);
      continue;
    }
    if (/^(---|\*\*\*)$/.test(line)) { closeList(); continue; }
    closeList();
    out.push(`<p>${inline(line)}</p>`);
  }
  closeList();
  return out.join("");
}

/* ─────────────── downloads ─────────────── */
const findDmg = (rel) => (rel.assets || []).find((a) => /\.dmg$/i.test(a.name)) || null;

function paintRelease(rel) {
  const dmg = findDmg(rel);
  const href = dmg ? dmg.browser_download_url : LATEST;
  const ver = (rel.tag_name || "").replace(/^v/, "");

  [...gh("hero-download"), ...gh("step-download"), ...gh("sticky-download"), ...gh("foot-download")].forEach((a) => {
    a.href = href;
    if (!dmg) a.removeAttribute("download");
  });

  gh("nav-download").forEach((el) => { el.textContent = ver ? `Download ${ver}` : "Download"; });
  gh("dl-label").forEach((el) => { el.textContent = ver ? `Download VACS ${ver}` : "Download for macOS"; });
  gh("version-pill").forEach((el) => { el.textContent = rel.tag_name || "latest"; });
  gh("hero-ver").forEach((el) => { el.textContent = rel.tag_name || "—"; });
  gh("hero-size").forEach((el) => { el.textContent = dmg ? bytes(dmg.size) : "—"; });
  gh("step-dl-label").forEach((el) => { el.textContent = dmg ? dmg.name : "VACS.dmg"; });
  gh("step-dl-meta").forEach((el) => {
    el.textContent = dmg
      ? `${bytes(dmg.size)} · released ${shortDate(rel.published_at)}`
      : `released ${shortDate(rel.published_at)}`;
  });
  gh("sticky-title").forEach((el) => { el.textContent = ver ? `VACS ${ver}` : "VACS"; });
  gh("sticky-meta").forEach((el) => {
    el.textContent = dmg ? `${bytes(dmg.size)} · macOS 14+ · MIT` : "macOS 14+ · Apple Silicon · MIT";
  });
}

/* ─────────────── changelog ─────────────── */
function paintReleases(list) {
  const box = $("#releases");
  box.innerHTML = list
    .map((r, i) => {
      const dmg = findDmg(r);
      const title = (r.name || r.tag_name).replace(/^v?[\d.]+\s*[-–—]\s*/, "");
      return `
      <article class="rel${i === 0 ? " is-open" : ""}">
        <button class="rel__head" type="button" aria-expanded="${i === 0}">
          <span class="rel__tag">${esc(r.tag_name)}</span>
          <span class="rel__title">${esc(smarten(title))}</span>
          <span class="rel__date">${shortDate(r.published_at)}</span>
          <svg class="rel__chev" viewBox="0 0 20 20" width="14" height="14" aria-hidden="true"><path d="m8 5 5 5-5 5" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>
        </button>
        <div class="rel__body"><div><div class="rel__content">
          ${md(r.body || "No notes for this release.")}
          ${dmg ? `<a class="rel__asset" href="${dmg.browser_download_url}" download>${esc(dmg.name)} <span>${bytes(dmg.size)}</span></a>` : ""}
        </div></div></div>
      </article>`;
    })
    .join("");

  $$(".rel__head", box).forEach((btn) => {
    btn.addEventListener("click", () => {
      const open = btn.closest(".rel").classList.toggle("is-open");
      btn.setAttribute("aria-expanded", String(open));
    });
  });
}

/* ─────────────── load everything ─────────────── */
async function loadGitHub() {
  try {
    const releases = (await cachedJSON(`${API}/releases?per_page=10`, "vacs:releases")).filter((r) => !r.draft);
    if (!releases.length) throw new Error("no releases published");
    paintRelease(releases[0]);
    paintReleases(releases);
  } catch (err) {
    console.warn("[VACS] releases unavailable —", err.message);
    $("#releases").innerHTML =
      `<p class="rels__error">The GitHub API is rate-limiting anonymous requests right now. Read the changelog on <a href="https://github.com/${REPO}/releases" target="_blank" rel="noopener">the releases page</a>.</p>`;
  }

  try {
    const raw = await cachedJSON(RULES, "vacs:rules");
    const rules = Array.isArray(raw) ? raw : Array.isArray(raw.rules) ? raw.rules : [];
    if (!rules.length) throw new Error("empty rules file");
    gh("rule-count").forEach((el) => { el.textContent = String(rules.length); });
  } catch (err) {
    console.warn("[VACS] rule count unavailable —", err.message);   // the baked-in 96 stands
  }
}

/* count a number up with an ease-out quart; reduced motion lands on the value */
function countTo(el, target, dur, format) {
  if (REDUCED) { el.textContent = format(target); return; }
  const t0 = performance.now();
  const tick = (now) => {
    const p = Math.min(1, (now - t0) / dur);
    el.textContent = format(target * (1 - Math.pow(1 - p, 4)));
    if (p < 1) requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
}

/* ─────────────── theme ─────────────── */
/* Dark is the default ground. The choice is remembered; there is no
   transition on the swap — a theme change is a state change, not a move. */
function theme() {
  const root = document.documentElement;
  const btn = $("#themeToggle");
  const meta = $("#themeColor");
  const GROUND = { dark: "#0c0e14", light: "#f7f8fb" };

  const apply = (mode) => {
    if (mode === "light") root.setAttribute("data-theme", "light");
    else root.removeAttribute("data-theme");
    if (meta) meta.content = GROUND[mode];
    if (btn) {
      btn.setAttribute("aria-checked", String(mode === "light"));
      btn.setAttribute("aria-label", mode === "light" ? "Switch to dark mode" : "Switch to light mode");
    }
  };

  let mode = "dark";
  try { if (localStorage.getItem("vacs:theme") === "light") mode = "light"; } catch {}
  apply(mode);

  btn?.addEventListener("click", () => {
    mode = mode === "light" ? "dark" : "light";
    apply(mode);
    try { localStorage.setItem("vacs:theme", mode); } catch {}
  });
}

/* ─────────────── nav, sticky bar, reveals ─────────────── */
function chrome() {
  const nav = $("#nav");
  const bar = $("#stickybar");
  const hero = $("#hero");
  const footer = $(".foot");
  if (!nav || !bar || !hero || !footer) return;

  new IntersectionObserver(([e]) => {
    nav.classList.toggle("is-stuck", !e.isIntersecting);
  }, { rootMargin: "-72px 0px 0px 0px" }).observe(hero);

  // the sticky CTA appears once the hero is behind you, and retreats over the footer
  let pastHero = false, atFoot = false;
  const sync = () => {
    bar.hidden = false;
    bar.classList.toggle("is-shown", pastHero && !atFoot);
  };
  new IntersectionObserver(([e]) => { pastHero = !e.isIntersecting; sync(); }, { threshold: 0 }).observe(hero);
  new IntersectionObserver(([e]) => { atFoot = e.isIntersecting; sync(); }, { threshold: 0 }).observe(footer);
}

function facts() {
  const el = $('[data-gh="rule-count"]');
  if (!el) return;
  new IntersectionObserver((e, o) => {
    if (!e[0].isIntersecting) return;
    o.disconnect();
    countTo(el, Number(el.textContent) || 96, 1200, (v) => String(Math.round(v)));
  }, { threshold: 0.6 }).observe(el);
}

function reveals() {
  const items = $$(".reveal");
  if (REDUCED) { items.forEach((el) => el.classList.add("is-in")); return; }
  const io = new IntersectionObserver((entries) => {
    entries.forEach((en, i) => {
      if (!en.isIntersecting) return;
      setTimeout(() => en.target.classList.add("is-in"), i * 90);   // one-shot stagger
      io.unobserve(en.target);
    });
  }, { threshold: 0.15, rootMargin: "0px 0px -6% 0px" });
  items.forEach((el) => io.observe(el));
}

function copyButtons() {
  $$(".code__copy").forEach((btn) => {
    btn.addEventListener("click", async () => {
      const code = btn.closest(".code")?.querySelector("code")?.textContent ?? "";
      try { await navigator.clipboard.writeText(code); } catch { return; }
      btn.textContent = "✓ Copied";
      btn.classList.add("is-done");
      setTimeout(() => { btn.textContent = "Copy"; btn.classList.remove("is-done"); }, 1600);
    });
  });
}

/* ─────────────── go ─────────────── */
theme();
chrome();
reveals();
facts();
copyButtons();
loadGitHub();
