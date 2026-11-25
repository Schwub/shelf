// Screenshots of the shelf web app against the local Supabase, signed in as
// a test user. Usage (see SKILL.md):
//   node shoot.js <out-dir> <email> [theme] [steps.json]
// Env: API_URL, SERVICE_ROLE_KEY (from `supabase status -o env`). The web
// build must be served on http://127.0.0.1:3000 (the local site_url).
// steps.json: [{"tap": "Text on screen"}, {"shot": "name"}, {"wait": 500}]
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const [outDir, email, theme = 'tobacco', stepsFile] = process.argv.slice(2);
const api = process.env.API_URL;
const key = process.env.SERVICE_ROLE_KEY;
const app = 'http://127.0.0.1:3000';

async function admin(route, body) {
  const res = await fetch(`${api}/auth/v1/admin/${route}`, {
    method: 'POST',
    headers: { apikey: key, Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return res.json();
}

(async () => {
  fs.mkdirSync(outDir, { recursive: true });
  // A one-time sign-in link: no email needed.
  const link = await admin('generate_link', { type: 'magiclink', email, redirect_to: app });
  if (!link.action_link) throw new Error('No sign-in link: ' + JSON.stringify(link));

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 412, height: 915 }, deviceScaleFactor: 1 });
  // The theme the app reads from shared_preferences.
  await page.addInitScript((t) => localStorage.setItem('flutter.theme', JSON.stringify(t)), theme);
  await page.goto(link.action_link);
  await page.waitForURL(/127\.0\.0\.1:3000/);
  await page.waitForTimeout(4000);
  // Flutter draws on a canvas; its accessibility tree makes text findable.
  // Its "Enable accessibility" button sits off screen on purpose.
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(1000);

  const steps = stepsFile ? JSON.parse(fs.readFileSync(stepsFile, 'utf8')) : [{ shot: 'shelf' }];
  for (const step of steps) {
    // Flutter exposes most tappable things by their label, some as text.
    if (step.tap) await page.getByLabel(step.tap).or(page.getByText(step.tap)).first().click();
    if (step.wait || step.tap) await page.waitForTimeout(step.wait ?? 1200);
    if (step.shot) {
      const file = path.join(outDir, `${theme}-${step.shot}.png`);
      await page.screenshot({ path: file });
      console.log(file);
    }
  }
  await browser.close();
})().catch((e) => { console.error(e); process.exit(1); });
