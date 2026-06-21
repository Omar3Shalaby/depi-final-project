import 'package:flutter/material.dart';
import 'ai_recipe_detailed.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_shell.dart';



class AiRecipeAlternativeContent extends StatefulWidget {
  const AiRecipeAlternativeContent({super.key});

  @override
  State<AiRecipeAlternativeContent> createState() =>
      _AiRecipeAlternativeContentState();
}

class _AiRecipeAlternativeContentState
    extends State<AiRecipeAlternativeContent> {
  late final PageController _pageController;
  int _currentPage = 0;
  String _goalKcal = '2,000';

  static const Color _primaryGreen = Color(0xFF4A8B5C);
  static const Color _darkButtonGreen = Color(0xFF2C5E3B);
  static const Color _darkTextColor = Color(0xFF2D3748);
  static const Color _lightBgGrey = Color(0xFFF5F7F6);

  final Map<String, dynamic> _originalMeal = {
    'name': 'Grilled chicken with brown rice and salad',
    'kcal': '620',
    'goalKcal': '2,000',
    'protein': '98g',
    'carbs': '150g',
    'fat': '41g',
  };

  final List<Map<String, dynamic>> _alternatives = [
    {
      'title': 'Lemon Herb Chicken with Quinoa & Steamed Vegetables',
      'image':
          'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&q=80&w=600',
      'savings': '-130 kcal',
      'kcal': '490 kcal',
      'protein': '38g',
      'carbs': '42g',
      'fat': '12g',
      'desc':
          'A lighter option with quinoa instead of brown rice, and steamed veggies instead of salad.',
    },
    {
      'title': 'Baked Lemon Salmon with Asparagus',
      'image':
          'https://images.unsplash.com/photo-1485962398705-ef6a13c41e8f?auto=format&fit=crop&q=80&w=600',
      'savings': '-95 kcal',
      'kcal': '525 kcal',
      'protein': '42g',
      'carbs': '15g',
      'fat': '22g',
      'desc':
          'Replaces heavy complex carbs with lean omega-3 rich salmon and fiber-loaded asparagus spears.',
    },
    {
      'title': 'Mediterranean Chickpea & Salad Bowl',
      'image':
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=600',
      'savings': '-180 kcal',
      'kcal': '440 kcal',
      'protein': '18g',
      'carbs': '58g',
      'fat': '10g',
      'desc':
          'A complete plant-based meal alternative utilizing roasted chickpeas, cucumbers, and light tahini.',
    },
    {
      'title': 'Sesame Ginger Tofu Stir-Fry',
      'image':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=600',
      'savings': '-150 kcal',
      'kcal': '470 kcal',
      'protein': '24g',
      'carbs': '30g',
      'fat': '14g',
      'desc':
          'Swap chicken for extra-firm tofu cooked in sesame oil and packed with dark cruciferous greens.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadGoalKcal();
  }

  Future<void> _loadGoalKcal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goalKcal = prefs.getString('Calories') ?? '2,000';
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = MainShellScope.of(context);
    
    // Original meal data
    final Map<String, dynamic> originalMeal = scope?.currentAnalyzedMeal ?? _originalMeal;
    
    // Alternative recipes list
    final List<Map<String, dynamic>> alternatives = 
        scope != null && scope.currentAlternatives.isNotEmpty 
            ? scope.currentAlternatives 
            : _alternatives;

    // Safety checks for active page index
    final int alternativesCount = alternatives.length;
    final int safeCurrentPage = _currentPage.clamp(0, alternativesCount > 0 ? alternativesCount - 1 : 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom:
            110, // Matching HistoryContent's padding to avoid persistent navigation bar overlap
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Section ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
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
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: _primaryGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Alternatives',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _darkTextColor,
                        ),
                      ),
                      Text(
                        scope != null && scope.currentAlternatives.isNotEmpty
                            ? 'Tailored custom alternatives for your meal'
                            : 'Healthier options for your original meal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Original Meal Card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.spa_rounded,
                      color: Color(0xFF8D9963),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        originalMeal['name'] ?? 'Grilled chicken with brown rice and salad',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _darkTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOriginalMacroBadge(
                      label: 'Calories',
                      value: '${originalMeal['kcal'] ?? 620}/${originalMeal['goalKcal'] ?? _goalKcal}',
                      icon: Icons.local_fire_department_rounded,
                      themeColor: const Color(0xFFF2A65A),
                    ),
                    _buildOriginalMacroBadge(
                      label: 'Protein',
                      value: originalMeal['protein'] is int ? '${originalMeal['protein']}g' : (originalMeal['protein'] ?? '98g'),
                      icon: Icons.thumb_up_rounded,
                      themeColor: const Color(0xFF5A92D6),
                    ),
                    _buildOriginalMacroBadge(
                      label: 'Carbs',
                      value: originalMeal['carbs'] is int ? '${originalMeal['carbs']}g' : (originalMeal['carbs'] ?? '150g'),
                      icon: Icons.grain_rounded,
                      themeColor: const Color(0xFF4A8B5C),
                    ),
                    _buildOriginalMacroBadge(
                      label: 'Fat',
                      value: originalMeal['fat'] is int ? '${originalMeal['fat']}g' : (originalMeal['fat'] ?? '41g'),
                      icon: Icons.opacity_rounded,
                      themeColor: const Color(0xFFEF9A9A),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Healthier Alternatives Header ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Healthier Alternatives',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkTextColor,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${alternativesCount > 0 ? safeCurrentPage + 1 : 0} / $alternativesCount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _nextPage,
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: _primaryGreen,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── PageView Slider Card ────────────────────────────────────
          SizedBox(
            height: 380,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: alternativesCount,
              itemBuilder: (context, index) {
                final recipe = alternatives[index];
                return _buildAlternativeCard(recipe);
              },
            ),
          ),
          const SizedBox(height: 12),

          // Indicators Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              alternativesCount,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: safeCurrentPage == index ? 16 : 6,
                decoration: BoxDecoration(
                  color: safeCurrentPage == index
                      ? _primaryGreen
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Banner Tip ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7F2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDFEDE4), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Color(0xFFBCBE7F),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'This recipe is a healthier version of your original meal. Swap for fewer calories and more nutrition!',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF556B5A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    final scope = MainShellScope.of(context);
    final List<Map<String, dynamic>> alternatives = 
        scope != null && scope.currentAlternatives.isNotEmpty 
            ? scope.currentAlternatives 
            : _alternatives;
    
    if (alternatives.isEmpty) return;

    if (_currentPage < alternatives.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildOriginalMacroBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color themeColor,
  }) {
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withOpacity(0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: themeColor, size: 13),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _darkTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeCard(Map<String, dynamic> recipe) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                recipe['image'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: _lightBgGrey,
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B6E4C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    recipe['savings'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        recipe['title'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _darkTextColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF81B88B),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPillMacro(
                      recipe['kcal'],
                      Icons.local_fire_department,
                      const Color(0xFFF2A65A),
                    ),
                    _buildPillMacro(
                      recipe['protein'],
                      Icons.thumb_up,
                      const Color(0xFF5A92D6),
                    ),
                    _buildPillMacro(
                      recipe['carbs'],
                      Icons.grain,
                      const Color(0xFF4A8B5C),
                    ),
                    _buildPillMacro(
                      recipe['fat'],
                      Icons.opacity,
                      const Color(0xFFEF9A9A),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  recipe['desc'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [_primaryGreen, _darkButtonGreen],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AiRecipeDetailsScreen(
                              recipeData:
                                  recipe, // Passes the clicked recipe details dynamically!
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View Recipe',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _lightBgGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 12),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _darkTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
