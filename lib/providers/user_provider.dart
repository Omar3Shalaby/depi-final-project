import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userGoalKcalProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return int.tryParse(prefs.getString('Calories') ?? '2000') ?? 2000;
});

final userDisplayNameProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('name') ?? 'User';
});

final userMacroGoalsProvider = FutureProvider<Map<String, double>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'protein': double.tryParse(prefs.getString('Protein') ?? '150') ?? 150,
    'carbs': double.tryParse(prefs.getString('Carbs') ?? '250') ?? 250,
    'fat': double.tryParse(prefs.getString('Fat') ?? '60') ?? 60,
  };
});
