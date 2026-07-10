import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_vision/models/meal_model.dart';
import 'package:nutri_vision/services/ai_service.dart';

void main() {
  group('AiService', () {
    test('parseNutritionResponse creates a Meal from API Ninjas nutrition data', () {
      final meal = AiService.parseNutritionResponse(
        [
          {
            'name': 'grilled chicken breast',
            'calories': 280.0,
            'protein_g': 53.0,
            'carbohydrates_total_g': 0.0,
            'fat_total_g': 6.0,
          }
        ],
        'grilled chicken breast',
      );

      expect(meal, isA<Meal>());
      expect(meal.name, 'Grilled Chicken Breast');
      expect(meal.kcal, 280);
      expect(meal.protein, 53);
      expect(meal.carbs, 0);
      expect(meal.fat, 6);
    });

    test('parseRecipeResponse builds UI-ready recipe alternatives', () {
      final recipes = AiService.parseRecipeResponse(
        [
          {
            'title': 'Chicken Salad Bowl',
            'ingredients': ['1 chicken breast', '2 cups lettuce'],
            'instructions': ['Mix and serve.'],
            'servings': 2,
          }
        ],
        'grilled chicken',
        '620',
      );

      expect(recipes, isA<List>());
      expect(recipes, hasLength(1));
      expect(recipes.first['title'], 'Chicken Salad Bowl');
      expect(recipes.first['ingredients'], isA<List>());
      expect(recipes.first['instructions'], isA<List>());
      expect(recipes.first['kcal'], contains('kcal'));
    });

    test('parseNutritionResponse estimates values when API returns premium-only placeholders', () {
      final meal = AiService.parseNutritionResponse(
        [
          {
            'name': 'apple',
            'calories': 'Only available for premium subscribers.',
            'protein_g': 'Only available for premium subscribers.',
            'carbohydrates_total_g': 25.6,
            'fat_total_g': 0.3,
          }
        ],
        'apple',
      );

      expect(meal.kcal, greaterThan(0));
      expect(meal.protein, greaterThan(0));
    });
  });
}
