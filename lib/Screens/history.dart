import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutri_vision/services/storage_service.dart';
import 'package:nutri_vision/models/meal_model.dart';
import 'package:nutri_vision/providers/app_providers.dart';

class HistoryContent extends ConsumerStatefulWidget {
  const HistoryContent({super.key});

  @override
  ConsumerState<HistoryContent> createState() => _HistoryContentState();
}

class _HistoryContentState extends ConsumerState<HistoryContent> {
  DateTime _selectedDate = DateTime.now();
  List<Meal> _meals = [];
  bool _isLoading = true;
  int _goalKcal = 2000;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadData(showSpinner: true);
    
    ref.listenManual<int>(navigationIndexProvider, (previous, next) {
      if (next == 1 && previous != 1) {
        // Silent reload when switching back to this tab (no blocking spinner)
        _loadData(showSpinner: false);
      }
    });
  }

  Future<void> _loadData({required bool showSpinner}) async {
    if (showSpinner || _meals.isEmpty) {
      setState(() => _isLoading = true);
    }

    // Run shared preferences read and database query concurrently
    final results = await Future.wait([
      _prefs != null ? Future.value(_prefs) : SharedPreferences.getInstance(),
      StorageService.getMealsForDate(_selectedDate),
    ]);

    _prefs = results[0] as SharedPreferences?;
    final meals = results[1] as List<Meal>;

    if (mounted) {
      setState(() {
        _meals = meals;
        _goalKcal = int.tryParse(_prefs?.getString('Calories') ?? '2000') ?? 2000;
        _isLoading = false;
      });
    }
  }

  void _changeDay(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
    // Silent load on date transition to keep UI responsive
    _loadData(showSpinner: false);
  }

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diff = selected.difference(today).inDays;

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    final monthName = months[_selectedDate.month - 1];
    final day = _selectedDate.day;

    if (diff == 0) return 'Today, $monthName $day';
    if (diff == -1) return 'Yesterday, $monthName $day';
    if (diff == 1) return 'Tomorrow, $monthName $day';
    return '$monthName $day';
  }

  int get _totalKcal => _meals.fold(0, (sum, m) => sum + m.kcal);
  int get _totalProtein => _meals.fold(0, (sum, m) => sum + m.protein);
  int get _totalCarbs => _meals.fold(0, (sum, m) => sum + m.carbs);
  int get _totalFat => _meals.fold(0, (sum, m) => sum + m.fat);

  Future<void> _deleteMeal(String id) async {
    await StorageService.deleteMeal(_selectedDate, id);
    _loadData(showSpinner: false);
  }

  Future<void> _toggleMealChecked(String id) async {
    await StorageService.toggleMealChecked(_selectedDate, id);
    _loadData(showSpinner: false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF4A8B5C),
      onRefresh: () => _loadData(showSpinner: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 110,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Color(0xFF4A8B5C),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meal History',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          'Track your daily meals',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF4A8B5C),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _loadData(showSpinner: true);
                      }
                    },
                    child: const Icon(
                      Icons.calendar_view_week_rounded,
                      color: Color(0xFF4A8B5C),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Date Navigator ────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _changeDay(-1),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.chevron_left_rounded,
                          color: Color(0xFF4A8B5C), size: 26),
                    ),
                  ),
                  Text(
                    _dateLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3748),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _changeDay(1),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF4A8B5C), size: 26),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Macro Summary Row ─────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMacroStat(
                    label: 'Calories',
                    value: '$_totalKcal / $_goalKcal',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFF2A65A),
                    bg: const Color(0xFFFFF3E0),
                  ),
                  _buildMacroStat(
                    label: 'Protein',
                    value: '${_totalProtein}g',
                    icon: Icons.thumb_up_rounded,
                    iconColor: const Color(0xFF5A92D6),
                    bg: const Color(0xFFE3F2FD),
                  ),
                  _buildMacroStat(
                    label: 'Carbs',
                    value: '${_totalCarbs}g',
                    icon: Icons.grain_rounded,
                    iconColor: const Color(0xFF4A8B5C),
                    bg: const Color(0xFFE8F5E9),
                  ),
                  _buildMacroStat(
                    label: 'Fat',
                    value: '${_totalFat}g',
                    icon: Icons.opacity_rounded,
                    iconColor: const Color(0xFFEF9A9A),
                    bg: const Color(0xFFFFEBEE),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Meals Header ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3748),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ref.read(navigationIndexProvider.notifier).state = 2;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A8B5C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Add Meal',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Meal Cards (dynamic) ───────────────────────────────
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(
                    color: Color(0xFF4A8B5C),
                  ),
                ),
              )
            else if (_meals.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.no_meals_rounded,
                        size: 56,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No meals logged for this day',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Add Meal" to log your first meal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: _meals.length,
                itemBuilder: (context, index) {
                  final meal = _meals[index];
                  return _MealCard(
                    meal: meal,
                    onToggleChecked: () => _toggleMealChecked(meal.id),
                    onDelete: () => _deleteMeal(meal.id),
                  );
                },
              ),
            const SizedBox(height: 20),

            // ── Daily Summary Card ────────────────────────────────
            if (!_isLoading && _meals.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_totalKcal / $_goalKcal kcal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          '${_goalKcal > 0 ? ((_totalKcal / _goalKcal) * 100).toStringAsFixed(0) : 0}%',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _goalKcal > 0
                            ? (_totalKcal / _goalKcal).clamp(0.0, 1.0)
                            : 0.0,
                        minHeight: 10,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4A8B5C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroStat({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bg,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.onToggleChecked,
    required this.onDelete,
  });
  final Meal meal;
  final VoidCallback onToggleChecked;
  final VoidCallback onDelete;

  IconData _resolveIcon(String iconValue) {
    switch (iconValue) {
      case 'egg':
        return Icons.egg_alt_rounded;
      case 'rice':
        return Icons.rice_bowl_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Color _resolveIconColor(String iconValue) {
    switch (iconValue) {
      case 'egg':
        return const Color(0xFFF2A65A);
      case 'rice':
        return const Color(0xFF4A8B5C);
      case 'dinner':
        return const Color(0xFF5A92D6);
      default:
        return const Color(0xFF8B9CB6);
    }
  }

  Color _resolveBgColor(String iconValue) {
    switch (iconValue) {
      case 'egg':
        return const Color(0xFFFFF3E0);
      case 'rice':
        return const Color(0xFFE8F5E9);
      case 'dinner':
        return const Color(0xFFE3F2FD);
      default:
        return const Color(0xFFF0F4F8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isChecked = meal.checked;
    final String iconKey = meal.icon;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _resolveBgColor(iconKey),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _resolveIcon(iconKey),
                color: _resolveIconColor(iconKey),
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  meal.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3748),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meal.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${meal.kcal} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'C ${meal.carbs}g · P ${meal.protein}g · F ${meal.fat}g',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Meal'),
                      content: Text('Remove "${meal.name}" from your log?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onDelete();
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggleChecked,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isChecked
                        ? const Color(0xFF4A8B5C)
                        : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: isChecked ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade400),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}