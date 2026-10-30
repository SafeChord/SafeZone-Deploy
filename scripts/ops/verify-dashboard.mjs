// F9 of verify-app.sh: load dashboard-v2 in headless Chromium and gate on what it renders.
// verify-app.sh runs it in the pinned Playwright image; it needs playwright-core in node_modules.
//
// Usage: node verify-dashboard.mjs <url> <shot_dir>
//   <url>       dashboard-v2, e.g. https://<host>/dashboard/
//   <shot_dir>  where a failing run leaves its screenshot; a passing run writes nothing there
//
// Output: verify-app.sh's lines, `PASS|FAIL|REPORT <id> <observed> <expected>`, tab-separated.
// The numbers on the page are reported, not gated: their correctness is F4's and F5's.
import { chromium } from "playwright-core";

const [url, shotDir] = process.argv.slice(2);
if (!url || !shotDir) {
  console.error("usage: node verify-dashboard.mjs <url> <shot_dir>");
  process.exit(2);
}
const SETTLE_MS = 30_000; // how long the page gets to fill in before it is judged
const MAP_MIN_DRAWN = 0.02; // share of the map that must differ from its background

const lines = [];
const line = (result, id, observed, expected) => lines.push([result, id, observed, expected]);

let browser = null;
let page = null;
const requests = { count: 0, bad: [] };
const pageErrors = [];

// What the page shows, read off the DOM. The components carry no test ids, so each is found by
// its heading text or, for the error banner, by its colour.
const readPage = () =>
  page.evaluate(() => {
    const leaf = (tag, text) =>
      [...document.querySelectorAll(tag)].find((e) => e.children.length === 0 && e.textContent.trim() === text);
    const card = (label) => leaf("div", label)?.nextElementSibling?.textContent.trim() ?? null;
    const banner = [...document.querySelectorAll("main > div")].find(
      (d) => getComputedStyle(d).backgroundColor === "rgb(255, 234, 234)",
    );
    const top = leaf("h3", "Top 10 Cities")?.parentElement;
    const time = document.querySelector("header span")?.textContent ?? "";
    return {
      systemDate: time.match(/Simulated: (\S+)/)?.[1] ?? null,
      banner: banner?.textContent.trim() ?? null,
      week: card("近七日新增案例"),
      today: card("今日新增案例"),
      top10: [...(top?.querySelectorAll("tbody tr") ?? [])].map((tr) =>
        [...tr.querySelectorAll("td")].slice(0, 2).map((td) => td.textContent.trim()).join(" "),
      ),
    };
  });

// Share of the map canvas that differs from its most common colour (the sea). Taken from a
// screenshot, since the WebGL canvas keeps no drawing buffer to read back; the zoom buttons are
// hidden so that they do not count.
const mapDrawn = async () => {
  const canvas = page.locator("canvas.maplibregl-canvas");
  if ((await canvas.count()) === 0) return 0;
  const png = await canvas.screenshot({ style: ".maplibregl-control-container { display: none !important; }" });
  return page.evaluate(async (b64) => {
    const img = new Image();
    img.src = `data:image/png;base64,${b64}`;
    await img.decode();
    const c = document.createElement("canvas");
    c.width = img.width;
    c.height = img.height;
    const ctx = c.getContext("2d");
    ctx.drawImage(img, 0, 0);
    const px = ctx.getImageData(0, 0, c.width, c.height).data;
    const freq = new Map();
    for (let i = 0; i < px.length; i += 4) {
      const k = (px[i] << 16) | (px[i + 1] << 8) | px[i + 2];
      freq.set(k, (freq.get(k) ?? 0) + 1);
    }
    const bg = [...freq].sort((a, b) => b[1] - a[1])[0][0];
    const [br, bgr, bb] = [bg >> 16, (bg >> 8) & 255, bg & 255];
    let diff = 0;
    for (let i = 0; i < px.length; i += 4) {
      if (Math.max(Math.abs(px[i] - br), Math.abs(px[i + 1] - bgr), Math.abs(px[i + 2] - bb)) > 3) diff++;
    }
    return diff / (px.length / 4);
  }, png.toString("base64"));
};

let fatal = null;
let shown = null;
let drawn = 0;
try {
  browser = await chromium.launch();
  page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.on("response", (r) => {
    requests.count++;
    const path = new URL(r.url()).pathname;
    if (r.status() >= 400 && path !== "/favicon.ico") requests.bad.push(`${r.status()} ${path}`);
  });
  page.on("pageerror", (e) => pageErrors.push(e.message.split("\n")[0]));
  const deadline = Date.now() + SETTLE_MS;
  await page.goto(url, { waitUntil: "load", timeout: SETTLE_MS });
  // A request that never finishes is left to the checks below, which name what it left empty.
  await page.waitForLoadState("networkidle", { timeout: Math.max(deadline - Date.now(), 1) }).catch(() => {});
  // Poll until the page has filled in, an error banner shows, or the time is up.
  for (;;) {
    shown = await readPage();
    drawn = await mapDrawn();
    const filled = shown.week !== "-" && shown.today !== "-" && shown.top10.length > 0;
    if (shown.banner || (filled && drawn >= MAP_MIN_DRAWN) || Date.now() > deadline) break;
    await page.waitForTimeout(500);
  }
} catch (e) {
  fatal = e.message.split("\n")[0];
}

if (fatal) {
  line("FAIL", "F9", `${url}: ${fatal}`, "dashboard-v2 loads");
} else {
  const wrong = [
    shown.banner && `error banner: ${shown.banner}`,
    pageErrors.length && `page errors: ${pageErrors.join(" | ")}`,
    requests.bad.length && `answered >= 400: ${requests.bad.join(", ")}`,
  ].filter(Boolean);
  line(wrong.length ? "FAIL" : "PASS", "F9.1",
    wrong.length ? wrong.join("; ") : `no error banner, no page error, ${requests.count} requests none >= 400`,
    "no error banner, no uncaught page error, no request answered >= 400 but /favicon.ico");
  const cards = `7 days ${shown.week ?? "none"}, today ${shown.today ?? "none"}`;
  const cardsOk = [shown.week, shown.today].every((v) => v && v !== "-");
  line(cardsOk ? "PASS" : "FAIL", "F9.2", cards, "both stat cards show a value");
  line(shown.top10.length ? "PASS" : "FAIL", "F9.3", `${shown.top10.length} rows`, "Top 10 has rows");
  line(drawn >= MAP_MIN_DRAWN ? "PASS" : "FAIL", "F9.4",
    `cities drawn on ${(drawn * 100).toFixed(1)}% of the map`, `cities drawn on >= ${MAP_MIN_DRAWN * 100}%`);
  line("REPORT", "F9.5",
    `system date ${shown.systemDate ?? "none"}; ${cards}; Top 10: ${shown.top10.join(", ") || "none"}`,
    "no threshold");
}

if (page && lines.some(([result]) => result === "FAIL")) {
  const shot = `${shotDir}/dashboard-v2-${new Date().toISOString().replace(/[:.]/g, "")}.png`;
  try {
    await page.screenshot({ path: shot, fullPage: true });
    for (const l of lines) if (l[0] === "FAIL") l[2] += `; screenshot ${shot}`;
  } catch (e) {
    for (const l of lines) if (l[0] === "FAIL") l[2] += `; no screenshot: ${e.message.split("\n")[0]}`;
  }
}
await browser?.close();
for (const l of lines) console.log(l.join("\t"));
