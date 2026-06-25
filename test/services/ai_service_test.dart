
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_vision/services/ai_service.dart';
import 'package:nutri_vision/models/meal_model.dart';

void main() {
  group('AiService', () {
    test('analyzeMealText returns a Meal object with estimated nutrition', () async {
      final mealDescription = 'A large chicken salad with avocado and vinaigrette dressing.';
      final meal = await AiService.analyzeMealText(mealDescription);

      expect(meal, isA<Meal>());
      expect(meal.name, isNotEmpty);
      expect(meal.kcal, isNotNull);
      expect(meal.protein, isNotNull);
      expect(meal.carbs, isNotNull);
      expect(meal.fat, isNotNull);

      // Since AI responses can vary, we'll check for reasonable ranges
      expect(meal.kcal, greaterThan(100));
      expect(meal.protein, greaterThan(5));
    });

    test('generateAlternativeRecipes returns a list of alternative recipes', () async {
      final originalMealName = 'Cheeseburger and Fries';
      final currentKcal = '800';
      final recipes = await AiService.generateAlternativeRecipes(originalMealName, currentKcal);

      expect(recipes, isA<List>());
      expect(recipes.isNotEmpty, true);

      final firstRecipe = recipes.first;
      expect(firstRecipe, containsPair('title', isNotEmpty));
      expect(firstRecipe, containsPair('image', anyOf(startsWith('http'), isNotEmpty)));
      expect(firstRecipe, containsPair('savings', startsWith('-')));
      expect(firstRecipe, containsPair('kcal', endsWith('kcal')));
      expect(firstRecipe, containsPair('protein', endsWith('g')));
      expect(firstRecipe, containsPair('carbs', endsWith('g')));
      expect(firstRecipe, containsPair('fat', endsWith('g')));
      expect(firstRecipe, containsPair('desc', isNotEmpty));
      expect(firstRecipe, containsPair('prepTime', isNotEmpty));
      expect(firstRecipe, containsPair('cookTime', isNotEmpty));
      expect(firstRecipe, containsPair('ingredients', isA<List>()));
      expect(firstRecipe, containsPair('instructions', isA<List>()));
    });
  });
}
