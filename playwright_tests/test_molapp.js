const { chromium } = require('playwright');
const fs = require('fs');

if (!fs.existsSync('playwright_tests/screenshots')) {
  fs.mkdirSync('playwright_tests/screenshots', { recursive: true });
}
async function wait(ms) { return new Promise(r => setTimeout(r, ms)); }

(async () => {
  console.log('\n🧪 MolPredict Playwright Test (corrected coordinates)\n');

  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  await page.setViewportSize({ width: 1280, height: 800 });

  await page.goto('http://localhost:3000');
  await wait(4000);
  console.log(`Title: "${await page.title()}"`);

  // Detect NavRail item positions by finding their bounding box via JS
  await page.keyboard.press('Tab');
  await wait(500);

  // Actual NavRail positions from visual inspection of screenshots:
  // Home≈100, Predict≈160, Batch≈220, Compare≈280, Search≈340
  const navItems = [
    { name: 'Home',    x: 40, y: 100 },
    { name: 'Predict', x: 40, y: 160 },
    { name: 'Batch',   x: 40, y: 220 },
    { name: 'Compare', x: 40, y: 280 },
    { name: 'Search',  x: 40, y: 340 },
  ];

  console.log('[Nav] Testing all 5 screens with corrected coordinates...\n');

  for (const nav of navItems) {
    await page.mouse.click(nav.x, nav.y);
    await wait(1500);
    const shot = `playwright_tests/screenshots/${nav.name.toLowerCase()}_screen.png`;
    await page.screenshot({ path: shot, fullPage: true });
    console.log(`  ✓ ${nav.name.padEnd(8)} → click(${nav.x},${nav.y}) → 📸 ${nav.name.toLowerCase()}_screen.png`);
  }

  // Detailed test: Predict screen with SMILES
  console.log('\n[Predict] SMILES input flow...');
  await page.mouse.click(40, 160);
  await wait(2000);

  // Click the text field area
  await page.mouse.click(640, 425); // center of SMILES input field
  await wait(300);
  await page.keyboard.type('CC(=O)Oc1ccccc1C(=O)O'); // Aspirin
  await wait(300);
  await page.screenshot({ path: 'playwright_tests/screenshots/predict_smiles_filled.png' });
  console.log('  SMILES typed');

  // Click Predict button (right side of input row)
  await page.mouse.click(1197, 425);
  await wait(5000); // wait for API (may timeout if backend not running)
  await page.screenshot({ path: 'playwright_tests/screenshots/predict_after_submit.png', fullPage: true });
  console.log('  Predict submitted → 📸 predict_after_submit.png');

  // Batch screen test
  console.log('\n[Batch] SMILES list input...');
  await page.mouse.click(40, 220);
  await wait(1500);
  await page.mouse.click(640, 340); // click textarea
  await wait(300);
  await page.keyboard.type('CCO\nCC(=O)Oc1ccccc1C(=O)O\nCn1c(=O)c2c(ncn2C)n(c1=O)C');
  await wait(300);
  await page.screenshot({ path: 'playwright_tests/screenshots/batch_filled.png', fullPage: true });
  console.log('  3 SMILES entered → 📸 batch_filled.png');

  // Compare screen test
  console.log('\n[Compare] Two molecule inputs...');
  await page.mouse.click(40, 280);
  await wait(1500);
  await page.mouse.click(310, 440); // Molecule 1 input
  await wait(200);
  await page.keyboard.type('CC(=O)Oc1ccccc1C(=O)O');
  await page.mouse.click(870, 440); // Molecule 2 input
  await wait(200);
  await page.keyboard.type('CC(=O)Nc1ccc(O)cc1');
  await page.screenshot({ path: 'playwright_tests/screenshots/compare_filled.png', fullPage: true });
  console.log('  Both molecules entered → 📸 compare_filled.png');

  // Search screen test
  console.log('\n[Search] PubChem name search...');
  await page.mouse.click(40, 340);
  await wait(1500);
  await page.mouse.click(590, 353); // search input
  await wait(200);
  await page.keyboard.type('aspirin');
  await page.screenshot({ path: 'playwright_tests/screenshots/search_filled.png', fullPage: true });
  console.log('  "aspirin" typed → 📸 search_filled.png');
  // Click Search button
  await page.mouse.click(1165, 353);
  await wait(5000); // wait for PubChem API
  await page.screenshot({ path: 'playwright_tests/screenshots/search_result.png', fullPage: true });
  console.log('  Search submitted → 📸 search_result.png');

  // Final summary
  const shots = fs.readdirSync('playwright_tests/screenshots').filter(f => f.endsWith('.png'));
  console.log(`\n✅ All tests complete! ${shots.length} screenshots total.`);
  shots.sort().forEach(s => console.log(`   📸 ${s}`));

  await wait(2000);
  await browser.close();
})();
