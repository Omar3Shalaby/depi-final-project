import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_model.dart';
import 'ai_recipe_detailed.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/meal_provider.dart';
import '../providers/app_providers.dart';

class AiRecipeAlternativeContent extends ConsumerStatefulWidget {
  const AiRecipeAlternativeContent({super.key});

  @override
  ConsumerState<AiRecipeAlternativeContent> createState() => _AiRecipeAlternativeContentState();
}

class _AiRecipeAlternativeContentState extends ConsumerState<AiRecipeAlternativeContent> {
  late final PageController _pageController;
  int _currentPage = 0;
  String _goalKcal = '2,000';
  SharedPreferences? _prefs;

  static const Color _primaryGreen = Color(0xFF4A8B5C);
  Color _darkTextColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3748);
  Color _lightBgGrey(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : const Color(0xFFF5F7F6);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadGoalKcal();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final originalMeal = ref.read(analyzedMealProvider);
      if (originalMeal != null) {
        ref.read(alternativesProvider.notifier).fetchAlternatives(originalMeal);
      }
    });
  }

  Future<void> _loadGoalKcal() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _goalKcal = _prefs?.getString('Calories') ?? '2,000';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Meal?>(analyzedMealProvider, (previous, next) {
      if (next == null) {
        ref.read(alternativesProvider.notifier).clear();
      }
    });

    final Meal? originalMeal = ref.watch(analyzedMealProvider);
    final bool isAiLoading = ref.watch(aiLoadingProvider);
    final List<Recipe> alternatives = ref.watch(alternativesProvider);

    if (originalMeal == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "No meal selected. Log a meal and tap 'Find alternative' to see AI recipe suggestions here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryGreen,
      onRefresh: () async {
        ref.read(alternativesProvider.notifier).fetchAlternatives(originalMeal);
        await _loadGoalKcal();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Original Meal Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, 
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    originalMeal.name, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkTextColor(context)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMacroBadge('Calories', '${originalMeal.kcal}/$_goalKcal', Icons.local_fire_department_rounded, const Color(0xFFF2A65A)),
                      _buildMacroBadge('Protein', '${originalMeal.protein}g', Icons.thumb_up_rounded, const Color(0xFF5A92D6)),
                      _buildMacroBadge('Carbs', '${originalMeal.carbs}g', Icons.grain_rounded, const Color(0xFF4A8B5C)),
                      _buildMacroBadge('Fat', '${originalMeal.fat}g', Icons.opacity_rounded, const Color(0xFFEF9A9A)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // ── PageView Slider or Loading UI ──
            if (isAiLoading)
              Container(
                height: 300,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: _primaryGreen),
                    const SizedBox(height: 16),
                    Text(
                      'Generating AI alternatives...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _darkTextColor(context),
                      ),
                    ),
                  ],
                ),
              )
            else if (alternatives.isEmpty)
              Container(
                height: 300,
                alignment: Alignment.center,
                child: const Text('No alternatives found. Drag down to refresh.'),
              )
            else
              SizedBox(
                height: 380,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: alternatives.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) => _buildAlternativeCard(alternatives[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeCard(Recipe recipe) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              recipe.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: _lightBgGrey(context),
                child: const Icon(Icons.restaurant, color: Colors.grey, size: 50),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title, 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _darkTextColor(context)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPillMacro(recipe.kcal, Icons.local_fire_department, const Color(0xFFF2A65A)),
                    const SizedBox(width: 8),
                    _buildPillMacro(recipe.protein, Icons.thumb_up, const Color(0xFF5A92D6)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => AiRecipeDetailsScreen(recipe: recipe),
                      ),
                    ),
                    child: const Text('View Recipe'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillMacro(String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _lightBgGrey(context), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _darkTextColor(context))),
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _darkTextColor(context))),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey)),
      ],
    );
  }
}