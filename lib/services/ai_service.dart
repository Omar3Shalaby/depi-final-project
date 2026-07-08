import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/meal_model.dart';

class AiService {
  static const String _apiKey = 'sk-89fe5f3d91164486b1eebf7ae04fa140';
  // Configured Base URL to domain root
  static const String _baseUrl = 'https://api.deepseek.com';

  static final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl))..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Authorization'] = 'Bearer $_apiKey';
            options.headers['Content-Type'] = 'application/json';
            return handler.next(options);
          },
        ),
      );

  // System Prompt for Meal Text Analysis
  static const String _analyzeMealSystemPrompt = '''
You are an expert nutritionist AI. Your task is to analyze the user's description of a meal and estimate its nutritional breakdown.
You must respond with ONLY a JSON object. Do not include markdown code blocks or any text outside of the JSON object.
The JSON object must strictly match the following schema:
{
  "name": "A clean, concise name for the meal (e.g. Grilled Chicken & Brown Rice)",
  "kcal": 620, // Integer: estimated total calories in kcal
  "protein": 42, // Integer: estimated protein in grams
  "carbs": 55, // Integer: estimated carbohydrates in grams
  "fat": 18, // Integer: estimated fat in grams
  "description": "A brief 1-2 sentence nutritional summary of the meal."
}
''';

  // System Prompt for Recipe Alternatives
  static const String _alternativesSystemPrompt = '''
You are an expert chef and dietitian AI.
Given an original meal name and its current calorie count, generate 3-4 healthy alternative recipes that are lower in calories and higher in nutrition.
For each alternative recipe, select a relevant, high-quality food image from Unsplash, or select one of these general Unsplash URLs:
- Healthy Salad: https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=600
- Grilled Salmon: https://images.unsplash.com/photo-1485962398705-ef6a13c41e8f?auto=format&fit=crop&q=80&w=600
- Chicken Quinoa Bowl: https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&q=80&w=600
- Tofu Stir Fry: https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=600
- Avocado Egg Toast: https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&q=80&w=600

You must respond with ONLY a JSON array containing recipe objects. Do not include markdown code blocks or any text outside of the JSON.
The JSON array must strictly match this schema:
[
  {
    "title": "Recipe Title",
    "image": "selected_unsplash_image_url",
    "savings": "-130 kcal", // String: difference in calories (e.g., "-130 kcal")
    "kcal": "490 kcal", // String: new calorie count (e.g., "490 kcal")
    "protein": "38g", // String: grams of protein (e.g., "38g")
    "carbs": "42g", // String: grams of carbs (e.g., "42g")
    "fat": "12g", // String: grams of fat (e.g., "12g")
    "desc": "A brief description of this healthier swap.",
    "prepTime": "10 min",
    "cookTime": "20 min",
    "ingredients": [
      "Ingredient 1 with quantity",
      "Ingredient 2 with quantity",
      "..."
    ],
    "instructions": [
      "Step 1 of instructions.",
      "Step 2 of instructions.",
      "..."
    ]
  }
]
''';

  // 1. Analyze Meal Text
  static Future<Meal> analyzeMealText(String description) async {
    try {
      final response = await _dio.post(
        '/chat/completions', // Set complete endpoint path
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': _analyzeMealSystemPrompt},
            {'role': 'user', 'content': 'Analyze this meal: "$description"'}
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.2,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        final String content = data['choices'][0]['message']['content'];
        final Map<String, dynamic> result = jsonDecode(content);
        return Meal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: result['name'] ?? 'Analyzed Meal',
          time: _formatTime(DateTime.now()),
          kcal: (result['kcal'] ?? 0) is int
              ? result['kcal'] as int
              : int.tryParse(result['kcal'].toString()) ?? 0,
          protein: (result['protein'] ?? 0) is int
              ? result['protein'] as int
              : int.tryParse(result['protein'].toString()) ?? 0,
          carbs: (result['carbs'] ?? 0) is int
              ? result['carbs'] as int
              : int.tryParse(result['carbs'].toString()) ?? 0,
          fat: (result['fat'] ?? 0) is int
              ? result['fat'] as int
              : int.tryParse(result['fat'].toString()) ?? 0,
          icon: 'default',
        );
      } else {
        throw Exception('Server returned status: ${response.statusCode} with body: ${response.data}');
      }
    } catch (e) {
      print('DeepSeek API Error (analyzeMealText): $e');
      return _generateLocalFallbackAnalysis(description);
    }
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }

  // 2. Generate Recipe Alternatives
  static Future<List<Map<String, dynamic>>> generateAlternativeRecipes(
      String originalMealName, String currentKcal) async {
    try {
      final response = await _dio.post(
        '/chat/completions', // Set complete endpoint path
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': _alternativesSystemPrompt},
            {
              'role': 'user',
              'content': 'Generate healthy alternatives for: "$originalMealName" which currently has $currentKcal calories.'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.5,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        final String content = data['choices'][0]['message']['content'];
        
        final parsed = jsonDecode(content);
        if (parsed is List) {
          return parsed.map((item) => Map<String, dynamic>.from(item)).toList();
        } else if (parsed is Map) {
          for (var value in parsed.values) {
            if (value is List) {
              return value.map((item) => Map<String, dynamic>.from(item)).toList();
            }
          }
        }
        throw Exception('Failed to parse alternatives JSON from response: $content');
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('DeepSeek API Error (generateAlternativeRecipes): $e');
      return _generateLocalFallbackRecipes(originalMealName, currentKcal);
    }
  }

  // Local fallback generator for analyzeMealText
  static Meal _generateLocalFallbackAnalysis(String text) {
    final String cleanText = text.toLowerCase();
    int kcal = 500;
    int protein = 25;
    int carbs = 60;
    int fat = 15;
    String name = 'Logged Meal';

    if (cleanText.contains('chicken') || cleanText.contains('poultry')) {
      name = 'Chicken Meal';
      kcal = 550; protein = 35; carbs = 40; fat = 12;
    } else if (cleanText.contains('egg') || cleanText.contains('omelet')) {
      name = 'Egg Meal';
      kcal = 320; protein = 18; carbs = 15; fat = 20;
    } else if (cleanText.contains('salmon') || cleanText.contains('fish') || cleanText.contains('tuna')) {
      name = 'Fish Meal';
      kcal = 480; protein = 30; carbs = 20; fat = 18;
    } else if (cleanText.contains('salad') || cleanText.contains('vegetable') || cleanText.contains('veggie')) {
      name = 'Salad Bowl';
      kcal = 280; protein = 8; carbs = 25; fat = 14;
    } else if (cleanText.contains('rice') || cleanText.contains('pasta') || cleanText.contains('bread')) {
      name = 'Carb-Rich Meal';
      kcal = 600; protein = 15; carbs = 90; fat = 10;
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

  // Local fallback generator for recipe alternatives — dynamically varies based on meal
  static List<Map<String, dynamic>> _generateLocalFallbackRecipes(
      String originalName, String kcalStr) {
    final lowerName = originalName.toLowerCase();
    final baseKcal = int.tryParse(kcalStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 500;

    // Build a pool of contextually relevant recipes
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

    // Default fallback recipes that work for any meal
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

    // Add defaults to fill up to 3 recipes
    for (final d in defaults) {
      if (pool.length >= 3) break;
      // Avoid duplicate titles
      if (!pool.any((p) => p['title'] == d['title'])) {
        pool.add(d);
      }
    }

    return pool.take(3).toList();
  }
}