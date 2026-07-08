import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_model.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import 'app_providers.dart';

// Rich model representing an AI-generated Recipe alternative
class Recipe {
  final String title;
  final String image;
  final String savings;
  final String kcal;
  final String protein;
  final String carbs;
  final String fat;
  final String desc;
  final String prepTime;
  final String cookTime;
  final List<String> ingredients;
  final List<String> instructions;

  Recipe({
    required this.title,
    required this.image,
    required this.savings,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.desc,
    required this.prepTime,
    required this.cookTime,
    required this.ingredients,
    required this.instructions,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title'] ?? 'Alternative Recipe',
      image: json['image'] ?? 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&q=80&w=600',
      savings: json['savings'] ?? '0 kcal',
      kcal: json['kcal'] ?? '0 kcal',
      protein: json['protein'] ?? '0g',
      carbs: json['carbs'] ?? '0g',
      fat: json['fat'] ?? '0g',
      desc: json['desc'] ?? '',
      prepTime: json['prepTime'] ?? '10 min',
      cookTime: json['cookTime'] ?? '20 min',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
    );
  }
}

// Returns a typed List of Recipe alternatives
final alternativesProvider = StateNotifierProvider<AlternativesNotifier, List<Recipe>>((ref) {
  return AlternativesNotifier(ref);
});

class AlternativesNotifier extends StateNotifier<List<Recipe>> {
  final Ref _ref;

  AlternativesNotifier(this._ref) : super([]);

  Future<void> fetchAlternatives(Meal originalMeal) async {
    _ref.read(aiLoadingProvider.notifier).state = true;
    try {
      state = [];
      final List<Map<String, dynamic>> rawAlternatives = 
          await AiService.generateAlternativeRecipes(originalMeal.name, '${originalMeal.kcal}');

      // Convert dynamic maps straight into the structured Recipe instances
      state = rawAlternatives.map((map) => Recipe.fromJson(map)).toList();
    } catch (e) {
      print('Error getting alternatives: $e');
      state = [];
    } finally {
      _ref.read(aiLoadingProvider.notifier).state = false;
    }
  }

  void clear() {
    state = [];
  }
}

final mealsForDateProvider = FutureProvider.family<List<Meal>, DateTime>((ref, date) {
  return StorageService.getMealsForDate(date);
});