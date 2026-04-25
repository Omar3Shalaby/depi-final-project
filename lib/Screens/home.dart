import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'main_shell.dart';

/// Pure content widget — Scaffold, background & nav bar live in MainShell.
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
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
                'Hello, Ahmad 👋',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
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
                child: const Icon(Icons.person, color: Color(0xFF718096)),
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
                            painter: NutritionChartPainter(),
                          ),
                          const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '1,320',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              Text(
                                '2000 Cal',
                                style: TextStyle(
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
                          '150g',
                          'Carbs',
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          const Color(0xFF5A92D6),
                          '98g',
                          'Protein',
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(const Color(0xFF4A8B5C), '41g', 'Fat'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: '753 kcal ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
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
                    // Switch to Log Meal tab in MainShell
                    MainShellScope.of(context)?.setIndex(2);
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
                child: _buildQuickActionCard(
                  icon: Icons.camera_alt,
                  iconColor: Colors.white,
                  iconBgColor: const Color(0xFF8B9CB6),
                  title: 'Analyze Food',
                  subtitle: 'Get nutritional info',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.auto_awesome,
                  iconColor: Colors.white,
                  iconBgColor: const Color(0xFF4A8B5C),
                  title: 'Healthy Recipe',
                  subtitle: 'AI-suggested alternative',
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
              Text(
                'View All Tips >',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
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
                        'Eat more leafy greens!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "They're low in calories but high in nutrients like vitamin K, vitamin C, and fiber.",
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

    const double startAngle = -math.pi / 2;

    paint.color = const Color(0xFFF2A65A);
    const orangeSweep = math.pi * 0.9;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      orangeSweep,
      false,
      paint,
    );

    paint.color = const Color(0xFF5A92D6);
    const blueSweep = math.pi * 0.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + orangeSweep + 0.1,
      blueSweep,
      false,
      paint,
    );

    paint.color = const Color(0xFF4A8B5C);
    const greenSweep = math.pi * 0.4;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + orangeSweep + blueSweep + 0.2,
      greenSweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
