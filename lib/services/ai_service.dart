import 'package:dio/dio.dart';
import '../models/meal_model.dart';

class AiService {
  static const String _apiKey = 'SResl82Zhh1LE8fVAD8Z8s6VBg1pQaQIt7a12B4C';
  static const String _baseUrl = 'https://api.api-ninjas.com/v1';

  static final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl))..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['X-Api-Key'] = _apiKey;
            options.headers['Content-Type'] = 'application/json';
            return handler.next(options);
          },
        ),
      );

  static Future<Meal> analyzeMealText(String description) async {
    try {
      final response = await _dio.get('/nutrition', queryParameters: {'query': description});

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          return parseNutritionResponse(data, description);
        }
        throw Exception('Nutrition API returned no food items.');
      }

      throw Exception('Server returned status: ${response.statusCode} with body: ${response.data}');
    } catch (e) {
      print('API Ninjas nutrition error (analyzeMealText): $e');
      return _generateLocalFallbackAnalysis(description);
    }
  }

  static Meal parseNutritionResponse(List<dynamic> rawItems, String description) {
    final firstItem = rawItems.isNotEmpty ? rawItems.first : null;
    final item = firstItem is Map ? Map<String, dynamic>.from(firstItem) : null;

    final name = item?['name']?.toString() ?? description;
    final kcal = _parseNumericValue(item?['calories'], description, 150);
    final protein = _parseNumericValue(item?['protein_g'], description, 8);
    final carbs = _parseNumericValue(item?['carbohydrates_total_g'] ?? item?['carbohydrates'], description, 20);
    final fat = _parseNumericValue(item?['fat_total_g'] ?? item?['fat'], description, 5);

    return Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _toTitleCase(name),
      time: _formatTime(DateTime.now()),
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      icon: 'default',
    );
  }

  static Future<List<Map<String, dynamic>>> generateAlternativeRecipes(
      String originalMealName, String currentKcal) async {
    try {
      final response = await _dio.get('/recipe', queryParameters: {'query': originalMealName});

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          return parseRecipeResponse(data, originalMealName, currentKcal);
        }
        throw Exception('Recipe API returned no items.');
      }

      throw Exception('Server returned status: ${response.statusCode}');
    } catch (e) {
      print('API Ninjas recipe error (generateAlternativeRecipes): $e');
      return _generateLocalFallbackRecipes(originalMealName, currentKcal);
    }
  }

  static List<Map<String, dynamic>> parseRecipeResponse(
      List<dynamic> rawItems, String originalMealName, String currentKcal) {
    final baseKcal = int.tryParse(currentKcal.replaceAll(RegExp(r'[^0-9]'), '')) ?? 500;
    final recipes = <Map<String, dynamic>>[];

    for (var index = 0; index < rawItems.length && recipes.length < 3; index++) {
      final item = rawItems[index];
      if (item is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(item);
      final title = map['title']?.toString() ?? 'Healthy Recipe';
      final kcal = _deriveKcal(baseKcal, index, title);
      final protein = _deriveMacro(baseKcal, index, 'protein');
      final carbs = _deriveMacro(baseKcal, index, 'carbs');
      final fat = _deriveMacro(baseKcal, index, 'fat');

      recipes.add({
        'title': title,
        'image': _selectImageForRecipe(title),
        'savings': '-${(baseKcal - kcal).toString()} kcal',
        'kcal': '$kcal kcal',
        'protein': '${protein}g',
        'carbs': '${carbs}g',
        'fat': '${fat}g',
        'desc': 'A lighter and more balanced version of $title designed for better nutrition.',
        'prepTime': map['prep_time']?.toString() ?? map['prepTime']?.toString() ?? '${8 + index * 2} min',
        'cookTime': map['cook_time']?.toString() ?? map['cookTime']?.toString() ?? '${10 + index * 3} min',
        'ingredients': _toStringList(map['ingredients']),
        'instructions': _toStringList(map['instructions']),
      });
    }

    if (recipes.isEmpty) {
      return _generateLocalFallbackRecipes(originalMealName, currentKcal);
    }

    return recipes;
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }

  static int _parseNumericValue(dynamic value, String description, int fallback) {
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), ''));
      if (parsed != null) {
        return parsed.round();
      }
    }

    final cleanedDescription = description.toLowerCase();
    if (cleanedDescription.contains('chicken')) {
      return fallback + 40;
    }
    if (cleanedDescription.contains('salad') || cleanedDescription.contains('vegetable')) {
      return fallback + 20;
    }
    if (cleanedDescription.contains('egg') || cleanedDescription.contains('omelet')) {
      return fallback + 30;
    }
    if (cleanedDescription.contains('fish') || cleanedDescription.contains('salmon') || cleanedDescription.contains('tuna')) {
      return fallback + 35;
    }
    if (cleanedDescription.contains('rice') || cleanedDescription.contains('pasta') || cleanedDescription.contains('bread')) {
      return fallback + 60;
    }
    return fallback;
  }

  static String _toTitleCase(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) {
      return 'Analyzed Meal';
    }

    return cleaned
        .split(' ')
        .map((part) => part.isEmpty ? part : part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  static int _deriveKcal(int baseKcal, int index, String title) {
    final reduction = 60 + (index * 25);
    final derived = baseKcal - reduction;

    if (title.toLowerCase().contains('salad')) {
      return derived < 250 ? 250 : derived;
    }
    if (title.toLowerCase().contains('soup')) {
      return derived < 280 ? 280 : derived;
    }
    return derived < 300 ? 300 : derived;
  }

  static int _deriveMacro(int baseKcal, int index, String type) {
    final base = (baseKcal * 0.08).round();
    switch (type) {
      case 'protein':
        return base + index * 3 + 20;
      case 'carbs':
        return base + index * 2 + 12;
      case 'fat':
        return base + index + 6;
      default:
        return 0;
    }
  }

  static String _selectImageForRecipe(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('salad')) {
      return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=600';
    }
    if (lowerTitle.contains('salmon') || lowerTitle.contains('fish')) {
      return 'https://images.unsplash.com/photo-1485962398705-ef6a13c41e8f?auto=format&fit=crop&q=80&w=600';
    }
    if (lowerTitle.contains('soup')) {
      return 'https://images.unsplash.com/photo-1547592166-23ac2d5f2f4c?auto=format&fit=crop&q=80&w=600';
    }
    if (lowerTitle.contains('tofu') || lowerTitle.contains('stir')) {
      return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=600';
    }
    return 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&q=80&w=600';
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return ['Prepare the ingredients.', 'Cook until done and serve warm.'];
  }

  static Meal _generateLocalFallbackAnalysis(String text) {
    final String cleanText = text.toLowerCase();
    int kcal = 500;
    int protein = 25;
    int carbs = 60;
    int fat = 15;
    String name = 'Logged Meal';

    if (cleanText.contains('chicken') || cleanText.contains('poultry')) {
      name = 'Chicken Meal';
      kcal = 550;
      protein = 35;
      carbs = 40;
      fat = 12;
    } else if (cleanText.contains('egg') || cleanText.contains('omelet')) {
      name = 'Egg Meal';
      kcal = 320;
      protein = 18;
      carbs = 15;
      fat = 20;
    } else if (cleanText.contains('salmon') || cleanText.contains('fish') || cleanText.contains('tuna')) {
      name = 'Fish Meal';
      kcal = 480;
      protein = 30;
      carbs = 20;
      fat = 18;
    } else if (cleanText.contains('salad') || cleanText.contains('vegetable') || cleanText.contains('veggie')) {
      name = 'Salad Bowl';
      kcal = 280;
      protein = 8;
      carbs = 25;
      fat = 14;
    } else if (cleanText.contains('rice') || cleanText.contains('pasta') || cleanText.contains('bread')) {
      name = 'Carb-Rich Meal';
      kcal = 600;
      protein = 15;
      carbs = 90;
      fat = 10;
    }

    if (text.length > 3) {
      name = text[0].toUpperCase() + text.substring(1);
      if (name.length > 35) {
        name = '${name.substring(0, 32)}...';
      }
    }

    return Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      time: _formatTime(DateTime.now()),
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      icon: 'default',
    );
  }

  static List<Map<String, dynamic>> _generateLocalFallbackRecipes(
      String originalName, String kcalStr) {
    final lowerName = originalName.toLowerCase();
    final baseKcal = int.tryParse(kcalStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 500;

    final List<Map<String, dynamic>> pool = [];

    if (lowerName.contains('chicken') || lowerName.contains('poultry') || lowerName.contains('grilled')) {
      pool.addAll([
        {
          'title': 'Herb-Crusted Chicken with Roasted Vegetables',
          'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&q=80&w=600',
          'savings': '-${(baseKcal * 0.2).round()} kcal',
          'kcal': '${(baseKcal * 0.8).round()} kcal',
          'protein': '${(baseKcal * 0.12).round()}g',
          'carbs': '${(baseKcal * 0.06).round()}g',
          'fat': '${(baseKcal * 0.02).round()}g',
          'desc': 'A lighter herb-crusted chicken breast paired with colorful roasted vegetables for a balanced meal.',
          'prepTime': '10 min',
          'cookTime': '25 min',
          'ingredients': ['150g chicken breast', '1 cup mixed bell peppers', '1 cup zucchini, sliced', '1 tbsp olive oil', '1 tsp dried rosemary', '1 tsp garlic powder', 'Salt and pepper to taste'],
          'instructions': ['Preheat oven to 200°C (400°F).', 'Season chicken with rosemary, garlic powder, salt, and pepper.', 'Toss vegetables with olive oil and spread on a baking sheet alongside chicken.', 'Bake for 20-25 minutes until chicken is cooked through.']
        },
        {
          'title': 'Chicken Lettuce Wraps with Ginger Sauce',
          'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=600',
          'savings': '-${(baseKcal * 0.3).round()} kcal',
          'kcal': '${(baseKcal * 0.7).round()} kcal',
          'protein': '${(baseKcal * 0.1).round()}g',
          'carbs': '${(baseKcal * 0.04).round()}g',
          'fat': '${(baseKcal * 0.02).round()}g',
          'desc': 'Light and fresh chicken lettuce wraps with a tangy ginger-soy dipping sauce.',
          'prepTime': '15 min',
          'cookTime': '10 min',
          'ingredients': ['150g ground chicken', '4 large lettuce leaves', '1 tbsp soy sauce', '1 tsp fresh ginger, minced', '1 carrot, shredded', '2 green onions, sliced'],
          'instructions': ['Cook ground chicken in a skillet over medium heat until browned.', 'Add soy sauce and ginger, stir for 1 minute.', 'Spoon mixture into lettuce leaves.', 'Top with shredded carrot and green onions.']
        },
      ]);
    }

    if (lowerName.contains('fish') || lowerName.contains('salmon') || lowerName.contains('tuna') || lowerName.contains('seafood')) {
      pool.addAll([
        {
          'title': 'Grilled Salmon with Avocado Salsa',
          'image': 'https://images.unsplash.com/photo-1485962398705-ef6a13c41e8f?auto=format&fit=crop&q=80&w=600',
          'savings': '-${(baseKcal * 0.15).round()} kcal',
          'kcal': '${(baseKcal * 0.85).round()} kcal',
          'protein': '${(baseKcal * 0.11).round()}g',
          'carbs': '${(baseKcal * 0.03).round()}g',
          'fat': '${(baseKcal * 0.04).round()}g',
          'desc': 'Omega-3 rich grilled salmon topped with fresh avocado salsa for a heart-healthy meal.',
          'prepTime': '10 min',
          'cookTime': '12 min',
          'ingredients': ['150g salmon fillet', '1/2 avocado, diced', '1/4 cup cherry tomatoes, halved', '1 tbsp lime juice', '1 tbsp cilantro, chopped', 'Salt and pepper'],
          'instructions': ['Season salmon with salt and pepper.', 'Grill for 5-6 minutes per side.', 'Mix avocado, tomatoes, lime juice, and cilantro.', 'Top grilled salmon with the salsa.']
        },
      ]);
    }

    if (lowerName.contains('rice') || lowerName.contains('pasta') || lowerName.contains('noodle') || lowerName.contains('carb')) {
      pool.addAll([
        {
          'title': 'Cauliflower Rice Stir-Fry Bowl',
          'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=600',
          'savings': '-${(baseKcal * 0.35).round()} kcal',
          'kcal': '${(baseKcal * 0.65).round()} kcal',
          'protein': '${(baseKcal * 0.08).round()}g',
          'carbs': '${(baseKcal * 0.05).round()}g',
          'fat': '${(baseKcal * 0.02).round()}g',
          'desc': 'Swap heavy rice for cauliflower rice to drastically cut calories while keeping the flavors.',
          'prepTime': '10 min',
          'cookTime': '15 min',
          'ingredients': ['2 cups cauliflower rice', '1 cup mixed vegetables', '2 eggs', '1 tbsp soy sauce', '1 tsp sesame oil', '1 green onion, sliced'],
          'instructions': ['Heat sesame oil in a wok over high heat.', 'Scramble eggs and set aside.', 'Stir-fry vegetables for 3 minutes, add cauliflower rice.', 'Add soy sauce and eggs, toss together and serve.']
        },
      ]);
    }

    final List<Map<String, dynamic>> defaults = [
      {
        'title': 'Quinoa Power Bowl with Roasted Vegetables',
        'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=600',
        'savings': '-${(baseKcal * 0.25).round()} kcal',
        'kcal': '${(baseKcal * 0.75).round()} kcal',
        'protein': '${(baseKcal * 0.07).round()}g',
        'carbs': '${(baseKcal * 0.08).round()}g',
        'fat': '${(baseKcal * 0.02).round()}g',
        'desc': 'A nutrient-dense quinoa bowl with roasted seasonal vegetables and a lemon-tahini drizzle.',
        'prepTime': '10 min',
        'cookTime': '20 min',
        'ingredients': ['1/2 cup quinoa (dry)', '1 cup broccoli florets', '1/2 sweet potato, cubed', '1 tbsp olive oil', '1 tbsp tahini', '1 tbsp lemon juice', 'Salt and pepper'],
        'instructions': ['Cook quinoa according to package directions.', 'Roast broccoli and sweet potato at 200°C for 15 minutes.', 'Whisk tahini with lemon juice and 1 tbsp water.', 'Assemble bowl and drizzle with tahini dressing.']
      },
      {
        'title': 'Mediterranean Chickpea Salad Bowl',
        'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=600',
        'savings': '-${(baseKcal * 0.3).round()} kcal',
        'kcal': '${(baseKcal * 0.7).round()} kcal',
        'protein': '${(baseKcal * 0.06).round()}g',
        'carbs': '${(baseKcal * 0.09).round()}g',
        'fat': '${(baseKcal * 0.02).round()}g',
        'desc': 'A complete plant-based meal with roasted chickpeas, cucumbers, and light tahini dressing.',
        'prepTime': '12 min',
        'cookTime': '5 min',
        'ingredients': ['1 cup canned chickpeas, drained', '1 cucumber, diced', '1/2 cup cherry tomatoes, halved', '1 tbsp tahini', '1 tbsp lemon juice', 'Fresh parsley'],
        'instructions': ['Mix chickpeas, diced cucumber, and halved cherry tomatoes in a bowl.', 'Whisk tahini and lemon juice with 1 tbsp warm water for dressing.', 'Drizzle dressing over salad and garnish with fresh parsley.']
      },
      {
        'title': 'Baked Lemon Salmon with Asparagus',
        'image': 'https://images.unsplash.com/photo-1485962398705-ef6a13c41e8f?auto=format&fit=crop&q=80&w=600',
        'savings': '-${(baseKcal * 0.2).round()} kcal',
        'kcal': '${(baseKcal * 0.8).round()} kcal',
        'protein': '${(baseKcal * 0.1).round()}g',
        'carbs': '${(baseKcal * 0.03).round()}g',
        'fat': '${(baseKcal * 0.03).round()}g',
        'desc': 'Lean omega-3 rich salmon baked with lemon and fiber-loaded asparagus spears.',
        'prepTime': '10 min',
        'cookTime': '15 min',
        'ingredients': ['150g fresh salmon fillet', '8-10 asparagus spears', '1/2 lemon, sliced', '1 tbsp dill weed', '1 tsp olive oil'],
        'instructions': ['Preheat oven to 200°C (400°F).', 'Place salmon and asparagus on a baking sheet, drizzle with olive oil.', 'Top salmon with lemon slices and dill weed.', 'Bake for 12-15 minutes until salmon flakes easily.']
      },
    ];

    for (final d in defaults) {
      if (pool.length >= 3) break;
      if (!pool.any((p) => p['title'] == d['title'])) {
        pool.add(d);
      }
    }

    return pool.take(3).toList();
  }
}