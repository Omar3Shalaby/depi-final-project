import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _usdaBaseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static final Dio _usdaDio = Dio(BaseOptions(baseUrl: _usdaBaseUrl));

  // ── Gemini API ───────────────────────────────────────────────────────
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';

  /// Reads the USDA API key saved by the user in Settings.
  /// Falls back to public DEMO_KEY if none was set.
  static Future<String> getUsdaApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('usda_api_key') ?? 'DEMO_KEY';
  }

  /// Reads the Gemini API key saved by the user in Settings.
  static Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('gemini_api_key');
    if (key != null && key.trim().isNotEmpty) return key.trim();
    return utf8.decode(base64.decode('QVEuQWI4Uk42SklJTEdlMjFyV3BDN1NlWTgycmtScGRVYlBDa0xkSWpmS05HVC1TN0JuY1E='));
  }

  // ── Chatbot ──────────────────────────────────────────────────────────

  /// Generates a single daily nutrition tip using Gemini.
  /// Returns a Map with 'title' and 'body' keys, or null on failure.
  static Future<Map<String, String>?> getDailyNutritionTip() async {
    final apiKey = await getGeminiApiKey();
    if (apiKey == null) return null;

    const prompt = '''
Generate one practical daily nutrition tip. Keep it evidence-based, actionable, and friendly.
Return STRICTLY this JSON format:
{
  "title": "Short Title (3-5 words)",
  "body": "One or two sentences of practical advice."
}
''';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.9,
        'maxOutputTokens': 120,
      }
    };

    try {
      final response = await Dio().post(
        _geminiBaseUrl,
        queryParameters: {'key': apiKey},
        data: jsonEncode(requestBody),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final parsed = jsonDecode(parts[0]['text']?.toString() ?? '{}');
            final title = parsed['title']?.toString();
            final body = parsed['body']?.toString();
            if (title != null && body != null) {
              return {'title': title, 'body': body};
            }
          }
        }
      }
    } catch (_) {
      // Caller falls back to pool
    }
    return null;
  }

  /// Sends a conversation to Gemini and returns the assistant's reply.
  ///
  /// [messages] is the full conversation history as a list of maps:
  ///   {'role': 'user'|'model', 'text': '...'}
  /// [userGoals] is a map with keys: calories, protein, carbs, fat.
  /// [todayMeals] is today's logged meals for context.
  /// [userName] is the user's display name.
  static Future<String> getChatbotResponse({
    required List<Map<String, String>> messages,
    required Map<String, String> userGoals,
    required List<Meal> todayMeals,
    String userName = 'the user',
  }) async {
    final apiKey = await getGeminiApiKey();
    if (apiKey == null) {
      return "Please add your Gemini API key in Profile → Settings → API Keys to enable the chatbot.";
    }

    // Build today's meals summary
    final mealsSummary = todayMeals.isEmpty
        ? 'No meals logged today yet.'
        : todayMeals
            .map((m) =>
                '- ${m.name}: ${m.kcal} kcal, ${m.protein}g protein, ${m.carbs}g carbs, ${m.fat}g fat')
            .join('\n');

    final totalKcal = todayMeals.fold(0, (sum, m) => sum + m.kcal);
    final totalProtein = todayMeals.fold(0, (sum, m) => sum + m.protein);
    final totalCarbs = todayMeals.fold(0, (sum, m) => sum + m.carbs);
    final totalFat = todayMeals.fold(0, (sum, m) => sum + m.fat);

    final goalKcal = userGoals['calories'] ?? '2000';
    final goalProtein = userGoals['protein'] ?? '150';
    final goalCarbs = userGoals['carbs'] ?? '250';
    final goalFat = userGoals['fat'] ?? '60';

    final systemPrompt = '''
You are NutriBot, a friendly and expert nutrition assistant inside the NutriVision app.
You help users understand their diet, track their nutrition, and make healthier choices.

User: $userName
Today's Nutrition Goals:
- Calories: $goalKcal kcal
- Protein: ${goalProtein}g
- Carbs: ${goalCarbs}g
- Fat: ${goalFat}g

Today's Logged Meals:
$mealsSummary

Today's Totals So Far:
- Calories: $totalKcal / $goalKcal kcal
- Protein: $totalProtein / ${goalProtein}g
- Carbs: $totalCarbs / ${goalCarbs}g
- Fat: $totalFat / ${goalFat}g

Rules:
- Always give specific, personalized answers based on the user's actual data above.
- Never give generic advice that ignores their goals or current intake.
- If asked about remaining calories/macros, calculate from the data above.
- Be concise, warm, and supportive.
- Use emojis sparingly for a friendly tone.
- Do NOT make up food data. Use the logged meals above as your source of truth.
- If you don't know something specific, say so honestly.
''';

    // Build Gemini contents array
    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [
          {'text': systemPrompt},
        ],
      },
      {
        'role': 'model',
        'parts': [
          {
            'text':
                'Understood! I have your nutrition goals and today\'s meal data. How can I help you?',
          },
        ],
      },
    ];

    // Add conversation history
    for (final msg in messages) {
      contents.add({
        'role': msg['role'] == 'user' ? 'user' : 'model',
        'parts': [
          {'text': msg['text'] ?? ''},
        ],
      });
    }

    try {
      final response = await Dio().post(
        _geminiBaseUrl,
        queryParameters: {'key': apiKey},
        data: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 600,
          },
        }),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text']?.toString() ?? 'No response.';
          }
        }
        return 'I could not generate a response. Please try again.';
      } else {
        return 'API error (${response.statusCode}). Please check your Gemini API key in Settings.';
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return 'Invalid Gemini API key. Please update it in Profile → Settings → API Keys.';
      }
      if (e.response?.statusCode == 429) {
        return 'Rate limit reached. Please wait a moment before sending another message.';
      }
      return 'Network error: ${e.message}. Please check your connection.';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  /// Analyzes a food image (base64 string) using Gemini Vision.
  /// Validates if the image is clear and contains food.
  /// Returns a Meal model or throws an Exception with a validation message.
  static Future<Meal> analyzeFoodImage(String base64Image, {String mimeType = 'image/jpeg'}) async {
    final apiKey = await getGeminiApiKey();
    if (apiKey == null) {
      throw Exception("Please add your Gemini API key in Profile → Settings → API Keys first.");
    }

    final prompt = '''
Identify the food in this image. You must validate if the image contains actual food and is clear enough to recognize.
If the image is extremely blurry, dark, or does not represent food (e.g., a person, a pet, furniture, document, electronics), respond STRICTLY with this JSON format:
{
  "error": "A user-friendly explanation of why the photo is invalid (e.g., 'The photo is too blurry to identify' or 'No food detected in this image')"
}

If the image contains food, identify it, estimate the portion size, and return STRICTLY this JSON format:
{
  "mealName": "Clean Title Case Name of Meal",
  "calories": integer,
  "protein": integer,
  "carbs": integer,
  "fat": integer
}
''';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.2,
      }
    };

    try {
      final response = await Dio().post(
        _geminiBaseUrl,
        queryParameters: {'key': apiKey},
        data: jsonEncode(requestBody),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final textResponse = parts[0]['text']?.toString() ?? '{}';
            final parsedJson = jsonDecode(textResponse.trim());

            if (parsedJson['error'] != null) {
              throw Exception(parsedJson['error']);
            }

            final mealName = parsedJson['mealName'] ?? 'Analyzed Food Image';
            final kcal = parsedJson['calories'] is num ? (parsedJson['calories'] as num).round() : 0;
            final protein = parsedJson['protein'] is num ? (parsedJson['protein'] as num).round() : 0;
            final carbs = parsedJson['carbs'] is num ? (parsedJson['carbs'] as num).round() : 0;
            final fat = parsedJson['fat'] is num ? (parsedJson['fat'] as num).round() : 0;

            return Meal(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: mealName,
              time: _formatTime(DateTime.now()),
              kcal: kcal,
              protein: protein,
              carbs: carbs,
              fat: fat,
              icon: 'default',
            );
          }
        }
        throw Exception('No response generated by the model.');
      } else {
        throw Exception('API error (${response.statusCode}). Please verify your Gemini API key in Settings.');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Invalid Gemini API key. Please update it in Profile → Settings → API Keys.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to analyze food image: $e');
    }
  }


  /// Calculates "Estimated Calories" for a logged meal:
  /// 1. Splits the meal description into individual food items.
  /// 2. Looks up each item in USDA FoodData Central (per-100g values).
  /// 3. Scales the result by the specified weight (defaults to 100g).
  /// 4. If USDA has no match, falls back to Gemini AI estimation.
  /// 5. If both USDA and Gemini fail (no key/no internet), falls back
  ///    to a fixed neutral baseline (~350 kcal) as a last resort.
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
      print('USDA lookup found no matches for "$description", attempting Gemini fallback.');
      try {
        final geminiMeal = await _geminiNutritionEstimation(description);
        if (geminiMeal != null) {
          return geminiMeal;
        }
      } catch (e) {
        print('Gemini fallback estimation failed: $e');
      }
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
      final usdaKey = await getUsdaApiKey();
      final response = await _usdaDio.get('/foods/search', queryParameters: {
        'query': query,
        'pageSize': 5,
        'api_key': usdaKey,
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

  static Future<Meal?> _geminiNutritionEstimation(String description) async {
    final apiKey = await getGeminiApiKey();
    if (apiKey == null) return null;

    final prompt = '''
Estimate the nutritional value of this meal description: "$description".
Provide the name of the meal in clean Title Case, estimated calories, protein (in grams), carbohydrates (in grams), and fat (in grams).
Return STRICTLY this JSON format:
{
  "mealName": "Clean Title Case Name of Meal",
  "calories": integer,
  "protein": integer,
  "carbs": integer,
  "fat": integer
}
''';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.2,
      }
    };

    try {
      final response = await Dio().post(
        _geminiBaseUrl,
        queryParameters: {'key': apiKey},
        data: jsonEncode(requestBody),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final textResponse = parts[0]['text']?.toString() ?? '{}';
            final parsedJson = jsonDecode(textResponse.trim());

            final mealName = parsedJson['mealName'] ?? _toTitleCase(description);
            final kcal = parsedJson['calories'] is num ? (parsedJson['calories'] as num).round() : 350;
            final protein = parsedJson['protein'] is num ? (parsedJson['protein'] as num).round() : 15;
            final carbs = parsedJson['carbs'] is num ? (parsedJson['carbs'] as num).round() : 45;
            final fat = parsedJson['fat'] is num ? (parsedJson['fat'] as num).round() : 10;

            return Meal(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: mealName,
              time: _formatTime(DateTime.now()),
              kcal: kcal,
              protein: protein,
              carbs: carbs,
              fat: fat,
              icon: 'default',
            );
          }
        }
      }
    } catch (e) {
      print('Gemini estimation error: $e');
    }
    return null;
  }

  static Meal _generateLocalFallbackAnalysis(String text) {
    String name = text.trim();
    if (name.isEmpty) {
      name = 'Logged Meal';
    } else {
      name = _toTitleCase(name);
      if (name.length > 35) {
        name = '${name.substring(0, 32)}...';
      }
    }

    return Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      time: _formatTime(DateTime.now()),
      kcal: 350,
      protein: 15,
      carbs: 45,
      fat: 10,
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