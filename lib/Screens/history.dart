import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutri_vision/services/storage_service.dart';
import 'main_shell.dart';

/// Pure content widget — Scaffold, background & nav bar live in MainShell.
class HistoryContent extends StatefulWidget {
  const HistoryContent({super.key});

  @override
  State<HistoryContent> createState() => _HistoryContentState();
}

class _HistoryContentState extends State<HistoryContent> {
  // The selected date for the navigator (defaults to today)
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _meals = [];
  bool _isLoading = true;
  int _goalKcal = 2000;
  int? _lastIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when the user navigates back to the History tab (index 1)
    final scope = MainShellScope.of(context);
    if (scope != null && scope.currentIndex == 1 && _lastIndex != 1) {
      _loadData();
    }
    _lastIndex = scope?.currentIndex;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final meals = await StorageService.getMealsForDate(_selectedDate);

    setState(() {
      _meals = meals;
      _goalKcal = int.tryParse(prefs.getString('Calories') ?? '2000') ?? 2000;
      _isLoading = false;
    });
  }

  void _changeDay(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
    _loadData();
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

  int get _totalKcal =>
      _meals.fold(0, (sum, m) => sum + (m['kcal'] as num).toInt());
  int get _totalProtein =>
      _meals.fold(0, (sum, m) => sum + (m['protein'] as num).toInt());
  int get _totalCarbs =>
      _meals.fold(0, (sum, m) => sum + (m['carbs'] as num).toInt());
  int get _totalFat =>
      _meals.fold(0, (sum, m) => sum + (m['fat'] as num).toInt());

  Future<void> _deleteMeal(String id) async {
    await StorageService.deleteMeal(_selectedDate, id);
    _loadData();
  }

  Future<void> _toggleMealChecked(String id) async {
    await StorageService.toggleMealChecked(_selectedDate, id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                      Icons.history_rounded,
                      color: Color(0xFF4A8B5C),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meal History',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
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
              // Calendar Icon Button
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
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
                      _loadData();
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
              const Text(
                'Meals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to Log Meal tab
                  MainShellScope.of(context)?.setIndex(2);
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
            ..._meals.map((meal) => _MealCard(
                  meal: meal,
                  onToggleChecked: () =>
                      _toggleMealChecked(meal['id']?.toString() ?? ''),
                  onDelete: () =>
                      _deleteMeal(meal['id']?.toString() ?? ''),
                )),
          const SizedBox(height: 20),

          // ── Daily Summary Card ────────────────────────────────
          if (!_isLoading && _meals.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        '${_goalKcal > 0 ? ((_totalKcal / _goalKcal) * 100).toStringAsFixed(0) : 0}%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _goalKcal > 0
                          ? (_totalKcal / _goalKcal).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade100,
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2D3748),
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

// ── Meal Card ─────────────────────────────────────────────────────────────────
class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.onToggleChecked,
    required this.onDelete,
  });
  final Map<String, dynamic> meal;
  final VoidCallback onToggleChecked;
  final VoidCallback onDelete;

  /// Resolve icon from the stored string key
  IconData _resolveIcon(dynamic iconValue) {
    if (iconValue is String) {
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
    // Fallback for any legacy data that stored IconData directly (not serializable)
    return Icons.restaurant_rounded;
  }

  /// Resolve color palette based on icon type
  Color _resolveIconColor(dynamic iconValue) {
    if (iconValue is String) {
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
    return const Color(0xFF8B9CB6);
  }

  Color _resolveBgColor(dynamic iconValue) {
    if (iconValue is String) {
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
    return const Color(0xFFF0F4F8);
  }

  @override
  Widget build(BuildContext context) {
    final bool isChecked = meal['checked'] == true;
    final iconKey = meal['icon'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Meal Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _resolveBgColor(iconKey),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _resolveIcon(iconKey),
              color: _resolveIconColor(iconKey),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),

          // Meal Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        meal['name'] as String? ?? 'Meal',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF2D3748),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      meal['time'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${meal['kcal']} kcal',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Carbs ${meal['carbs']}g  ·  Protein ${meal['protein']}g  ·  Fat ${meal['fat']}g',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              // Toggle checked
              GestureDetector(
                onTap: onToggleChecked,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isChecked
                        ? const Color(0xFF4A8B5C)
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isChecked ? Icons.check : Icons.check,
                    color: isChecked ? Colors.white : Colors.grey.shade400,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Delete
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Meal'),
                      content: Text(
                          'Remove "${meal['name']}" from your log?'),
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
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
