const { chromium } = require('playwright');
const fs = require('fs');
const { spawn } = require('child_process');

const DIR = 'playwright_tests/full';
if (!fs.existsSync(DIR)) fs.mkdirSync(DIR, { recursive: true });

const wait = ms => new Promise(r => setTimeout(r, ms));

// Start the mock backend from within the test so it stays alive for the full run
async function startBackend() {
  const py = 'C:\\Users\\takay\\AppData\\Local\\Programs\\Python\\Python39\\python.exe';
  const proc = spawn(py, ['-m', 'uvicorn', 'mock_backend:app', '--host', '0.0.0.0', '--port', '8282'], {
    cwd: process.cwd(),
    detached: false,
    stdio: 'ignore',
  });
  proc.on('error', e => console.error('Backend error:', e.message));
  await wait(2000); // wait for uvicorn to bind
  console.log(`[backend] Started PID ${proc.pid}`);
  return proc;
}

// Flutter CanvasKit: no real HTML inputs → use click + keyboard
async function typeInField(page, x, y, text, clear = true) {
  await page.mouse.click(x, y);
  await wait(300);
  if (clear) {
    await page.keyboard.press('Control+a');
    await wait(100);
    await page.keyboard.press('Backspace');
    await wait(100);
  }
  await page.keyboard.type(text, { delay: 20 });
  await wait(200);
}

// Navigation rail coordinates (80px wide rail, items spaced ~60px)
const NAV = { Home: [40, 100], Predict: [40, 160], Batch: [40, 220], Compare: [40, 280], Search: [40, 340] };

(async () => {
  console.log('\n=== MolPredict Full Verification ===\n');

  // Kill any stale backend and start a fresh one owned by this process
  const backend = await startBackend();

  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  await page.setViewportSize({ width: 1400, height: 900 });
  await page.goto('http://localhost:3000');
  await wait(5000);

  await page.screenshot({ path: `${DIR}/01_home.png`, fullPage: true });
  console.log('[1] Home screen');

  // ── Predict: Aspirin ──────────────────────────────────────────
  console.log('\n[2] Predict: Aspirin');
  await page.mouse.click(...NAV.Predict);
  await wait(2000);
  // Input field confirmed at x=660, y=465 from grid measurement
  await typeInField(page, 660, 465, 'CC(=O)Oc1ccccc1C(=O)O');
  await page.keyboard.press('Enter');
  await wait(7000);
  await page.screenshot({ path: `${DIR}/02_predict_aspirin.png`, fullPage: true });
  console.log('    Aspirin prediction done');

  // ── Predict: Caffeine ─────────────────────────────────────────
  console.log('\n[3] Predict: Caffeine');
  await typeInField(page, 660, 465, 'Cn1c(=O)c2c(ncn2C)n(c1=O)C');
  await page.keyboard.press('Enter');
  await wait(7000);
  await page.screenshot({ path: `${DIR}/03_predict_caffeine.png`, fullPage: true });
  console.log('    Caffeine prediction done');

  // ── Predict: invalid SMILES ───────────────────────────────────
  console.log('\n[4] Invalid SMILES error handling');
  await typeInField(page, 660, 465, 'INVALID!!!');
  await page.keyboard.press('Enter');
  await wait(3000);
  await page.screenshot({ path: `${DIR}/04_predict_error.png`, fullPage: true });
  console.log('    Error handling screenshot saved');

  // ── Batch ─────────────────────────────────────────────────────
  console.log('\n[5] Batch prediction');
  await page.mouse.click(...NAV.Batch);
  await wait(2000);
  await page.screenshot({ path: `${DIR}/05_batch_empty.png`, fullPage: true });

  // Textarea confirmed at x=730, y=215 from grid measurement
  const smilesList = 'CC(=O)Oc1ccccc1C(=O)O\nCC(=O)Nc1ccc(O)cc1\nCCO\nCn1c(=O)c2c(ncn2C)n(c1=O)C\nNCCc1ccc(O)c(O)c1';
  await page.mouse.click(730, 215);
  await wait(300);
  await page.keyboard.press('Control+a');
  await page.keyboard.press('Backspace');
  await page.keyboard.type(smilesList, { delay: 10 });
  await wait(500);
  await page.screenshot({ path: `${DIR}/06_batch_filled.png`, fullPage: true });

  // Click "Run Batch" button confirmed at x=330, y=110
  await page.mouse.click(330, 110);
  await wait(10000);
  await page.screenshot({ path: `${DIR}/07_batch_results.png`, fullPage: true });
  console.log('    Batch results done');

  // ── Compare ───────────────────────────────────────────────────
  console.log('\n[6] Compare: Aspirin vs Paracetamol');
  await page.mouse.click(...NAV.Compare);
  await wait(2000);
  await page.screenshot({ path: `${DIR}/08_compare_empty.png`, fullPage: true });

  // Two input fields confirmed from grid: mol1 at x=363,y=480; mol2 at x=945,y=480
  await typeInField(page, 363, 480, 'CC(=O)Oc1ccccc1C(=O)O');
  await typeInField(page, 945, 480, 'CC(=O)Nc1ccc(O)cc1');
  await wait(500);
  await page.screenshot({ path: `${DIR}/09_compare_filled.png`, fullPage: true });

  // Click Compare button confirmed at x=1287, y=468
  await page.mouse.click(1287, 468);
  await wait(10000);
  await page.screenshot({ path: `${DIR}/10_compare_results.png`, fullPage: true });
  console.log('    Compare results done');

  // ── PubChem Search ────────────────────────────────────────────
  console.log('\n[7] PubChem Search: caffeine');
  await page.mouse.click(...NAV.Search);
  await wait(2000);
  // Search input confirmed at x=630, y=395 from full-res screenshot
  await typeInField(page, 630, 395, 'caffeine');
  await page.keyboard.press('Enter');
  await wait(6000);
  await page.screenshot({ path: `${DIR}/11_search_caffeine.png`, fullPage: true });
  console.log('    Search result done');

  // Navigate to Predict screen with caffeine SMILES (same as "Predict Properties" button)
  await page.mouse.click(...NAV.Predict);
  await wait(1500);
  await typeInField(page, 660, 465, 'Cn1c(=O)c2c(ncn2C)n(c1=O)C');
  await page.keyboard.press('Enter');
  await wait(8000);
  await page.screenshot({ path: `${DIR}/12_predict_from_search.png`, fullPage: true });
  console.log('    Predict from search done');

  // ── Summary ───────────────────────────────────────────────────
  const shots = fs.readdirSync(DIR).filter(f => f.endsWith('.png'));
  console.log(`\n=== Done: ${shots.length} screenshots ===`);
  shots.forEach(s => console.log(`  ${s}`));

  await wait(2000);
  await browser.close();
  backend.kill();
  console.log('[backend] Stopped');
})();
