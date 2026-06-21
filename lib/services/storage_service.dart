import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _mealsKeyPrefix = 'logged_meals_';

  // Helper to format DateTime to yyyy-MM-dd
  static String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get meals logged on a specific date
  static Future<List<Map<String, dynamic>>> getMealsForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_mealsKeyPrefix${_formatDateKey(date)}';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) {
      // If today and no meals saved yet, we can populate default meals so the user gets initial data,
      // but only if they have never loaded it before.
      // Let's check if there is an initialization flag, or just return empty list.
      // Actually, returning an empty list or some default mock data for the very first launch is good.
      // Let's populate default mocks for the first ever load of date "2026-04-24" (mock data date in code)
      // to keep original screens working until user starts adding new things.
      final hasInitialized = prefs.getBool('initialized_$key') ?? false;
      if (!hasInitialized && _formatDateKey(date) == '2026-04-24') {
        final mockMeals = _getDefaultMockMeals();
        await saveMealsList(date, mockMeals);
        await prefs.setBool('initialized_$key', true);
        return mockMeals;
      }
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // Save multiple meals at once
  static Future<void> saveMealsList(DateTime date, List<Map<String, dynamic>> meals) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_mealsKeyPrefix${_formatDateKey(date)}';
    await prefs.setString(key, jsonEncode(meals));
    await prefs.setBool('initialized_$key', true);
  }

  // Save/Append a single meal
  static Future<void> saveMeal(DateTime date, Map<String, dynamic> meal) async {
    final meals = await getMealsForDate(date);
    
    // Add unique ID if it doesn't exist
    final newMeal = Map<String, dynamic>.from(meal);
    if (newMeal['id'] == null) {
      newMeal['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }
    if (newMeal['checked'] == null) {
      newMeal['checked'] = false;
    }
    if (newMeal['time'] == null) {
      final now = DateTime.now();
      final minute = now.minute.toString().padLeft(2, '0');
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      newMeal['time'] = '$hour:$minute $period';
    }

    // Determine icon based on meal name/type
    if (newMeal['icon'] == null) {
      final nameLower = (newMeal['name'] ?? '').toString().toLowerCase();
      if (nameLower.contains('breakfast') || nameLower.contains('egg')) {
        newMeal['icon'] = 'egg';
      } else if (nameLower.contains('lunch') || nameLower.contains('rice') || nameLower.contains('salad')) {
        newMeal['icon'] = 'rice';
      } else if (nameLower.contains('dinner') || nameLower.contains('steak') || nameLower.contains('soup')) {
        newMeal['icon'] = 'dinner';
      } else {
        newMeal['icon'] = 'default';
      }
    }

    meals.add(newMeal);
    await saveMealsList(date, meals);
  }

  // Delete a logged meal
  static Future<void> deleteMeal(DateTime date, String id) async {
    final meals = await getMealsForDate(date);
    meals.removeWhere((m) => m['id'] == id);
    await saveMealsList(date, meals);
  }

  // Toggle meal checked state
  static Future<void> toggleMealChecked(DateTime date, String id) async {
    final meals = await getMealsForDate(date);
    for (var m in meals) {
      if (m['id'] == id) {
        m['checked'] = !(m['checked'] ?? false);
        break;
      }
    }
    await saveMealsList(date, meals);
  }

  // Default Mock Meals for initial run to preserve original static visual structure
  static List<Map<String, dynamic>> _getDefaultMockMeals() {
    return [
      {
        'id': 'mock_breakfast',
        'name': 'Breakfast',
        'time': '8:30 AM',
        'kcal': 350,
        'carbs': 45,
        'protein': 18,
        'fat': 12,
        'icon': 'egg',
        'checked': false,
      },
      {
        'id': 'mock_lunch',
        'name': 'Lunch (Grilled chicken & brown rice)',
        'time': '1:15 PM',
        'kcal': 620,
        'carbs': 55,
        'protein': 42,
        'fat': 18,
        'icon': 'rice',
        'checked': true,
      },
      {
        'id': 'mock_dinner',
        'name': 'Dinner',
        'time': '7:45 PM',
        'kcal': 350,
        'carbs': 50,
        'protein': 22,
        'fat': 11,
        'icon': 'dinner',
        'checked': false,
      },
    ];
  }
}
