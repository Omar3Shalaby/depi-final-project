import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_vision/models/meal_model.dart';

void main() {
  group('Meal Model', () {
    test('Meal.fromJson parses numeric values correctly', () {
      final meal = Meal.fromJson({
        'id': 'test_1',
        'name': 'Grilled Chicken',
        'time': '1:00 PM',
        'kcal': 280,
        'protein': 53,
        'carbs': 0,
        'fat': 6,
        'icon': 'default',
        'checked': false,
      });

      expect(meal, isA<Meal>());
      expect(meal.name, 'Grilled Chicken');
      expect(meal.kcal, 280);
      expect(meal.protein, 53);
      expect(meal.carbs, 0);
      expect(meal.fat, 6);
    });

    test('Meal.fromJson handles string-encoded numbers', () {
      final meal = Meal.fromJson({
        'id': 'test_2',
        'name': 'Apple',
        'time': '10:00 AM',
        'kcal': '95',
        'protein': '0',
        'carbs': '25',
        'fat': '0',
        'icon': 'default',
      });

      expect(meal.kcal, 95);
      expect(meal.carbs, 25);
    });

    test('Meal.toJson round-trips correctly', () {
      final original = Meal(
        id: 'test_3',
        name: 'Oatmeal',
        time: '8:00 AM',
        kcal: 150,
        protein: 5,
        carbs: 27,
        fat: 3,
        icon: 'default',
        checked: false,
        date: '2026-07-11',
      );

      final json = original.toJson();
      final restored = Meal.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.kcal, original.kcal);
      expect(restored.protein, original.protein);
      expect(restored.carbs, original.carbs);
      expect(restored.fat, original.fat);
    });
  });
}
