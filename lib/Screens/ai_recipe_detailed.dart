import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../providers/meal_provider.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class AiRecipeDetailsScreen extends StatefulWidget {
  final Recipe recipe;

  const AiRecipeDetailsScreen({super.key, required this.recipe});

  @override
  State<AiRecipeDetailsScreen> createState() => _AiRecipeDetailsScreenState();
}

class _AiRecipeDetailsScreenState extends State<AiRecipeDetailsScreen> {
  // Set to keep track of checked ingredient items
  final Set<int> _checkedIngredients = {};

  static const Color _primaryGreen = Color(0xFF4A8B5C);
  Color _darkTextColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3748);
  Color _lightBgGrey(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : const Color(0xFFF5F7F6);

  int _parseNumericValue(String val) {
    final match = RegExp(r'\d+').firstMatch(val);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '0') ?? 0;
    }
    return 0;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }

  Future<void> _logAlternativeToHistory() async {
    final now = DateTime.now();
    final newMeal = Meal(
      id: now.millisecondsSinceEpoch.toString(),
      name: widget.recipe.title,
      time: _formatTime(now),
      kcal: _parseNumericValue(widget.recipe.kcal),
      protein: _parseNumericValue(widget.recipe.protein),
      carbs: _parseNumericValue(widget.recipe.carbs),
      fat: _parseNumericValue(widget.recipe.fat),
      icon: 'dinner',
    );

    try {
      await StorageService.saveMeal(now, newMeal);
      // Trigger notification about the meal
      NotificationService.showMealAnalysisNotification(
        newMeal.name,
        newMeal.kcal,
      ).catchError((_) {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _primaryGreen,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '✓ "${widget.recipe.title}" successfully logged in your meals history!',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } on DuplicateMealException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFF2A65A),
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text('This meal has already been logged today.'),
                ),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on MealLimitExceededException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daily limit of 5 meals reached. Delete a meal to add more.',
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to log meal. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Beautiful Sliver Image Header ──
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: _primaryGreen,
            leading: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                r.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _lightBgGrey(context),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.grey,
                    size: 50,
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title and savings badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        r.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _darkTextColor(context),
                        ),
                      ),
                    ),
                    if (r.savings.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C5E3B).withOpacity(0.2) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          r.savings,
                          style: const TextStyle(
                            color: _primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Recipe swap description
                if (r.desc.isNotEmpty)
                  Text(
                    r.desc,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 18),

                // Preparation Time Row
                Row(
                  children: [
                    _buildTimeBadge(
                      'Prep Time',
                      r.prepTime,
                      Icons.access_time_rounded,
                    ),
                    const SizedBox(width: 16),
                    _buildTimeBadge(
                      'Cook Time',
                      r.cookTime,
                      Icons.local_fire_department_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Macros Section
                Text(
                  'Nutritional Content',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _darkTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMacroSquare(
                      'Calories',
                      r.kcal,
                      Theme.of(context).brightness == Brightness.dark ? Colors.orange.shade900.withOpacity(0.2) : const Color(0xFFFFF3E0),
                      const Color(0xFFF2A65A),
                    ),
                    _buildMacroSquare(
                      'Protein',
                      r.protein,
                      Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade900.withOpacity(0.2) : const Color(0xFFE3F2FD),
                      const Color(0xFF5A92D6),
                    ),
                    _buildMacroSquare(
                      'Carbs',
                      r.carbs,
                      Theme.of(context).brightness == Brightness.dark ? Colors.green.shade900.withOpacity(0.2) : const Color(0xFFE8F5E9),
                      _primaryGreen,
                    ),
                    _buildMacroSquare(
                      'Fat',
                      r.fat,
                      Theme.of(context).brightness == Brightness.dark ? Colors.red.shade900.withOpacity(0.2) : const Color(0xFFFFEBEE),
                      const Color(0xFFEF9A9A),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Ingredients checklist Section
                Text(
                  'Ingredients',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _darkTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                if (r.ingredients.isEmpty)
                  const Text('No ingredients listed.')
                else
                  ...List.generate(r.ingredients.length, (idx) {
                    final item = r.ingredients[idx];
                    final isChecked = _checkedIngredients.contains(idx);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isChecked
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: isChecked ? _primaryGreen : Colors.grey.shade400,
                      ),
                      title: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          color: isChecked ? Colors.grey : _darkTextColor(context),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (isChecked) {
                            _checkedIngredients.remove(idx);
                          } else {
                            _checkedIngredients.add(idx);
                          }
                        });
                      },
                    );
                  }),
                const SizedBox(height: 24),

                // Numbered Steps Instructions Section
                Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _darkTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),
                if (r.instructions.isEmpty)
                  const Text('No instructions listed.')
                else
                  ...List.generate(r.instructions.length, (idx) {
                    final step = r.instructions[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C5E3B).withOpacity(0.2) : const Color(0xFFE8F5E9),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: _darkTextColor(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 40),

                // ── Action Button: Log This Meal ──
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 20),
                    label: const Text(
                      'Log This Meal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _logAlternativeToHistory,
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBadge(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _lightBgGrey(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _primaryGreen),
          const SizedBox(width: 6),
          Text(
            '$title: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _darkTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSquare(String label, String value, Color bg, Color color) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
