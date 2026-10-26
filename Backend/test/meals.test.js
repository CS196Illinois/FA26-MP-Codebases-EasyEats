const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

// Point the server at a temporary meal file so the real data is never touched
const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'easyeats-test-'));
process.env.MEAL_TRACKING_PATH = path.join(tmpDir, 'meal_tracking.json');

const { app, db } = require('../server');

const USER_ID = 999;
let server;
let baseUrl;

// Same local date format the server uses for /today-totals
function today() {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}

async function getTodayCalories() {
    const res = await fetch(`${baseUrl}/api/user/${USER_ID}/today-totals`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    return body.totals.calories;
}

test.before(async () => {
    await new Promise((resolve) => {
        server = app.listen(0, resolve);
    });
    baseUrl = `http://localhost:${server.address().port}`;
});

test.after(() => {
    server.close();
    db.close();
    fs.rmSync(tmpDir, { recursive: true, force: true });
});

test('deleting a logged meal removes its calories from today\'s totals', async () => {
    const before = await getTodayCalories();

    const logRes = await fetch(`${baseUrl}/api/user/${USER_ID}/meals`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            foods: [{ name: 'Test Pizza', calories: 300, protein: 12 }],
            meal_type: 'Lunch',
            dining_hall: 'ISR',
            consumed_at: `${today()}T12:00:00`,
        }),
    });
    assert.strictEqual(logRes.status, 201);
    const { meal } = await logRes.json();

    assert.strictEqual(await getTodayCalories(), before + 300);

    const deleteRes = await fetch(`${baseUrl}/api/user/${USER_ID}/meals/${meal.id}`, {
        method: 'DELETE',
    });
    assert.strictEqual(deleteRes.status, 200);

    assert.strictEqual(await getTodayCalories(), before);
});

test('deleting a meal that does not exist returns 404', async () => {
    const res = await fetch(`${baseUrl}/api/user/${USER_ID}/meals/12345`, {
        method: 'DELETE',
    });
    assert.strictEqual(res.status, 404);
});
