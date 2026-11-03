// Builds the food ranking used by /api/recommendations based on the user's goal

// Add-ons that shouldn't be recommended as foods on their own
const EXCLUDED_CATEGORIES = ['Dressings & Condiments', 'Sauces', 'Toppings'];

// ORDER BY clause for each ranking. The *_ratio columns are the share of a
// food's calories that come from protein, carbs, and fat.
const RANKINGS = {
    // Lean, filling foods: most protein per calorie, then least fat, then most fiber
    lose: 'protein_ratio DESC, fat_ratio ASC, dietary_fiber DESC',
    // Calorie-dense foods, with protein weighted so entrees beat desserts
    gain: '(calories + protein * 10) DESC',
    // Closest to a balanced 30/40/30 protein/carb/fat split
    fit: 'ABS(protein_ratio - 0.30) + ABS(carb_ratio - 0.40) + ABS(fat_ratio - 0.30) ASC, protein DESC',
};

// Missing or unrecognized goals keep the original protein-first ranking
RANKINGS.default = RANKINGS.lose;

// Goals come from the questionnaire ("Losing weight", "Gaining weight",
// "Becoming fit") or free text on the profile page, so match on keywords
function getRanking(goal) {
    const text = (goal || '').toLowerCase();

    if (/\blos|\bcut/.test(text)) return 'lose';
    if (/\bgain|\bbulk|muscle/.test(text)) return 'gain';
    if (/\bfit|maintain|balance|health/.test(text)) return 'fit';
    return 'default';
}

function buildRecommendationQuery(diningHall, mealType, ranking) {
    let query = `
        SELECT DISTINCT name, category, serving_size, calories, protein,
               total_fat, total_carbohydrate, dietary_fiber, sugars, sodium,
               (protein * 4.0 / NULLIF(calories, 0)) as protein_ratio,
               (total_carbohydrate * 4.0 / NULLIF(calories, 0)) as carb_ratio,
               (total_fat * 9.0 / NULLIF(calories, 0)) as fat_ratio
        FROM nutrition_data
        WHERE dining_hall LIKE ?
        AND calories > 0
        AND (category IS NULL OR category NOT IN (${EXCLUDED_CATEGORIES.map(() => '?').join(', ')}))
    `;
    const params = [`%${diningHall}%`, ...EXCLUDED_CATEGORIES];

    if (mealType) {
        query += ` AND meal_type = ?`;
        params.push(mealType);
    }

    query += `
        GROUP BY name
        ORDER BY ${RANKINGS[ranking] || RANKINGS.default}
        LIMIT 20
    `;

    return { query, params };
}

module.exports = {
    EXCLUDED_CATEGORIES,
    getRanking,
    buildRecommendationQuery,
};
