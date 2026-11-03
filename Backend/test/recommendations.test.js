const { test, describe, before, after } = require('node:test');
const assert = require('node:assert');
const path = require('path');
const sqlite3 = require('sqlite3');
const { EXCLUDED_CATEGORIES, getRanking, buildRecommendationQuery } = require('../recommendations');

const dbPath = path.join(__dirname, '..', 'data', 'nutrition_data.db');
let db;

function recommend(diningHall, mealType, ranking) {
    const { query, params } = buildRecommendationQuery(diningHall, mealType, ranking);
    return new Promise((resolve, reject) => {
        db.all(query, params, (err, rows) => (err ? reject(err) : resolve(rows)));
    });
}

function average(foods, field) {
    return foods.reduce((sum, f) => sum + f[field], 0) / foods.length;
}

// How far a food's calories are from a 30/40/30 protein/carb/fat split
function macroDistance(food) {
    return Math.abs(food.protein_ratio - 0.3)
        + Math.abs(food.carb_ratio - 0.4)
        + Math.abs(food.fat_ratio - 0.3);
}

describe('getRanking', () => {
    test('maps questionnaire goals', () => {
        assert.strictEqual(getRanking('Losing weight'), 'lose');
        assert.strictEqual(getRanking('Gaining weight'), 'gain');
        assert.strictEqual(getRanking('Becoming fit'), 'fit');
    });

    test('maps free-text profile goals', () => {
        assert.strictEqual(getRanking('Lose weight'), 'lose');
        assert.strictEqual(getRanking('cutting'), 'lose');
        assert.strictEqual(getRanking('Build muscle'), 'gain');
        assert.strictEqual(getRanking('bulk'), 'gain');
        assert.strictEqual(getRanking('stay healthy'), 'fit');
    });

    test('falls back to default for missing or unknown goals', () => {
        assert.strictEqual(getRanking(null), 'default');
        assert.strictEqual(getRanking(undefined), 'default');
        assert.strictEqual(getRanking(''), 'default');
        assert.strictEqual(getRanking('eat more vegetables'), 'default');
    });
});

describe('buildRecommendationQuery', () => {
    before(() => {
        db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY);
    });

    after(() => {
        db.close();
    });

    test('gain recommends more calories than lose', async () => {
        const gain = await recommend('ISR', 'Lunch', 'gain');
        const lose = await recommend('ISR', 'Lunch', 'lose');

        assert.ok(average(gain, 'calories') > average(lose, 'calories'));
    });

    test('lose recommends more protein per calorie than gain', async () => {
        const gain = await recommend('ISR', 'Lunch', 'gain');
        const lose = await recommend('ISR', 'Lunch', 'lose');

        assert.ok(average(lose, 'protein_ratio') > average(gain, 'protein_ratio'));
    });

    test('fit recommends foods closest to a balanced macro split', async () => {
        const fit = await recommend('ISR', 'Lunch', 'fit');

        for (const other of ['lose', 'gain']) {
            const foods = await recommend('ISR', 'Lunch', other);
            const fitDistance = fit.reduce((sum, f) => sum + macroDistance(f), 0);
            const otherDistance = foods.reduce((sum, f) => sum + macroDistance(f), 0);
            assert.ok(fitDistance < otherDistance, `fit should beat ${other}`);
        }
    });

    test('unknown ranking uses the default order', async () => {
        const unknown = await recommend('ISR', 'Lunch', 'not-a-ranking');
        const fallback = await recommend('ISR', 'Lunch', 'default');

        assert.deepStrictEqual(unknown.map(f => f.name), fallback.map(f => f.name));
    });

    test('every ranking returns at most 20 real foods', async () => {
        for (const ranking of ['lose', 'gain', 'fit', 'default']) {
            const foods = await recommend('ISR', 'Lunch', ranking);

            assert.ok(foods.length > 0 && foods.length <= 20, ranking);
            for (const food of foods) {
                assert.ok(food.calories > 0, `${ranking}: ${food.name} has no calories`);
                assert.ok(!EXCLUDED_CATEGORIES.includes(food.category),
                    `${ranking}: ${food.name} is a ${food.category}`);
            }
        }
    });

    test('filters by meal type', async () => {
        const breakfast = await recommend('PAR', 'Breakfast', 'gain');
        const dinner = await recommend('LAR', 'Dinner', 'gain');

        assert.ok(breakfast.length > 0);
        assert.strictEqual(dinner.length, 0); // LAR has no dinner data
    });
});
