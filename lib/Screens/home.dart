import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutri_vision/services/storage_service.dart';
import 'package:nutri_vision/providers/app_providers.dart';

/// Pure content widget — Scaffold, background & nav bar live in MainShell.
class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  String _displayName = 'Ahmad';
  int _consumedKcal = 0;
  int _consumedCarbs = 0;
  int _consumedProtein = 0;
  int _consumedFat = 0;

  int _goalKcal = 2000;

  @override
  void initState() {
    super.initState();
    _loadData();
    ref.listenManual<int>(navigationIndexProvider, (previous, next) {
      if (next == 0 && previous != 0) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayMeals = await StorageService.getMealsForDate(DateTime.now());

    int kcalSum = 0;
    int carbsSum = 0;
    int proteinSum = 0;
    int fatSum = 0;

    for (var m in todayMeals) {
      kcalSum += m.kcal;
      carbsSum += m.carbs;
      proteinSum += m.protein;
      fatSum += m.fat;
    }

    final name = prefs.getString('name') ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'User';

    setState(() {
      _displayName = name;
      _consumedKcal = kcalSum;
      _consumedCarbs = carbsSum;
      _consumedProtein = proteinSum;
      _consumedFat = fatSum;

      _goalKcal = int.tryParse(prefs.getString('Calories') ?? '2000') ?? 2000;
    });
  }

  @override
  Widget build(BuildContext context) {
    final remainingKcal = math.max(0, _goalKcal - _consumedKcal);

    // Compute ratios for donut chart painter
    final double carbsKcal = _consumedCarbs * 4.0;
    final double proteinKcal = _consumedProtein * 4.0;
    final double fatKcal = _consumedFat * 9.0;
    final double totalKcalCalculated = carbsKcal + proteinKcal + fatKcal;

    final double carbsPercent = totalKcalCalculated > 0 ? (carbsKcal / totalKcalCalculated) : 0.33;
    final double proteinPercent = totalKcalCalculated > 0 ? (proteinKcal / totalKcalCalculated) : 0.33;
    final double fatPercent = totalKcalCalculated > 0 ? (fatKcal / totalKcalCalculated) : 0.34;
    final double totalFraction = _goalKcal > 0 ? (_consumedKcal / _goalKcal).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 100, // clearance for the floating nav bar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hello, $_displayName 👋',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    ref.read(navigationIndexProvider.notifier).state = 4;
                  },
                  child: const Icon(Icons.person, color: Color(0xFF718096)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Today's Nutrition Card ───────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Nutrition",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Circular Chart
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(120, 120),
                            painter: NutritionChartPainter(
                              totalFraction: totalFraction,
                              carbsPercent: carbsPercent,
                              proteinPercent: proteinPercent,
                              fatPercent: fatPercent,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_consumedKcal',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              Text(
                                '$_goalKcal Cal',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),
                    // Macros Legend
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(
                          const Color(0xFFF2A65A),
                          '${_consumedCarbs}g',
                          'Carbs',
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          const Color(0xFF5A92D6),
                          '${_consumedProtein}g',
                          'Protein',
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          const Color(0xFF4A8B5C),
                          '${_consumedFat}g',
                          'Fat',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$remainingKcal kcal ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                          fontSize: 14,
                        ),
                      ),
                      const TextSpan(
                        text: 'remaining',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Quick Actions ────────────────────────────────────
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Log Meal — taps the shell's tab index 2
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(navigationIndexProvider.notifier).state = 2;
                  },
                  child: _buildQuickActionCard(
                    icon: Icons.add,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFF4A8B5C),
                    title: 'Log Meal',
                    subtitle: 'Add a new meal',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(navigationIndexProvider.notifier).state = 3;
                  },
                  child: _buildQuickActionCard(
                    icon: Icons.auto_awesome,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFF4A8B5C),
                    title: 'Healthy Recipe',
                    subtitle: 'AI-suggested alternatives',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Today's Tip ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Tip",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFFD4E157), size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keep it balanced!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Try to hit your goal ratios. Keep your carbs near 50%, protein near 30%, and fat near 20% for stable daily energy.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String value, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painter ────────────────────────────────────────────────────────────
class NutritionChartPainter extends CustomPainter {
  final double totalFraction;
  final double carbsPercent;
  final double proteinPercent;
  final double fatPercent;

  NutritionChartPainter({
    required this.totalFraction,
    required this.carbsPercent,
    required this.proteinPercent,
    required this.fatPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = Colors.grey.shade200;
    canvas.drawCircle(center, radius, paint);

    if (totalFraction == 0) return;

    const double startAngle = -math.pi / 2;
    final double totalSweep = 2 * math.pi * totalFraction;

    const double gap = 0.05; // gap between segments for beautiful premium look

    // Carbs (orange)
    paint.color = const Color(0xFFF2A65A);
    final carbsSweep = totalSweep * carbsPercent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      (carbsSweep - gap).clamp(0.0, 2 * math.pi),
      false,
      paint,
    );

    // Protein (blue)
    paint.color = const Color(0xFF5A92D6);
    final proteinSweep = totalSweep * proteinPercent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + carbsSweep,
      (proteinSweep - gap).clamp(0.0, 2 * math.pi),
      false,
      paint,
    );

    // Fat (green)
    paint.color = const Color(0xFF4A8B5C);
    final fatSweep = totalSweep * fatPercent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + carbsSweep + proteinSweep,
      (fatSweep - gap).clamp(0.0, 2 * math.pi),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
