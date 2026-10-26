import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../models/meal_entry.dart';

class NutritionService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Get all dining halls
  static Future<List<String>> getDiningHalls() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dining-halls'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['dining_halls'] ?? []);
      } else {
        throw Exception('Failed to load dining halls');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get foods for a dining hall
  static Future<List<FoodItem>> getFoodsForDiningHall(
    String diningHall, {
    String? mealType,
    String? date,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/dining-halls/$diningHall/foods');

      final queryParams = <String, String>{};
      if (mealType != null) queryParams['meal_type'] = mealType;
      if (date != null) queryParams['date'] = date;

      uri = uri.replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foodsList = data['foods'] as List;
        return foodsList.map((f) => FoodItem.fromJson(f)).toList();
      } else {
        throw Exception('Failed to load foods');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get recommended foods for user
  static Future<Map<String, dynamic>> getRecommendations(
    int userId,
    String diningHall, {
    String? mealType,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/recommendations/$userId');

      final queryParams = <String, String>{'dining_hall': diningHall};
      if (mealType != null) queryParams['meal_type'] = mealType;

      uri = uri.replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'recommendations': (data['recommendations'] as List)
              .map((f) => FoodItem.fromJson(f))
              .toList(),
          'user_target_calories': data['user_target_calories'],
          'goal': data['goal'],
          'count': data['count'],
        };
      } else {
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Log a consumed meal
  static Future<MealEntry> logMeal(
    int userId,
    List<FoodItem> foods, {
    String? mealType,
    String? diningHall,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/meals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'foods': foods.map((f) => f.toJson()).toList(),
          'meal_type': mealType ?? 'Snack',
          'dining_hall': diningHall ?? 'Unknown',
          'consumed_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return MealEntry.fromJson(data['meal']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to log meal');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get user's meal history
  static Future<List<MealEntry>> getMealHistory(
    int userId, {
    String? date,
    int? limit,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/user/$userId/meals');

      final queryParams = <String, String>{};
      if (date != null) queryParams['date'] = date;
      if (limit != null) queryParams['limit'] = limit.toString();

      uri = uri.replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final mealsList = data['meals'] as List;
        return mealsList.map((m) => MealEntry.fromJson(m)).toList();
      } else {
        throw Exception('Failed to load meal history');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get today's nutrition totals
  static Future<Map<String, dynamic>> getTodayTotals(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/today-totals'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'totals': NutritionTotals.fromJson(data['totals']),
          'date': data['date'],
          'meals': (data['meals'] as List)
              .map((m) => MealEntry.fromJson(m))
              .toList(),
        };
      } else {
        throw Exception('Failed to load today\'s totals');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Delete a meal entry
  static Future<void> deleteMeal(int userId, int mealId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/$userId/meals/$mealId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete meal');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get the user's saved favorites (stored on their profile)
  static Future<List<dynamic>> getFavorites(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/profile'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['favorites'] as List? ?? [];
      } else {
        throw Exception('Failed to load favorites');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Save a food to favorites. The server ignores duplicates.
  static Future<List<dynamic>> addFavorite(int userId, FoodItem food) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/favorites'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'foodItem': food.toJson()}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data['favorites'] as List? ?? [];
      } else {
        throw Exception(data['error'] ?? 'Failed to add favorite');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Remove a favorite by its position in the list from getFavorites()
  static Future<List<dynamic>> removeFavorite(int userId, int index) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/$userId/favorites/$index'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data['favorites'] as List? ?? [];
      } else {
        throw Exception(data['error'] ?? 'Failed to remove favorite');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
