/**
 * Generates the README banners (1600x500):
 *
 *   vlc-redesign-banner.svg/.png       light, cone + name + claim
 *   vlc-redesign-banner-dark.svg/.png  dark,  cone + name + claim
 *   vlc-redesign-banner-logo.svg/.png  light, cone only, no text
 *
 * The cone is the one from the redesign's icon set; its stripes are gaps, so
 * the same logo reads on white and on near-black.
 *
 * Text becomes SVG paths through opentype.js, so the SVG needs no font and
 * renders the same in resvg and a browser. Bree Serif for the name and Lato for
 * the claim, as in the other repos.
 *
 * Deps (global): opentype.js, @resvg/resvg-js. Fonts are fetched to the OS temp dir.
 * Run: node .github/assets/gen-banner.mjs
 */
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";
import { createRequire } from "node:module";
import { execSync } from "node:child_process";

const require = createRequire(import.meta.url);
const groot = execSync("npm root -g").toString().trim();
const opentype = require(`${groot}/opentype.js`);
const { Resvg } = require(`${groot}/@resvg/resvg-js`);

const __dir = dirname(fileURLToPath(import.meta.url));

const NAME = "VLC Redesign";
const CLAIM = "A new look. Still plays everything.";
const W = 1600, H = 500;
const LOGO_FILE = "logo.svg";
const { vbW: LOGO_VB_W, vbH: LOGO_VB_H } = readViewBox(LOGO_FILE);
// The cone is taller than wide; 380 leaves room above and below like the other banners.
const LH = 380, LW = LH * (LOGO_VB_W / LOGO_VB_H);
const nameSize = 132, claimSize = 44, gap = 80, lineGap = 8;

const THEMES = [
  { suffix: "", bg: "#ffffff", name: "#1f2328", claim: "#5a5d5e" },
  { suffix: "-dark", bg: "#0d1117", name: "#e6edf3", claim: "#9aa4ad" },
];

function readViewBox(logoFile) {
  const raw = readFileSync(join(__dir, logoFile), "utf8");
  const m = raw.match(/viewBox="[\d.\-]+\s+[\d.\-]+\s+([\d.]+)\s+([\d.]+)"/);
  if (!m) throw new Error(`${logoFile}: no viewBox found`);
  return { vbW: parseFloat(m[1]), vbH: parseFloat(m[2]) };
}

async function loadFont(file, url) {
  const path = join(tmpdir(), file);
  if (!existsSync(path)) {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`font fetch ${res.status}`);
    writeFileSync(path, Buffer.from(await res.arrayBuffer()));
  }
  return opentype.parse(readFileSync(path));
}

const font = await loadFont("VlcRedesign-BreeSerif-Regular.ttf", "https://github.com/google/fonts/raw/main/ofl/breeserif/BreeSerif-Regular.ttf");
const claimFont = await loadFont("VlcRedesign-Lato-Regular.ttf", "https://github.com/google/fonts/raw/main/ofl/lato/Lato-Regular.ttf");

const nameW = font.getAdvanceWidth(NAME, nameSize);
const claimW = claimFont.getAdvanceWidth(CLAIM, claimSize);
const groupW = LW + gap + Math.max(nameW, claimW);
const startX = Math.max(60, (W - groupW) / 2);
const LX = startX, LY = (H - LH) / 2;
const textX = startX + LW + gap;

const sc = (s) => s / font.unitsPerEm;
const nameAsc = font.ascender * sc(nameSize);
const nameDesc = -font.descender * sc(nameSize);
const claimAsc = claimFont.ascender * (claimSize / claimFont.unitsPerEm);
const blockH = nameAsc + nameDesc + lineGap + claimAsc;
const nameBaseline = H / 2 - blockH / 2 + nameAsc;
const claimBaseline = nameBaseline + nameDesc + lineGap + claimAsc;

const namePath = font.getPath(NAME, textX, nameBaseline, nameSize).toPathData(2);
const claimPath = claimFont.getPath(CLAIM, textX, claimBaseline, claimSize).toPathData(2);

// Embeds the logo at (x, y, w, h), keeping its own viewBox.
function embedLogo(x, y, w, h) {
  const raw = readFileSync(join(__dir, LOGO_FILE), "utf8");
  const vb = raw.match(/viewBox="([^"]+)"/)[1];
  return raw.replace(/<svg\b[^>]*>/, `<svg x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${w.toFixed(1)}" height="${h}" viewBox="${vb}">`).trim();
}

function emit(name, svg, bg) {
  writeFileSync(join(__dir, `${name}.svg`), svg);
  const png = new Resvg(svg, { background: bg, fitTo: { mode: "width", value: W } }).render().asPng();
  writeFileSync(join(__dir, `${name}.png`), png);
  console.log(`wrote ${name}.svg + .png`);
}

for (const t of THEMES) {
  emit(`vlc-redesign-banner${t.suffix}`, `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <rect width="${W}" height="${H}" fill="${t.bg}"/>
  ${embedLogo(LX, LY, LW, LH)}
  <path d="${namePath}" fill="${t.name}"/>
  <path d="${claimPath}" fill="${t.claim}"/>
</svg>
`, t.bg);
}

emit("vlc-redesign-banner-logo", `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <rect width="${W}" height="${H}" fill="${THEMES[0].bg}"/>
  ${embedLogo((W - LW) / 2, (H - LH) / 2, LW, LH)}
</svg>
`, THEMES[0].bg);
