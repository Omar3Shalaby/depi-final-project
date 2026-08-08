import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_model.dart';

// 1. Bottom Navigation Tab Index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// 2. Holds the original meal currently selected for analysis / alternatives
final analyzedMealProvider = StateProvider<Meal?>((ref) => null);

// 3. Tracks whether the DeepSeek API is actively loading
final aiLoadingProvider = StateProvider<bool>((ref) => false);