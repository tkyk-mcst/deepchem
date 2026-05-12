const { chromium } = require('playwright');
const fs = require('fs');

const DIR = 'playwright_tests/layout';
if (!fs.existsSync(DIR)) fs.mkdirSync(DIR, { recursive: true });
const wait = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  await page.setViewportSize({ width: 1400, height: 900 });
  await page.goto('http://localhost:3000');
  await wait(4000);

  // Click Predict nav
  await page.mouse.click(40, 160);
  await wait(2000);
  await page.screenshot({ path: `${DIR}/predict_base.png`, fullPage: true });

  // Draw grid overlay to measure layout
  await page.evaluate(() => {
    const overlay = document.createElement('div');
    overlay.style.cssText = `
      position:fixed; top:0; left:0; width:100%; height:100%;
      pointer-events:none; z-index:9999;
    `;
    // Draw horizontal lines every 50px
    for (let y = 0; y <= 900; y += 50) {
      const line = document.createElement('div');
      line.style.cssText = `position:absolute;top:${y}px;left:0;right:0;height:1px;background:rgba(255,0,0,0.4);`;
      const label = document.createElement('div');
      label.style.cssText = `position:absolute;top:${y}px;left:2px;color:red;font-size:10px;background:black;`;
      label.textContent = `y=${y}`;
      overlay.appendChild(line);
      overlay.appendChild(label);
    }
    // Draw vertical lines every 100px
    for (let x = 0; x <= 1400; x += 100) {
      const line = document.createElement('div');
      line.style.cssText = `position:absolute;left:${x}px;top:0;bottom:0;width:1px;background:rgba(0,0,255,0.4);`;
      const label = document.createElement('div');
      label.style.cssText = `position:absolute;left:${x}px;top:2px;color:blue;font-size:10px;background:black;`;
      label.textContent = `x=${x}`;
      overlay.appendChild(line);
      overlay.appendChild(label);
    }
    document.body.appendChild(overlay);
  });
  await wait(500);
  await page.screenshot({ path: `${DIR}/predict_grid.png`, fullPage: true });

  // Batch screen
  await page.mouse.click(40, 220);
  await wait(1500);
  await page.screenshot({ path: `${DIR}/batch_grid.png`, fullPage: true });

  // Compare screen
  await page.mouse.click(40, 280);
  await wait(1500);
  await page.screenshot({ path: `${DIR}/compare_grid.png`, fullPage: true });

  // Search screen
  await page.mouse.click(40, 340);
  await wait(1500);
  await page.screenshot({ path: `${DIR}/search_grid.png`, fullPage: true });

  console.log('Layout screenshots saved to playwright_tests/layout/');
  await wait(1000);
  await browser.close();
})();
