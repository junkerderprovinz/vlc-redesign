/**
 * Renders the README screenshots in the style of the house's store pictures: the
 * captured VLC window on a dark ground with the VLC cone as a relief, a heading
 * and a line of text beside it. 1920x1000 each.
 *
 * The captures in captures/ are 1440x900 at twice the pixel density, taken from
 * the Linux build under Xvfb with a demo media library, in the dark theme with
 * the default accent unless the heading is about colours. VLC draws its own title
 * bar, so the window here is the capture itself with rounded corners.
 *
 * The player plays a still from Big Buck Bunny (c) Blender Foundation, CC BY 3.0,
 * peach.blender.org.
 *
 * Needs playwright-core installed globally and Chrome.
 * Run: node .github/assets/screenshots/render.mjs
 */
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { execSync } from "node:child_process";

const require = createRequire(import.meta.url);
const { chromium } = require(`${execSync("npm root -g").toString().trim()}/playwright-core`);

const here = dirname(fileURLToPath(import.meta.url));

const SHOTS = [
  { file: "vlc-redesign-1.png", capture: "library.png", caption: "Your whole library,<br><em>at a glance</em>", sub: "Videos, music and network shares in one place" },
  { file: "vlc-redesign-2.png", capture: "player.png", caption: "Controls that<br><em>step aside</em>", sub: "The bar and the frame hide until the pointer comes back" },
  { file: "vlc-redesign-3.png", capture: "music.png", caption: "Albums that<br><em>look like albums</em>", sub: "Covers, tracks and one click to play" },
  { file: "vlc-redesign-4.png", capture: "settings.png", caption: "Settings you can<br><em>actually find</em>", sub: "13 clear pages, and VLC's full preferences one click away" },
  { file: "vlc-redesign-5.png", capture: "customize.png", caption: "Your player,<br><em>your buttons</em>", sub: "Drag controls into the bar or out of it" },
  { file: "vlc-redesign-6.png", capture: "light.png", caption: "Dark, light and<br><em>any colour<br>you like</em>", sub: "Nine accent colours and a picker for the rest" },
  { file: "vlc-redesign-7.png", capture: "accent.png", caption: "Set it up<br><em>on the first start</em>", sub: "Theme, layout and accent colour before the first video" },
];

async function cached(file, url) {
  const path = join(tmpdir(), `vlc-${file}`);
  if (!existsSync(path)) {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`${file}: fetch ${res.status}`);
    writeFileSync(path, Buffer.from(await res.arrayBuffer()));
  }
  return readFileSync(path);
}

const dataUrl = (buf, type) => `data:${type};base64,${buf.toString("base64")}`;
const fonts = "https://github.com/google/fonts/raw/main/ofl";
const bree = dataUrl(await cached("BreeSerif-Regular.ttf", `${fonts}/breeserif/BreeSerif-Regular.ttf`), "font/ttf");
const lato = dataUrl(await cached("Lato-Regular.ttf", `${fonts}/lato/Lato-Regular.ttf`), "font/ttf");
const cone = dataUrl(readFileSync(join(here, "..", "vlc-cone.svg")), "image/svg+xml");

const STYLE = `
@font-face { font-family: "Bree Serif"; src: url(${bree}); }
@font-face { font-family: Lato; src: url(${lato}); }
* { box-sizing: border-box; margin: 0; }
body { position: relative; width: 1920px; height: 1000px; overflow: hidden; font-family: Lato, sans-serif; background: #0c0c0b; }
.wall { position: absolute; inset: 0; background: radial-gradient(55% 60% at 62% 35%, #26231d, #0f0e0c 72%); }
.relief { position: absolute; width: 36%; left: -7%; top: 7%; transform: rotate(-10deg); opacity: .32;
  filter: grayscale(1) brightness(.36) contrast(1.2) drop-shadow(-2px -2px 0 rgba(255,255,255,.16)) drop-shadow(12px 18px 26px rgba(0,0,0,.85)); }
.vignette { position: absolute; inset: 0; box-shadow: inset 0 0 200px rgba(0,0,0,.6); }
.copy { position: absolute; left: 84px; top: 0; bottom: 0; width: 500px; display: flex; flex-direction: column; justify-content: center; gap: 28px; }
.copy img { width: 112px; }
h1 { font: 400 62px/1.12 "Bree Serif", serif; color: #f4f4f4; text-wrap: balance; }
h1 em { font-style: normal; color: #FCC419; }
.sub { font-size: 28px; line-height: 1.35; color: #9d9481; text-wrap: balance; }
.stage { position: absolute; left: 640px; top: 119px; width: 1220px; perspective: 2400px; }
.floor { position: absolute; left: 12%; right: 12%; bottom: -4%; height: 8%; border-radius: 50%; background: rgba(0,0,0,.8); filter: blur(30px); }
.win { position: relative; transform: rotateY(-8deg) rotateX(2deg); border-radius: 12px; overflow: hidden; background: #161616;
  box-shadow: 0 0 0 1px #3c3c3c, 0 2px 4px rgba(0,0,0,.35), 0 18px 36px rgba(0,0,0,.45), 0 52px 100px rgba(0,0,0,.55); }
.win > img { display: block; width: 1220px; height: 762px; }
.glare { position: absolute; inset: 0; pointer-events: none;
  background: linear-gradient(118deg, rgba(255,255,255,.07) 0%, rgba(255,255,255,.02) 28%, rgba(255,255,255,0) 42%); }
`;

const page = ({ capture, caption, sub }) => `<!doctype html><html><head><meta charset="utf-8"><style>${STYLE}</style></head><body>
<div class="wall"></div><img class="relief" src="${cone}"><div class="vignette"></div>
<div class="copy"><img src="${cone}"><h1>${caption}</h1><p class="sub">${sub}</p></div>
<div class="stage"><div class="floor"></div><div class="win">
  <img src="${dataUrl(readFileSync(join(here, "captures", capture)), "image/png")}"><div class="glare"></div>
</div></div>
</body></html>`;

// Rendered at twice the size and scaled down, which keeps the type crisp.
const browser = await chromium.launch({ channel: "chrome" });
for (const shot of SHOTS) {
  const big = await browser.newPage({ viewport: { width: 1920, height: 1000 }, deviceScaleFactor: 2 });
  await big.setContent(page(shot));
  await big.evaluate(() => document.fonts.ready);
  const png = await big.screenshot();
  await big.close();
  const small = await browser.newPage({ viewport: { width: 1920, height: 1000 } });
  await small.setContent(`<body style="margin:0"><img src="${dataUrl(png, "image/png")}" style="display:block;width:1920px;height:1000px">`);
  await small.locator("img").evaluate((img) => img.decode());
  await small.screenshot({ path: join(here, shot.file) });
  await small.close();
  console.log(`${shot.file} written`);
}
await browser.close();
