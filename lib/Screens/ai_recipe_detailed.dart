import 'package:flutter/material.dart';
import 'package:nutri_vision/services/storage_service.dart';


class AiRecipeDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? recipeData;

  const AiRecipeDetailsScreen({
    super.key,
    this.recipeData,
  });

  @override
  State<AiRecipeDetailsScreen> createState() => _AiRecipeDetailsScreenState();
}

class _AiRecipeDetailsScreenState extends State<AiRecipeDetailsScreen> {
  bool _isBookmarked = false;

  static const Color _primaryGreen = Color(0xFF4A8B5C);
  static const Color _darkTextColor = Color(0xFF2D3748);
  static const Color _lightBgGrey = Color(0xFFF5F7F6);

  late final Map<String, dynamic> _recipe;

  // Global static fallbacks to avoid missing key crashes
  static const List<String> _defaultIngredients = [
    '2 boneless, skinless chicken breasts',
    '1 cup cooked quinoa',
    '1 cup broccoli florets',
    '1/2 cup sliced carrots',
    '1/4 cup cherry tomatoes',
    '1 tbsp olive oil',
    '2 tbsp lemon juice',
    '1 tsp Italian seasoning',
    'Salt and pepper to taste',
  ];

  static const List<String> _defaultInstructions = [
    'Season chicken breasts with Italian seasoning, salt, and pepper.',
    'Heat olive oil in a pan over medium heat and cook chicken for 5-6 minutes per side until fully cooked.',
    'Steam the broccoli, carrots, and cherry tomatoes until tender.',
    'Serve the chicken over a warm bed of cooked quinoa alongside the steamed vegetables. Drizzle with lemon juice.'
  ];

  @override
  void initState() {
    super.initState();
    
    // Safely copy and merge data to prevent missing key errors
    final providedData = widget.recipeData;
    if (providedData != null) {
      _recipe = Map<String, dynamic>.from(providedData);
    } else {
      _recipe = {};
    }

    // Apply default fallbacks for any values that might be missing in the swipeable list
    _recipe['title'] ??= 'Lemon Herb Chicken with Quinoa & Steamed Vegetables';
    _recipe['image'] ??= 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&q=80&w=600';
    _recipe['desc'] ??= 'A healthy and delicious alternative featuring grilled lemon herb chicken, protein-rich quinoa, and a mix of steamed vegetables.';
    _recipe['kcal'] ??= '490 kcal';
    _recipe['protein'] ??= '38g';
    _recipe['carbs'] ??= '50g';
    _recipe['fat'] ??= '12g';
    _recipe['prepTime'] ??= '10 min';
    _recipe['cookTime'] ??= '20 min';
    _recipe['ingredients'] ??= _defaultIngredients;
    _recipe['instructions'] ??= _defaultInstructions;
  }

  @override
  Widget build(BuildContext context) {
    // Safely parse the lists to prevent dynamic list casting errors
    final List<String> ingredients = List<String>.from(_recipe['ingredients']);
    final List<String> instructions = List<String>.from(_recipe['instructions']);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F1EE), Color(0xFFF5F7F6)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // ── Main Scrollable Body ───────────────────────────────
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 64, 
                    bottom: 100, 
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Recipe Image Card
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            _recipe['image'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              color: _lightBgGrey,
                              child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Recipe Title (Centered)
                      Text(
                        _recipe['title'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkTextColor,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Recipe Description (Centered)
                      Text(
                        _recipe['desc'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Summary Metrics Box ─────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildMacroItem(_recipe['kcal'], Icons.local_fire_department_rounded, const Color(0xFFF2A65A)),
                                _buildDivider(),
                                _buildMacroItem(_recipe['protein'], Icons.thumb_up_rounded, const Color(0xFF5A92D6)),
                                _buildDivider(),
                                _buildMacroItem(_recipe['carbs'], Icons.grain_rounded, const Color(0xFF4A8B5C)),
                                _buildDivider(),
                                _buildMacroItem(_recipe['fat'], Icons.opacity_rounded, const Color(0xFFEF9A9A)),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(height: 1, color: Color(0xFFECEFF1)),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.schedule_rounded, size: 16, color: _primaryGreen),
                                const SizedBox(width: 6),
                                Text(
                                  'Prep: ${_recipe['prepTime']}   ·   Cook: ${_recipe['cookTime']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _darkTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Ingredients List Card ──────────────────────
                      _buildSectionCard(
                        headerIcon: Icons.check_box_outlined,
                        headerTitle: 'Ingredients',
                        child: Column(
                          children: ingredients
                              .map((ingredient) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(Icons.check_rounded,
                                              color: _primaryGreen, size: 16),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            ingredient,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _darkTextColor,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Instructions List Card ─────────────────────
                      _buildSectionCard(
                        headerIcon: Icons.unarchive_outlined,
                        headerTitle: 'Instructions',
                        child: Column(
                          children: instructions
                              .asMap()
                              .entries
                              .map((entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${entry.key + 1}. ',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _primaryGreen,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _darkTextColor,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Floating Action Top Bar ────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE8F1EE).withOpacity(0.95),
                        const Color(0xFFE8F1EE).withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: _primaryGreen),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const Text(
                        'Recipe Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkTextColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isBookmarked = !_isBookmarked;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: _primaryGreen,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Floating Bottom Button ─────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF5F7F6).withOpacity(0.0),
                        const Color(0xFFF5F7F6).withOpacity(0.9),
                        const Color(0xFFF5F7F6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: const LinearGradient(
                          colors: [_primaryGreen, Color(0xFF2C5E3B)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                       child: ElevatedButton(
                        onPressed: () async {
                          final Map<String, dynamic> mealData = {
                            'name': _recipe['title'],
                            'kcal': int.tryParse(_recipe['kcal'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 400,
                            'protein': int.tryParse(_recipe['protein'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 30,
                            'carbs': int.tryParse(_recipe['carbs'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 40,
                            'fat': int.tryParse(_recipe['fat'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 10,
                          };
                          await StorageService.saveMeal(DateTime.now(), mealData);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Recipe added to your logged meals!'),
                                backgroundColor: _primaryGreen,
                              ),
                            );
                            // Wait briefly and pop
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted) Navigator.pop(context);
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Add to Meal',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroItem(String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _darkTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Text(
      '|',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData headerIcon,
    required String headerTitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF7F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(headerIcon, color: _primaryGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                headerTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _darkTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}