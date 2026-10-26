import '../models/food_item.dart';
import '../models/meal_entry.dart';

// Pure helpers for the History and Favorites pages. No network or widgets,
// so they can be unit tested directly.

// All meals eaten on one calendar day (in the user's local time zone)
class DayGroup {
  final DateTime day;
  final List<MealEntry> meals;

  DayGroup(this.day, this.meals);

  NutritionTotals get totals => meals.fold(
        NutritionTotals(calories: 0, protein: 0, fat: 0, carbs: 0, fiber: 0),
        (sum, meal) => sum + meal.totals,
      );
}

// A dish the user eats often but hasn't favorited yet
class FavoriteSuggestion {
  final FoodItem food;
  final int timesEaten;

  FavoriteSuggestion(this.food, this.timesEaten);
}

DateTime _localDay(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

// The server stores consumed_at in UTC, so convert to local time before
// picking the day. Otherwise an 8 PM dinner in Illinois lands on tomorrow.
// Days are newest first, and meals within a day are newest first.
List<DayGroup> groupMealsByDay(List<MealEntry> meals) {
  final byDay = <DateTime, List<MealEntry>>{};
  for (final meal in meals) {
    byDay.putIfAbsent(_localDay(meal.consumedAt), () => []).add(meal);
  }

  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return days.map((day) {
    final dayMeals = byDay[day]!
      ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
    return DayGroup(day, dayMeals);
  }).toList();
}

// Favorites are saved as FoodItem JSON, but older entries may be plain strings
String favoriteName(dynamic favorite) {
  if (favorite is Map) return (favorite['name'] ?? '').toString();
  return favorite.toString();
}

String _key(String name) => name.trim().toLowerCase();

// Dishes logged in at least [minTimes] separate meals during the last [days]
// days, excluding ones already in [favoriteNames]. Most eaten first.
List<FavoriteSuggestion> suggestFavorites(
  List<MealEntry> meals,
  Iterable<String> favoriteNames, {
  DateTime? now,
  int minTimes = 3,
  int days = 14,
}) {
  final cutoff = (now ?? DateTime.now()).subtract(Duration(days: days));
  final favorites = favoriteNames.map(_key).toSet();

  final counts = <String, int>{};
  final foods = <String, FoodItem>{};
  for (final meal in meals) {
    if (meal.consumedAt.isBefore(cutoff)) continue;

    // Count a dish once per meal, even if it was added twice
    final seenInMeal = <String>{};
    for (final food in meal.foods) {
      final key = _key(food.name);
      if (key.isEmpty || favorites.contains(key) || !seenInMeal.add(key)) {
        continue;
      }
      counts[key] = (counts[key] ?? 0) + 1;
      foods.putIfAbsent(key, () => food);
    }
  }

  final suggestions = counts.entries
      .where((e) => e.value >= minTimes)
      .map((e) => FavoriteSuggestion(foods[e.key]!, e.value))
      .toList()
    ..sort((a, b) {
      final byCount = b.timesEaten.compareTo(a.timesEaten);
      return byCount != 0 ? byCount : a.food.name.compareTo(b.food.name);
    });
  return suggestions;
}
