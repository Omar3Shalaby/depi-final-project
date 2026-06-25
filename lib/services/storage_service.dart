import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_model.dart';

class StorageService {
  static const String _mealsKeyPrefix = 'logged_meals_';

  // Fixed missing $ character in interpolation
  static String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String? _getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Get meals for a specific date (instant local cache + silent Firestore sync)
  static Future<List<Meal>> getMealsForDate(DateTime date) async {
    final dateKey = _formatDateKey(date);
    final localMeals = await _getLocalMeals(dateKey);

    // If we have local meals, return them instantly to make the UI responsive
    if (localMeals.isNotEmpty) {
      _syncWithFirestoreInBackground(dateKey, localMeals);
      return localMeals;
    }

    // Otherwise, fetch from network if local cache is completely empty
    final uid = _getUserId();
    if (uid == null) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(dateKey)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        final firestoreMeals = (snapshot.data()!['items'] as List? ?? [])
            .map((item) => Meal.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        // Save to local cache so the next reload is instant
        final prefs = await SharedPreferences.getInstance();
        final key = '$_mealsKeyPrefix$dateKey';
        await prefs.setString(key, jsonEncode(firestoreMeals.map((m) => m.toJson()).toList()));

        return firestoreMeals;
      }
    } catch (_) {}

    return [];
  }

  // Syncs Firestore updates without blocking the UI rendering thread
  static void _syncWithFirestoreInBackground(String dateKey, List<Meal> localMeals) {
    final uid = _getUserId();
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc(dateKey)
        .get()
        .then((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final firestoreMeals = (snapshot.data()!['items'] as List? ?? [])
            .map((item) => Meal.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        // If local data differs from Cloud Firestore, sync local cache quietly
        if (firestoreMeals.length != localMeals.length) {
          final prefs = await SharedPreferences.getInstance();
          final key = '$_mealsKeyPrefix$dateKey';
          await prefs.setString(key, jsonEncode(firestoreMeals.map((m) => m.toJson()).toList()));
        }
      }
    }).catchError((_) {});
  }

  // Fixed the key interpolation bug
  static Future<List<Meal>> _getLocalMeals(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_mealsKeyPrefix$dateKey';
    final jsonStr = prefs.getString(key);

    if (jsonStr == null) {
      if (dateKey == '2026-04-24') return _getDefaultMockMeals();
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => Meal.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveMeal(DateTime date, Meal meal) async {
    final meals = await getMealsForDate(date);
    final updatedMeal = Meal(
      id: meal.id,
      name: meal.name,
      time: meal.time,
      kcal: meal.kcal,
      protein: meal.protein,
      carbs: meal.carbs,
      fat: meal.fat,
      icon: meal.icon,
      checked: meal.checked,
      date: _formatDateKey(date),
    );
    final existingIndex = meals.indexWhere((m) => m.id == meal.id);
    if (existingIndex >= 0) {
      meals[existingIndex] = updatedMeal;
    } else {
      meals.add(updatedMeal);
    }
    await _saveList(date, meals);
  }

  static Future<void> _saveList(DateTime date, List<Meal> meals) async {
    final dateKey = _formatDateKey(date);
    final prefs = await SharedPreferences.getInstance();
    final key = '$_mealsKeyPrefix$dateKey';
    await prefs.setString(key, jsonEncode(meals.map((m) => m.toJson()).toList()));

    final uid = _getUserId();
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('meals')
            .doc(dateKey)
            .set({
          'date': dateKey,
          'items': meals.map((m) => m.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  static Future<void> deleteMeal(DateTime date, String id) async {
    final meals = await getMealsForDate(date);
    meals.removeWhere((m) => m.id == id);
    await _saveList(date, meals);
  }

  static Future<void> toggleMealChecked(DateTime date, String id) async {
    final meals = await getMealsForDate(date);
    for (var m in meals) {
      if (m.id == id) {
        final index = meals.indexOf(m);
        meals[index] = Meal(
          id: m.id, name: m.name, kcal: m.kcal, protein: m.protein,
          carbs: m.carbs, fat: m.fat, icon: m.icon, time: m.time,
          checked: !m.checked, date: m.date,
        );
        break;
      }
    }
    await _saveList(date, meals);
  }

  static List<Meal> _getDefaultMockMeals() {
    return [
      Meal(id: 'mock_1', name: 'Breakfast', time: '8:30 AM', kcal: 350, protein: 18, carbs: 45, fat: 12, icon: 'egg'),
      Meal(id: 'mock_2', name: 'Lunch', time: '1:15 PM', kcal: 620, protein: 42, carbs: 55, fat: 18, icon: 'rice', checked: true),
    ];
  }
}