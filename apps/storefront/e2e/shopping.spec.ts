import { test, expect, type Page } from '@playwright/test';

const ADMIN_URL = process.env.ADMIN_URL ?? 'http://localhost:3000';

async function addCandleToCart(page: Page) {
  await page.goto('/products/fynbos-soy-candle');
  await page.getByRole('button', { name: 'Add to cart', exact: true }).click();
  await expect(page.getByText('Added to your cart')).toBeVisible();
}

async function fillAddress(page: Page) {
  await page.fill('#email', `e2e.${Date.now()}@example.co.za`);
  await page.fill('#first_name', 'Nomsa');
  await page.fill('#last_name', 'Khumalo');
  await page.fill('#phone', '0827776666');
  await page.fill('#address1', '14 Mphuthi Street');
  await page.fill('#city', 'Khayelitsha');
  await page.fill('#postal_code', '7784');
  await page.selectOption('#state_abbr', 'WC');
  await page.getByRole('button', { name: /Continue to delivery/ }).click();
}

test('home, shop filters and seller pages render with catalogue data', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: /Shop local/ })).toBeVisible();
  await page.goto('/shop?province=KZN');
  await expect(page.getByText('Marula Oil Face Serum')).toBeVisible();
  await page.goto('/sellers/mzansi-clay-studio');
  await expect(page.getByRole('heading', { level: 1, name: 'Mzansi Clay Studio' })).toBeVisible();
});

test('pickup-point checkout with manual EFT places an order', async ({ page }) => {
  await addCandleToCart(page);
  await page.goto('/checkout');
  await fillAddress(page);
  await page.getByRole('button', { name: /Collect at a Paxi point/ }).click();
  await expect(page.getByText('Choose your Paxi point')).toBeVisible();
  // payment stays locked until a pickup point is chosen
  await expect(page.getByText('Manual EFT / Bank transfer')).toHaveCount(0);
  await page.getByRole('button', { name: /Khayelitsha, Cape Town/ }).first().click();
  await expect(page.getByText(/Collect at SAMPLE Paxi point/).first()).toBeVisible();
  await page.getByText('Manual EFT / Bank transfer').click();
  await page.getByRole('button', { name: /Place order/ }).click();
  await expect(page).toHaveURL(/\/orders\/or_.*placed=1/);
  await expect(page.getByRole('heading', { name: /Order placed/ })).toBeVisible();
  await expect(page.getByText(/Collect at SAMPLE Paxi point/)).toBeVisible();
});

test('online payment hands the shopper to PayFast with the order total', async ({ page }) => {
  await addCandleToCart(page);
  await page.goto('/checkout');
  await fillAddress(page);
  await page.getByRole('button', { name: /Courier to your door/ }).click();
  const payButton = page.getByRole('button', { name: /Pay R.*securely/ });
  await expect(payButton).toBeVisible();
  // Don't leave the site: capture the form the storefront submits to PayFast
  await page.route('https://sandbox.payfast.co.za/**', (route) => route.fulfill({ status: 200, contentType: 'text/html', body: 'ok' }));
  const [request] = await Promise.all([
    page.waitForRequest((r) => r.url().startsWith('https://sandbox.payfast.co.za/eng/process') && r.method() === 'POST'),
    payButton.click(),
  ]);
  const posted = new URLSearchParams(request.postData() ?? '');
  expect(posted.get('merchant_id')).toBeTruthy();
  expect(Number(posted.get('amount'))).toBeGreaterThan(0);
  expect(posted.get('notify_url')).toMatch(/\/api\/v3\/webhooks\/payments\/pm_/);
  expect(posted.get('return_url')).toMatch(/\/checkout\/payment\/return\?payment_session=ps_/);
});

test('seller application is accepted and invalid referral codes are rejected', async ({ page }) => {
  const apply = async (name: string, referral?: string) => {
    await page.goto('/sell?apply=' + Date.now());
    await page.fill('#name', name);
    await page.selectOption('#primary_category', 'Food & Pantry');
    await page.selectOption('#business_type', 'sole_proprietor');
    await page.selectOption('#province', 'LP');
    await page.fill('#city', 'Polokwane');
    await page.fill('#contact_name', 'Sipho');
    await page.fill('#email', 'sipho@example.co.za');
    await page.fill('#phone', '0830000000');
    if (referral) await page.fill('#referral_code', referral);
    await page.check('input[name=consent]');
    await page.getByRole('button', { name: /Submit application/ }).click();
  };
  await apply(`E2E Spaza ${Date.now()}`);
  await expect(page.getByText('Application received!')).toBeVisible();
  await apply(`E2E Bad Code ${Date.now()}`, 'NOTREAL');
  await expect(page.getByText(/Referral code is invalid/)).toBeVisible();
});

test('admin finance, payouts and partners pages load', async ({ page }) => {
  await page.goto(`${ADMIN_URL}/admin`);
  await page.fill('input[type=email]', process.env.ADMIN_EMAIL ?? 'spree@example.com');
  await page.fill('input[type=password]', process.env.ADMIN_PASSWORD ?? 'spree123');
  await page.click('[type=submit]');
  for (const [path, heading] of [['/admin/finance', 'Finance'], ['/admin/payout_batches', 'Payout runs'], ['/admin/partners', 'Partners'], ['/admin/sellers', 'Sellers']]) {
    await page.goto(`${ADMIN_URL}${path}`);
    await expect(page.getByRole('heading', { name: heading }).first()).toBeVisible();
  }
});
