// Renders tool/icon/icon.svg at 1024 px twice: the whole icon (icon.png)
// and the foreground alone on transparent (foreground.png). render.py
// scales them into the app's icon files.
// Usage, from app/: node tool/icon/render.js && python3 tool/icon/render.py
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  const svg = fs.readFileSync(path.join(__dirname, 'icon.svg'), 'utf8');
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1024, height: 1024 } });
  for (const [name, css] of [
    ['icon.png', ''],
    ['foreground.png', '#wall{display:none}'],
  ]) {
    await page.setContent(
      `<style>html,body{margin:0;background:transparent}svg{display:block;width:1024px;height:1024px}${css}</style>${svg}`,
    );
    await page.screenshot({ path: path.join(__dirname, name), omitBackground: true });
  }
  await browser.close();
})();
