import 'package:flutter/material.dart';
import '../models/meal_entry.dart';
import '../services/meal_insights.dart';
import '../services/nutrition_service.dart';
import '../services/user_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<DayGroup> _days = [];
  bool _isLoading = true;
  String _error = '';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final user = await UserService.getCurrentUser();
      if (user == null) {
        setState(() {
          _error = 'Please log in first';
          _isLoading = false;
        });
        return;
      }

      final meals = await NutritionService.getMealHistory(user['id']);
      setState(() {
        _days = groupMealsByDay(meals);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysAgo = today.difference(day).inDays;
    if (daysAgo == 0) return 'Today';
    if (daysAgo == 1) return 'Yesterday';
    return '${_weekdays[day.weekday - 1]}, ${_months[day.month - 1]} ${day.day}';
  }

  String _timeLabel(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error, textAlign: TextAlign.center),
                  ),
                )
              : _days.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _days.length,
                        itemBuilder: (context, index) => _buildDay(_days[index]),
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No meals logged yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Meals you log from a dining hall will show up here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDay(DayGroup day) {
    final totals = day.totals;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dayLabel(day.day),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '${totals.calories.toInt()} cal • P: ${totals.protein.toInt()}g • '
            'C: ${totals.carbs.toInt()}g • F: ${totals.fat.toInt()}g',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ...day.meals.map(_buildMeal),
        ],
      ),
    );
  }

  Widget _buildMeal(MealEntry meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          '${meal.mealType} • ${meal.diningHall}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_timeLabel(meal.consumedAt)} • ${meal.foods.length} '
          '${meal.foods.length == 1 ? 'item' : 'items'} • '
          '${meal.totals.calories.toInt()} cal',
        ),
        children: meal.foods
            .map((food) => ListTile(
                  dense: true,
                  title: Text(food.name),
                  trailing: Text(
                    '${food.calories.toInt()} cal • ${food.protein.toInt()}g P',
                  ),
                ))
            .toList(),
      ),
    );
  }
}
