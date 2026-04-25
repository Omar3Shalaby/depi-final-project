import 'package:flutter/material.dart';

/// Pure content widget — Scaffold, background & nav bar live in MainShell.
class HistoryContent extends StatefulWidget {
  const HistoryContent({super.key});

  @override
  State<HistoryContent> createState() => _HistoryContentState();
}

class _HistoryContentState extends State<HistoryContent> {
  // Simulated current date offset for the date navigator
  int _dayOffset = 0;

  String get _dateLabel {
    if (_dayOffset == 0) return 'Today, April 24';
    if (_dayOffset == -1) return 'Yesterday, April 23';
    if (_dayOffset == 1) return 'Tomorrow, April 25';
    final day = 24 + _dayOffset;
    return 'April $day';
  }

  // Sample meal data
  final List<Map<String, dynamic>> _meals = [
    {
      'name': 'Breakfast',
      'time': '8:30 AM',
      'kcal': 350,
      'carbs': 45,
      'protein': 18,
      'fat': 12,
      'icon': Icons.egg_alt_rounded,
      'color': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFF2A65A),
      'checked': false,
    },
    {
      'name': 'Lunch',
      'time': '1:15 PM',
      'kcal': 620,
      'carbs': 55,
      'protein': 42,
      'fat': 18,
      'icon': Icons.rice_bowl_rounded,
      'color': Color(0xFFE8F5E9),
      'iconColor': Color(0xFF4A8B5C),
      'checked': true,
    },
    {
      'name': 'Dinner',
      'time': '7:45 PM',
      'kcal': 350,
      'carbs': 50,
      'protein': 22,
      'fat': 11,
      'icon': Icons.dinner_dining_rounded,
      'color': Color(0xFFE3F2FD),
      'iconColor': Color(0xFF5A92D6),
      'checked': false,
    },
  ];

  int get _totalKcal =>
      _meals.fold(0, (sum, m) => sum + (m['kcal'] as int));
  int get _totalProtein =>
      _meals.fold(0, (sum, m) => sum + (m['protein'] as int));
  int get _totalCarbs =>
      _meals.fold(0, (sum, m) => sum + (m['carbs'] as int));
  int get _totalFat =>
      _meals.fold(0, (sum, m) => sum + (m['fat'] as int));
  static const int _goalKcal = 2000;

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
                child: const Icon(
                  Icons.calendar_view_week_rounded,
                  color: Color(0xFF4A8B5C),
                  size: 20,
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
                  onTap: () => setState(() => _dayOffset--),
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
                  onTap: () => setState(() => _dayOffset++),
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
                onTap: () {},
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

          // ── Meal Cards ────────────────────────────────────────
          ..._meals.map((meal) => _MealCard(meal: meal)),
          const SizedBox(height: 20),

          // ── Daily Summary Card ────────────────────────────────
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      'See Details >',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
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
                      '${((_totalKcal / _goalKcal) * 100).toStringAsFixed(0)}%',
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
                    value: (_totalKcal / _goalKcal).clamp(0.0, 1.0),
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
  const _MealCard({required this.meal});
  final Map<String, dynamic> meal;

  @override
  Widget build(BuildContext context) {
    final bool isChecked = meal['checked'] as bool;

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
              color: meal['color'] as Color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              meal['icon'] as IconData,
              color: meal['iconColor'] as Color,
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
                    Text(
                      meal['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      meal['time'] as String,
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

          // Checked indicator or more options
          if (isChecked)
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF4A8B5C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            )
          else
            Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
