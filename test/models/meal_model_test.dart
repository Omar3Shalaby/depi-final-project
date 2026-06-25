
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_vision/models/meal_model.dart';

void main() {
  group('Meal', () {
    test('Meal.fromJson creates a valid Meal object', () {
      final Map<String, dynamic> json = {
        'id': '123',
        'name': 'Test Meal',
        'time': '10:00 AM',
        'kcal': 500,
        'protein': 30,
        'carbs': 50,
        'fat': 20,
        'icon': 'default',
        'checked': false,
        'date': '2024-01-01',
      };

      final meal = Meal.fromJson(json);

      expect(meal.id, '123');
      expect(meal.name, 'Test Meal');
      expect(meal.time, '10:00 AM');
      expect(meal.kcal, 500);
      expect(meal.protein, 30);
      expect(meal.carbs, 50);
      expect(meal.fat, 20);
      expect(meal.icon, 'default');
      expect(meal.checked, false);
      expect(meal.date, '2024-01-01');
    });

    test('Meal.toJson converts a Meal object to a valid JSON map', () {
      final meal = Meal(
        id: '123',
        name: 'Test Meal',
        time: '10:00 AM',
        kcal: 500,
        protein: 30,
        carbs: 50,
        fat: 20,
        icon: 'default',
        checked: true,
        date: '2024-01-01',
      );

      final json = meal.toJson();

      expect(json['id'], '123');
      expect(json['name'], 'Test Meal');
      expect(json['time'], '10:00 AM');
      expect(json['kcal'], 500);
      expect(json['protein'], 30);
      expect(json['carbs'], 50);
      expect(json['fat'], 20);
      expect(json['icon'], 'default');
      expect(json['checked'], true);
      expect(json['date'], '2024-01-01');
    });
  });
}
