// Starts the real server against a temporary data folder, so the
// checked-in users.json and meal_tracking.json are never touched.
const { test, before, after } = require('node:test');
const assert = require('node:assert');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const PORT = 3999;
const BASE = `http://localhost:${PORT}/api`;
let server;
let dataDir;
let userId;

async function api(method, route, body) {
    const res = await fetch(`${BASE}${route}`, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: body ? JSON.stringify(body) : undefined,
    });
    return { status: res.status, body: await res.json() };
}

before(async () => {
    dataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'easyeats-test-'));
    server = spawn('node', [path.join(__dirname, '..', 'server.js')], {
        env: { ...process.env, PORT, EASYEATS_DATA_DIR: dataDir },
        stdio: ['ignore', 'pipe', 'inherit'],
    });
    await new Promise(resolve => {
        server.stdout.on('data', data => {
            if (data.toString().includes('Server running')) resolve();
        });
    });

    const res = await api('POST', '/auth/register', { email: 'test@illinois.edu', password: 'secret123' });
    userId = res.body.id;
});

after(() => {
    server.kill();
    fs.rmSync(dataDir, { recursive: true, force: true });
});

const tofu = { name: 'Tofu Stir Fry', calories: 250, protein: 15 };

test('a new user has no favorites', async () => {
    const res = await api('GET', `/user/${userId}/profile`);
    assert.deepStrictEqual(res.body.favorites, []);
});

test('adding a favorite saves it to the profile', async () => {
    await api('POST', `/user/${userId}/favorites`, { foodItem: tofu });
    const res = await api('GET', `/user/${userId}/profile`);
    assert.deepStrictEqual(res.body.favorites, [tofu]);
});

test('adding the same dish twice only stores it once', async () => {
    const res = await api('POST', `/user/${userId}/favorites`, { foodItem: { ...tofu, name: 'tofu stir fry ' } });
    assert.strictEqual(res.body.favorites.length, 1);
});

test('deleting with an invalid index is rejected and removes nothing', async () => {
    for (const index of ['abc', '-1', '5']) {
        const res = await api('DELETE', `/user/${userId}/favorites/${index}`);
        assert.strictEqual(res.status, 400);
    }
    const res = await api('GET', `/user/${userId}/profile`);
    assert.strictEqual(res.body.favorites.length, 1);
});

test('deleting a favorite removes it', async () => {
    await api('DELETE', `/user/${userId}/favorites/0`);
    const res = await api('GET', `/user/${userId}/profile`);
    assert.deepStrictEqual(res.body.favorites, []);
});

test('logged meals show up in meal history', async () => {
    await api('POST', `/user/${userId}/meals`, { foods: [tofu], meal_type: 'Lunch', dining_hall: 'ISR' });
    const res = await api('GET', `/user/${userId}/meals`);
    assert.strictEqual(res.body.count, 1);
    assert.strictEqual(res.body.meals[0].foods[0].name, 'Tofu Stir Fry');
    assert.strictEqual(res.body.meals[0].totals.calories, 250);
});
