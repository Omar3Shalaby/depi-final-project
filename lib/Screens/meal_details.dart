import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:nutri_vision/Screens/main_shell.dart';



void main() {
  runApp(const NutritionApp());
}

class NutritionApp extends StatelessWidget {
  const NutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'PlusJakartaSans',
        scaffoldBackgroundColor: const Color(0xFFF1F5F2),
      ),
      home: const MealDetailsScreen(),
    );
  }
}

class MealDetailsScreen extends StatelessWidget {
  const MealDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F2EC), Color(0xFFF1F5F2)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main Scrollable Content
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => MainShellScope.of(context)?.setIndex(2),
                            child: const Icon(Icons.arrow_back, color: Color(0xFF3B694D),),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Meal Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B694D),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content Card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meal Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Grilled chicken with brown rice and salad',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Calories Banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9E6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Calories:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  RichText(
                                    text: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '620 ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'kcal',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Macro Progress Bars
                            _buildMacroBar('Protein:', '42g', 0.65, const Color(0xFF64B5F6)),
                            const SizedBox(height: 16),
                            _buildMacroBar('Carbs:', '55g', 0.75, const Color(0xFFFAA325)),
                            const SizedBox(height: 16),
                            _buildMacroBar('Fat:', '18g', 0.45, const Color(0xFF54E34F)),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(color: Color(0xFFEEEEEE), height: 1),
                            ),

                            // Donut Chart Section
                            Row(
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CustomPaint(
                                        size: const Size(140, 140),
                                        painter: DonutChartPainter(),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text(
                                            '620',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          Text(
                                            'kcal',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF666666),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildLegendItem('Carbs', '36%', const Color(0xFFFAA325)),
                                      const SizedBox(height: 12),
                                      _buildLegendItem('Protein', '27%', const Color(0xFF64B5F6)),
                                      const SizedBox(height: 12),
                                      _buildLegendItem('Fat', '20%', const Color(0xFF54E34F)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Buttons
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF569C6F),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                shadowColor: const Color(0xFF569C6F).withOpacity(0.4),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              child: const Text('Save Meal'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFEEEEEE)),
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                foregroundColor: const Color(0xFF333333),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text('Get Healthier Recipe'),
                                  SizedBox(width: 8),
                                  Icon(Icons.chevron_right, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroBar(String label, String value, double progress, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF5F5F5),
              color: color,
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String percent, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        const Spacer(),
        Text(
          percent,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius - 10);
    const strokeWidth = 20.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track
    paint.color = const Color(0xFFEEEEEE);
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);

    // Carbs
    paint.color = const Color(0xFFFAA325);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * 0.36, false, paint);

    // Protein
    paint.color = const Color(0xFF64B5F6);
    canvas.drawArc(rect, -math.pi / 2 + 2 * math.pi * 0.36, 2 * math.pi * 0.27, false, paint);

    // Fat
    paint.color = const Color(0xFF54E34F);
    canvas.drawArc(rect, -math.pi / 2 + 2 * math.pi * (0.36 + 0.27), 2 * math.pi * 0.20, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}