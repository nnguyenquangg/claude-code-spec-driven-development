// Throwaway UI walkthrough (ui-walkthrough skill). Copy to the scratchpad, fill in `steps`, run:
//   NODE_PATH=<repo>/node_modules node walk.mjs
// Screenshots land in $WALK_OUT (or ./shots/). Read every one of them afterwards.
// Every step CHECKS its result with `expect` (never a bare timeout): a step that silently did
// nothing is the failure a walkthrough exists to catch. A failed check stops the walk, shoots the
// page and exits 1.
// Verify like QA, through the real API: a write is wrapped in act() (awaits the page's request,
// fails on non-2xx) and then read back with `api`; every backend call lands in api.log and any
// 4xx/5xx the page made fails the walk.
import { appendFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const require = createRequire(join(process.env.NODE_PATH ?? process.cwd(), 'noop.js'));
const { chromium, request: pwRequest } = require('playwright');
const { expect } = require('@playwright/test');

const BASE_URL = process.env.WALK_BASE_URL ?? 'http://localhost:3000';
// the real backend the page talks to; its calls are recorded and asserted
const API_URL = new URL(process.env.WALK_API_URL ?? 'http://localhost:5000/api/v1');
const API_ORIGIN = API_URL.origin;
const API_PATH = API_URL.pathname.replace(/\/+$/, ''); // '' when the API sits at the origin root
const API = API_ORIGIN + API_PATH; // normalised base for the read-back client: no trailing slash, no query
// WALK_OUT: the slice folder from the skill's step 2, <repo>/verify-screenshots/<date>-<task>/<slice>
// (git-excluded); without it the shots land in ./shots next to this throwaway script.
const OUT = process.env.WALK_OUT ?? join(dirname(fileURLToPath(import.meta.url)), 'shots');
mkdirSync(OUT, { recursive: true });

// WALK_CHANNEL=chrome uses the installed Google Chrome (works where the bundled Chromium is
// unsupported); leave it unset for Playwright's own browser. WALK_VIEWPORT=390x844 for phone
// (a project standard that asks for both viewports wins: walk twice).
const browser = await chromium.launch({ channel: process.env.WALK_CHANNEL || undefined });
const [width, height] = (process.env.WALK_VIEWPORT ?? '1440x900').split('x').map(Number);
const page = await browser.newPage({ viewport: { width, height } });
page.setDefaultTimeout(10_000);

const log = [];
page.on('console', (m) => m.type() === 'error' && log.push(`console: ${m.text()}`));
page.on('pageerror', (e) => log.push(`pageerror: ${e.message}`));

// every call the page makes to the backend: "<METHOD> <path?query> <status>". `rel` is the raw
// path + query that act() matches against; `logged` masks values of secret-named query keys
// (the last word of the key: `token`, `reset_code`, `apiKey`, `accessToken`, `X-Amz-Signature`;
// not `keyword` or `authorId`) so api.log and error messages never carry them. Over-masking
// (`zipCode`) is harmless: act() matches the raw `rel`.
const SECRET_WORD = 'token|code|secret|password|passwd|key|sig|signature|session|auth|jwt|otp|apikey|accesstoken|authtoken|sessionid|sid';
const SECRET_KEY = new RegExp(`(^|[_-])(${SECRET_WORD})$`, 'i');       // token, reset_code, x-api-key
const SECRET_CAMEL = new RegExp(`[a-z0-9](${SECRET_WORD.replace(/(^|\|)(\w)/g, (m, s, c) => s + c.toUpperCase())})$`); // accessToken
const isSecretKey = (k) => {
  let name = k;
  try { name = decodeURIComponent(k); } catch { /* malformed %-escape: test the raw key */ }
  return SECRET_KEY.test(name) || SECRET_CAMEL.test(name);
};
const rel = (u) => { const url = new URL(u); return url.pathname.slice(API_PATH.length) + url.search; };
const logged = (u) => {
  const url = new URL(u);
  const q = url.search.slice(1).split('&').filter(Boolean).map((pair) => {
    const [k, ...v] = pair.split('=');
    return isSecretKey(k) && v.length ? `${k}=***` : pair;
  });
  return url.pathname.slice(API_PATH.length) + (q.length ? `?${q.join('&')}` : '');
};
// a backend call: same origin as API and under its path ("/api" does not match "/apiary")
const isApi = (u) => {
  const url = new URL(u);
  return url.origin === API_ORIGIN && (url.pathname === API_PATH || url.pathname.startsWith(`${API_PATH}/`));
};
const calls = [];
page.on('response', (r) => {
  if (isApi(r.url())) calls.push(`${r.request().method()} ${logged(r.url())} ${r.status()}`);
});
// a user action and the backend call it must make (pathRe matches path + query); returns its data
const act = async (method, pathRe, action) => {
  const [res] = await Promise.all([
    page.waitForResponse((r) => isApi(r.url()) && r.request().method() === method && pathRe.test(rel(r.url()))),
    action(),
  ]);
  // only the start of the error body: enough to diagnose, too short to carry a whole payload
  if (res.status() >= 400) throw new Error(`${method} ${logged(res.url())} -> ${res.status()} ${(await res.text()).slice(0, 200)}`);
  // empty, non-JSON or un-enveloped bodies are fine: return the parsed body, its `data` if it has one
  const text = await res.text();
  if (!text) return null;
  let body;
  try { body = JSON.parse(text); } catch { return text; }
  return body && typeof body === 'object' && 'data' in body ? body.data : body;
};
// read-back client: log in over the API the way the project's e2e fixture does, e.g.
//   const token = (await (await api.post(`${API}/auth/login`, { data: { email, password } })).json()).data.access_token;
//   const get = async (path) => (await (await api.get(`${API}${path}`, { headers: { Authorization: `Bearer ${token}` } })).json()).data;
const api = await pwRequest.newContext();

// WALK_FROM=4 on a partial re-walk: the first shot is 04-..., so it replaces the shot it re-takes
let n = Math.max(0, Number(process.env.WALK_FROM || 1) - 1);
const shot = async (name) => {
  const file = join(OUT, `${String(++n).padStart(2, '0')}-${name}.png`);
  await page
    .waitForLoadState('networkidle')
    .catch((e) => log.push(`networkidle not reached before ${name}: ${e.message}`));
  // let dialogs / toasts finish animating so the shot shows the settled screen
  await page.evaluate(() => Promise.all(document.getAnimations()
    .filter((a) => a.effect?.getTiming().iterations !== Infinity)
    .map((a) => a.finished.catch(() => {}))));
  await page.screenshot({ path: file, fullPage: true });
  console.log(`shot ${file}`);
};

// ---- steps: user action -> expect(the result a user would see) -> shot() -----------------
const steps = async () => {
  await page.goto(`${BASE_URL}/login`);
  await expect(page.getByRole('button', { name: 'Login' })).toBeVisible();
  await shot('login');
  // await page.getByLabel('Email').fill(process.env.WALK_EMAIL);
  // await page.getByLabel('Password').fill(process.env.WALK_PASSWORD);
  // await page.getByRole('button', { name: 'Login' }).click();
  // await expect(page).toHaveURL(/dashboard/);
  // await shot('dashboard');
  // A write, proven on the backend:
  // const saved = await act('POST', /^\/projects$/, () => dialog.getByRole('button', { name: 'Create project' }).click());
  // await expect(page.getByText('created')).toBeVisible();
  // expect(await get(`/projects/${saved.id}`)).toMatchObject({ name: 'Typed name', status: 'ACTIVE' });
  // await shot('created');
};
// -----------------------------------------------------------------------------------------

try {
  await steps();
  const bad = calls.filter((c) => /\s[45]\d\d$/.test(c));
  if (bad.length) throw new Error(`backend errors: ${bad.join(', ')}`);
} catch (error) {
  console.log(`STEP FAILED: ${error.message.split('\n').slice(0, 4).join(' | ')}`);
  await shot('failed');
  process.exitCode = 1;
} finally {
  // appended, one header per run: a partial re-walk keeps the calls the earlier steps made
  appendFileSync(join(OUT, 'api.log'), `# walk ${new Date().toISOString()}\n` + calls.join('\n') + '\n');
  if (log.length) console.log(log.join('\n'));
  await browser.close();
  await api.dispose();
}
