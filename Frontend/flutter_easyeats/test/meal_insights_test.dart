import 'package:flutter_test/flutter_test.dart';

import 'package:easyeats/models/food_item.dart';
import 'package:easyeats/models/meal_entry.dart';
import 'package:easyeats/services/meal_insights.dart';

FoodItem food(String name, {double calories = 100}) => FoodItem(
      name: name,
      calories: calories,
      protein: 10,
      totalFat: 2,
      totalCarbohydrate: 5,
    );

int _nextId = 1;

MealEntry meal(DateTime consumedAt, List<FoodItem> foods) => MealEntry(
      id: _nextId++,
      userId: 1,
      mealType: 'Lunch',
      diningHall: 'ISR',
      consumedAt: consumedAt,
      foods: foods,
      totals: NutritionTotals(
        calories: foods.fold(0, (sum, f) => sum + f.calories),
        protein: foods.fold(0, (sum, f) => sum + f.protein),
        fat: foods.fold(0, (sum, f) => sum + f.totalFat),
        carbs: foods.fold(0, (sum, f) => sum + f.totalCarbohydrate),
        fiber: 0,
      ),
    );

void main() {
  group('groupMealsByDay', () {
    test('returns nothing for an empty history', () {
      expect(groupMealsByDay([]), isEmpty);
    });

    test('groups meals by day, newest day first, with daily totals', () {
      final groups = groupMealsByDay([
        meal(DateTime(2026, 10, 20, 8), [food('Eggs', calories: 200)]),
        meal(DateTime(2026, 10, 22, 12), [food('Rice', calories: 300)]),
        meal(DateTime(2026, 10, 20, 18), [food('Pasta', calories: 500)]),
      ]);

      expect(groups.length, 2);
      expect(groups[0].day, DateTime(2026, 10, 22));
      expect(groups[1].day, DateTime(2026, 10, 20));
      expect(groups[1].meals.length, 2);
      expect(groups[1].totals.calories, 700);
    });

    test('orders meals within a day newest first', () {
      final groups = groupMealsByDay([
        meal(DateTime(2026, 10, 20, 8), [food('Eggs')]),
        meal(DateTime(2026, 10, 20, 18), [food('Pasta')]),
      ]);

      expect(groups.single.meals.first.foods.single.name, 'Pasta');
    });

    test('uses the local day for UTC timestamps from the server', () {
      // A late-evening local meal can fall on the next day in UTC
      final localEvening = DateTime(2026, 10, 20, 23, 30);
      final groups = groupMealsByDay([
        meal(localEvening.toUtc(), [food('Pizza')]),
      ]);

      expect(groups.single.day, DateTime(2026, 10, 20));
    });
  });

  group('suggestFavorites', () {
    final now = DateTime(2026, 10, 25, 12);

    List<MealEntry> eaten(String name, int times) => List.generate(
          times,
          (i) => meal(now.subtract(Duration(days: i)), [food(name)]),
        );

    test('suggests a dish eaten 3 times', () {
      final suggestions = suggestFavorites(eaten('Tofu', 3), [], now: now);

      expect(suggestions.single.food.name, 'Tofu');
      expect(suggestions.single.timesEaten, 3);
    });

    test('does not suggest a dish eaten only twice', () {
      expect(suggestFavorites(eaten('Tofu', 2), [], now: now), isEmpty);
    });

    test('skips dishes that are already favorites, ignoring case', () {
      expect(suggestFavorites(eaten('Tofu', 3), ['tofu'], now: now), isEmpty);
    });

    test('ignores meals older than the time window', () {
      final old = List.generate(
        3,
        (i) => meal(now.subtract(Duration(days: 30 + i)), [food('Tofu')]),
      );

      expect(suggestFavorites(old, [], now: now), isEmpty);
    });

    test('counts a dish once per meal', () {
      final meals = [
        meal(now, [food('Tofu'), food('Tofu'), food('Tofu')]),
      ];

      expect(suggestFavorites(meals, [], now: now), isEmpty);
    });

    test('lists the most eaten dishes first', () {
      final suggestions = suggestFavorites(
        [...eaten('Tofu', 3), ...eaten('Rice', 5)],
        [],
        now: now,
      );

      expect(suggestions.map((s) => s.food.name), ['Rice', 'Tofu']);
    });

    test('returns nothing for an empty history', () {
      expect(suggestFavorites([], [], now: now), isEmpty);
    });
  });

  group('favoriteName', () {
    test('reads saved food items and plain strings', () {
      expect(favoriteName({'name': 'Tofu', 'calories': 100}), 'Tofu');
      expect(favoriteName('Rice'), 'Rice');
    });
  });
}
