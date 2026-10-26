import 'package:flutter/material.dart';
import '../models/meal_entry.dart';
import '../services/meal_insights.dart';
import '../services/nutrition_service.dart';
import '../services/user_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<dynamic> _favorites = [];
  List<FavoriteSuggestion> _suggestions = [];
  bool _isLoading = true;
  String _error = '';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
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
      _userId = user['id'];

      final results = await Future.wait([
        NutritionService.getFavorites(_userId!),
        NutritionService.getMealHistory(_userId!),
      ]);
      final favorites = results[0];
      final meals = results[1] as List<MealEntry>;

      setState(() {
        _favorites = favorites;
        _suggestions = suggestFavorites(
          meals,
          favorites.map(favoriteName),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addSuggestion(FavoriteSuggestion suggestion) async {
    try {
      await NutritionService.addFavorite(_userId!, suggestion.food);
      await _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${suggestion.food.name} to favorites')),
        );
      }
    } catch (e) {
      _showError('Could not add favorite: $e');
    }
  }

  Future<void> _removeFavorite(int index) async {
    final name = favoriteName(_favorites[index]);
    try {
      await NutritionService.removeFavorite(_userId!, index);
      await _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed $name from favorites')),
        );
      }
    } catch (e) {
      _showError('Could not remove favorite: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
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
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_suggestions.isNotEmpty) ...[
                        _buildSectionTitle('Suggested for you'),
                        Text(
                          'You eat these often. Save them as favorites?',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ..._suggestions.map(_buildSuggestionCard),
                        const SizedBox(height: 16),
                      ],
                      _buildSectionTitle('Your favorites'),
                      if (_favorites.isEmpty)
                        _buildEmptyState()
                      else
                        ...List.generate(_favorites.length, _buildFavoriteCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart on any food in a dining hall to save it',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(FavoriteSuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.green[50],
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.trending_up, color: Colors.white),
        ),
        title: Text(
          suggestion.food.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Eaten ${suggestion.timesEaten} times in the last 2 weeks'),
        trailing: TextButton.icon(
          onPressed: () => _addSuggestion(suggestion),
          icon: const Icon(Icons.favorite_border),
          label: const Text('Add'),
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(int index) {
    final favorite = _favorites[index];
    String? details;
    if (favorite is Map) {
      final calories = (favorite['calories'] ?? 0).toInt();
      final protein = (favorite['protein'] ?? 0).toInt();
      details = '$calories cal • ${protein}g protein';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.restaurant, color: Colors.white),
        ),
        title: Text(
          favoriteName(favorite),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: details != null ? Text(details) : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: 'Remove from favorites',
          onPressed: () => _removeFavorite(index),
        ),
      ),
    );
  }
}
