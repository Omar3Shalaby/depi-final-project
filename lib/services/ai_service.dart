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

  // Local fallback generator for recipe alternatives
  static List<Map<String, dynamic>> _generateLocalFallbackRecipes(
      String originalName, String kcalStr) {
    return [
      {
        'title': 'Lemon Herb Chicken with Quinoa & Steamed Vegetables',
        'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&q=80&w=600',
        'savings': '-130 kcal',
        'kcal': '490 kcal',
        'protein': '38g',
        'carbs': '42g',
        'fat': '12g',
        'desc': 'A lighter version of your meal swapping heavy carbs for protein-rich quinoa and fresh broccoli.',
        'prepTime': '10 min',
        'cookTime': '20 min',
        'ingredients': [
          '150g boneless chicken breast',
          '1/2 cup quinoa (dry)',
          '1 cup broccoli florets',
          '1 tbsp fresh lemon juice',
          '1 tsp olive oil',
          'Pinch of oregano, salt, and pepper'
        ],
        'instructions': [
          'Cook quinoa in boiling water for 15 minutes.',
          'Season chicken with lemon juice, oregano, salt, and pepper, and pan-sear in olive oil.',
          'Steam broccoli for 5 minutes until tender-crisp.',
          'Plate everything together and serve warm.'
        ]
      },
      {
        'title': 'Baked Lemon Salmon with Asparagus',
        'image': 'https://images.unsplash.com/photo-1485962398705-ef6a13c41e8f?auto=format&fit=crop&q=80&w=600',
        'savings': '-95 kcal',
        'kcal': '525 kcal',
        'protein': '42g',
        'carbs': '15g',
        'fat': '22g',
        'desc': 'Replaces heavy complex carbs with lean omega-3 rich salmon and fiber-loaded asparagus spears.',
        'prepTime': '10 min',
        'cookTime': '15 min',
        'ingredients': [
          '150g fresh salmon fillet',
          '8-10 asparagus spears',
          '1/2 lemon, sliced',
          '1 tbsp dill weed',
          '1 tsp butter or olive oil'
        ],
        'instructions': [
          'Preheat oven to 200°C (400°F).',
          'Place salmon and asparagus on a baking sheet, drizzle with olive oil, salt, and pepper.',
          'Top salmon with lemon slices and dill weed.',
          'Bake for 12-15 minutes until salmon flakes easily.'
        ]
      },
      {
        'title': 'Mediterranean Chickpea Salad Bowl',
        'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=600',
        'savings': '-180 kcal',
        'kcal': '440 kcal',
        'protein': '18g',
        'carbs': '58g',
        'fat': '10g',
        'desc': 'A complete plant-based meal alternative utilizing roasted chickpeas, cucumbers, and light tahini.',
        'prepTime': '12 min',
        'cookTime': '5 min',
        'ingredients': [
          '1 cup canned chickpeas, drained and rinsed',
          '1 cucumber, diced',
          '1/2 cup cherry tomatoes, halved',
          '1 tbsp tahini',
          '1 tbsp lemon juice',
          'Fresh parsley'
        ],
        'instructions': [
          'In a large bowl, mix chickpeas, diced cucumber, and halved cherry tomatoes.',
          'Whisk tahini and lemon juice with 1 tbsp warm water to create dressing.',
          'Drizzle dressing over salad and garnish with fresh parsley.'
        ]
      }
    ];
  }
}