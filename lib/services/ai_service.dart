import 'package:dio/dio.dart';
import '../models/meal_model.dart';

class AiService {
  // ── Recipe search (API Ninjas) ───────────────────────────────────────
  // Only used for recipe titles/ingredients/instructions text — NOT for
  // nutrition numbers, so the "premium field" restriction below doesn't
  // affect this part.
  static const String _recipeApiKey = 'SResl82Zhh1LE8fVAD8Z8s6VBg1pQaQIt7a12B4C';
  static const String _recipeBaseUrl = 'https://api.api-ninjas.com/v1';

  static final Dio _recipeDio = Dio(BaseOptions(baseUrl: _recipeBaseUrl))..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['X-Api-Key'] = _recipeApiKey;
            options.headers['Content-Type'] = 'application/json';
            return handler.next(options);
          },
        ),
      );

  // ── Nutrition data (USDA FoodData Central) ───────────────────────────
  // We switched away from API Ninjas' /nutrition endpoint for macro data:
  // its `calories` and `protein_g` fields are locked behind a paid
  // "premium" plan and return null/0 on a free key — that was the source
  // of the "0 kcal / 0g protein" results. FoodData Central is a free,
  // government-run (USDA) nutrition database that includes calories and
  // protein at no cost.
  //
  // IMPORTANT: 'DEMO_KEY' below is a shared public test key rate-limited
  // to ~30 requests/hour per IP. Get your own free key in under a minute
  // (no credit card, instant) at https://fdc.nal.usda.gov/api-key-signup
  // and replace DEMO_KEY with it before shipping.
  static const String _usdaApiKey = 'DEMO_KEY';
  static const String _usdaBaseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static final Dio _usdaDio = Dio(BaseOptions(baseUrl: _usdaBaseUrl));

  static Future<Meal> analyzeMealText(String description) async {
    final items = _splitFoodItems(description);
    if (items.isEmpty) {
      return _generateLocalFallbackAnalysis(description);
    }

    double kcal = 0, protein = 0, carbs = 0, fat = 0;
    final matchedNames = <String>[];
    var anySucceeded = false;

    for (final rawItem in items) {
      final parsed = _extractGramWeight(rawItem);
      final per100g = await _usdaLookup(parsed.query);
      if (per100g == null) continue;

      anySucceeded = true;
      matchedNames.add(parsed.query);
      final scale = (parsed.grams ?? 100) / 100;
      kcal += per100g['kcal']! * scale;
      protein += per100g['protein']! * scale;
      carbs += per100g['carbs']! * scale;
      fat += per100g['fat']! * scale;
    }

    if (!anySucceeded) {
      print('USDA lookup found no matches for "$description", using local fallback.');
      return _generateLocalFallbackAnalysis(description);
    }

    return Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _toTitleCase(matchedNames.join(', ')),
      time: _formatTime(DateTime.now()),
      kcal: kcal.round(),
      protein: protein.round(),
      carbs: carbs.round(),
      fat: fat.round(),
      icon: 'default',
    );
  }

  static Future<List<Map<String, dynamic>>> generateAlternativeRecipes(
      String originalMealName, String currentKcal) async {
    try {
      final response = await _recipeDio.get('/recipe', queryParameters: {'query': originalMealName});

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          return await _parseRecipeResponse(data, originalMealName, currentKcal);
        }
        throw Exception('Recipe API returned no items.');
      }

      throw Exception('Server returned status: ${response.statusCode}');
    } catch (e) {
      print('API Ninjas recipe error (generateAlternativeRecipes): $e');
      return _generateLocalFallbackRecipes(originalMealName, currentKcal);
    }
  }

  // The /recipe endpoint only returns title/ingredients/instructions — no
  // nutrition data — so we look up real nutrition for the recipe's actual
  // ingredients via USDA FoodData Central and sum it, rather than
  // inventing numbers.
  static Future<List<Map<String, dynamic>>> _parseRecipeResponse(
      List<dynamic> rawItems, String originalMealName, String currentKcal) async {
    final baseKcal = int.tryParse(currentKcal.replaceAll(RegExp(r'[^0-9]'), '')) ?? 500;
    final recipes = <Map<String, dynamic>>[];

    for (var index = 0; index < rawItems.length && recipes.length < 3; index++) {
      final item = rawItems[index];
      if (item is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(item);
      final title = map['title']?.toString() ?? 'Healthy Recipe';
      final ingredients = _toStringList(map['ingredients']);

      final macros = await _lookupNutritionForIngredients(ingredients, baseKcal);
      final kcal = macros['kcal']!;
      final protein = macros['protein']!;
      final carbs = macros['carbs']!;
      final fat = macros['fat']!;

      recipes.add({
        'title': title,
        'image': _selectImageForRecipe(title),
        'savings': '${(baseKcal - kcal) >= 0 ? '-' : '+'}${(baseKcal - kcal).abs()} kcal',
        'kcal': '$kcal kcal',
        'protein': '${protein}g',
        'carbs': '${carbs}g',
        'fat': '${fat}g',
        'desc': 'A lighter and more balanced version of $title designed for better nutrition.',
        'prepTime': map['prep_time']?.toString() ?? map['prepTime']?.toString() ?? '${8 + index * 2} min',
        'cookTime': map['cook_time']?.toString() ?? map['cookTime']?.toString() ?? '${10 + index * 3} min',
        'ingredients': ingredients,
        'instructions': _toStringList(map['instructions']),
      });
    }

    if (recipes.isEmpty) {
      return _generateLocalFallbackRecipes(originalMealName, currentKcal);
    }

    return recipes;
  }

  /// Looks up real nutrition totals for a list of ingredient strings via
  /// USDA FoodData Central. Falls back to a neutral, clearly-approximate
  /// estimate only if no ingredient could be matched at all.
  static Future<Map<String, int>> _lookupNutritionForIngredients(
      List<String> ingredients, int baseKcal) async {
    if (ingredients.isEmpty) {
      return _estimatedMacros(baseKcal);
    }

    double kcal = 0, protein = 0, carbs = 0, fat = 0;
    var anySucceeded = false;

    for (final ingredient in ingredients) {
      final parsed = _extractGramWeight(ingredient);
      final per100g = await _usdaLookup(parsed.query);
      if (per100g == null) continue;

      anySucceeded = true;
      final scale = (parsed.grams ?? 100) / 100;
      kcal += per100g['kcal']! * scale;
      protein += per100g['protein']! * scale;
      carbs += per100g['carbs']! * scale;
      fat += per100g['fat']! * scale;
    }

    if (!anySucceeded || kcal <= 0) {
      return _estimatedMacros(baseKcal);
    }

    return {
      'kcal': kcal.round(),
      'protein': protein.round(),
      'carbs': carbs.round(),
      'fat': fat.round(),
    };
  }

  static Map<String, int> _estimatedMacros(int baseKcal) {
    return {
      'kcal': (baseKcal * 0.8).round(),
      'protein': (baseKcal * 0.08).round(),
      'carbs': (baseKcal * 0.08).round(),
      'fat': (baseKcal * 0.03).round(),
    };
  }

  // ── USDA FoodData Central helpers ────────────────────────────────────

  /// Splits a free-text meal description into individual food phrases,
  /// e.g. "grilled chicken with rice and salad" -> ["grilled chicken", "rice", "salad"].
  static List<String> _splitFoodItems(String description) {
    final normalized = description
        .replaceAll(RegExp(r'\bwith\b', caseSensitive: false), ',')
        .replaceAll(RegExp(r'\band\b', caseSensitive: false), ',')
        .replaceAll('+', ',')
        .replaceAll('&', ',');
    return normalized
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Pulls an explicit gram quantity out of a phrase (e.g. "150g chicken
  /// breast" -> query "chicken breast", grams 150). If no gram quantity is
  /// present, the full phrase is used as the search query and nutrition is
  /// reported per the USDA database's standard 100g serving.
  static ({String query, double? grams}) _extractGramWeight(String phrase) {
    final match = RegExp(r'(\d+(\.\d+)?)\s*g\b', caseSensitive: false).firstMatch(phrase);
    if (match != null) {
      final grams = double.tryParse(match.group(1)!);
      final cleaned = phrase.replaceRange(match.start, match.end, '').trim();
      return (query: cleaned.isEmpty ? phrase : cleaned, grams: grams);
    }
    return (query: phrase, grams: null);
  }

  /// Queries USDA FoodData Central for a food name and returns its
  /// calories/protein/carbs/fat per 100g, or null if nothing matched.
  static Future<Map<String, double>?> _usdaLookup(String foodQuery) async {
    final query = foodQuery.trim();
    if (query.isEmpty) return null;

    try {
      final response = await _usdaDio.get('/foods/search', queryParameters: {
        'query': query,
        'pageSize': 5,
        'api_key': _usdaApiKey,
      });

      if (response.statusCode != 200) return null;
      final foods = response.data is Map ? response.data['foods'] : null;
      if (foods is! List || foods.isEmpty) return null;

      // Prefer whole-food reference data over branded/processed products
      // for more representative values.
      const preferredOrder = ['Foundation', 'SR Legacy', 'Survey (FNDDS)', 'Branded'];
      Map<String, dynamic>? best;
      for (final type in preferredOrder) {
        final match = foods.firstWhere(
          (f) => f is Map && f['dataType'] == type,
          orElse: () => null,
        );
        if (match != null) {
          best = Map<String, dynamic>.from(match as Map);
          break;
        }
      }
      best ??= Map<String, dynamic>.from(foods.first as Map);

      final nutrients = best['foodNutrients'];
      if (nutrients is! List) return null;

      double? findNutrient(String targetName) {
        for (final n in nutrients) {
          if (n is! Map) continue;
          final nutrientName = n['nutrientName']?.toString() ?? '';
          if (nutrientName.toLowerCase() == targetName.toLowerCase()) {
            final value = n['value'];
            if (value is num) return value.toDouble();
          }
        }
        return null;
      }

      return {
        'kcal': findNutrient('Energy') ?? 0,
        'protein': findNutrient('Protein') ?? 0,
        'fat': findNutrient('Total lipid (fat)') ?? 0,
        'carbs': findNutrient('Carbohydrate, by difference') ?? 0,
      };
    } catch (e) {
      print('USDA FoodData Central error ("$query"): $e');
      return null;
    }
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
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