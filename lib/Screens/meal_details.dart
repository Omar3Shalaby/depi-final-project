import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutri_vision/services/storage_service.dart';
import 'package:nutri_vision/models/meal_model.dart';
import 'package:nutri_vision/providers/app_providers.dart';
import 'package:nutri_vision/providers/meal_provider.dart';
import 'package:nutri_vision/services/notification_service.dart';

class MealDetailsScreen extends ConsumerStatefulWidget {
  const MealDetailsScreen({super.key});

  @override
  ConsumerState<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends ConsumerState<MealDetailsScreen> {
  bool _isGeneratingAlternatives = false;
  bool _isSaving = false;
  bool _listenerRegistered = false;
  double _goalProtein = 150.0;
  double _goalCarbs = 250.0;
  double _goalFat = 60.0;

  @override
  void initState() {
    super.initState();
    _loadDailyGoals();
  }

  Future<void> _loadDailyGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goalProtein =
          double.tryParse(prefs.getString('Protein') ?? '150') ?? 150.0;
      _goalCarbs = double.tryParse(prefs.getString('Carbs') ?? '250') ?? 250.0;
      _goalFat = double.tryParse(prefs.getString('Fat') ?? '60') ?? 60.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we register the provider listener from within build
    // (ref.listen must be called during build for ConsumerWidgets).
    if (!_listenerRegistered) {
      _listenerRegistered = true;
      ref.listen<Meal?>(analyzedMealProvider, (previous, next) {
        if (previous?.id != next?.id) {
          if (mounted) {
            setState(() {
              _isSaving = false;
              _isGeneratingAlternatives = false;
            });
          }
        }
      });
    }

    final meal = ref.watch(analyzedMealProvider);

    if (meal == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8F2EC), Color(0xFFF1F5F2)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Color(0xFF4A8B5C),
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Meal Analyzed Yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Go to the Log Meal tab to describe what you ate and get a dynamic AI analysis of your nutrition.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.read(navigationIndexProvider.notifier).state = 2,
                      icon: const Icon(Icons.add),
                      label: const Text('Log A Meal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A8B5C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final String name = meal.name;
    final int kcal = meal.kcal;
    final int protein = meal.protein;
    final int carbs = meal.carbs;
    final int fat = meal.fat;

    // Calculate percentages for donut chart
    final double carbsKcal = carbs * 4.0;
    final double proteinKcal = protein * 4.0;
    final double fatKcal = fat * 9.0;
    final double totalKcalCalculated = carbsKcal + proteinKcal + fatKcal;

    final double carbsPercent = totalKcalCalculated > 0
        ? (carbsKcal / totalKcalCalculated)
        : 0.33;
    final double proteinPercent = totalKcalCalculated > 0
        ? (proteinKcal / totalKcalCalculated)
        : 0.33;
    final double fatPercent = totalKcalCalculated > 0
        ? (fatKcal / totalKcalCalculated)
        : 0.34;

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
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                ref
                                        .read(navigationIndexProvider.notifier)
                                        .state =
                                    2,
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF3B694D),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Meal Analysis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B694D),
                            ),
                          ),
                          const Spacer(),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Analysis Result',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A8B5C),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Calories Banner
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9E6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Estimated Calories:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$kcal ',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        const TextSpan(
                                          text: 'kcal',
                                          style: TextStyle(
                                            fontSize: 15,
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

                            // Macro Progress Bars (percentage relative to daily goal targets)
                            _buildMacroBar(
                              'Protein:',
                              '${protein}g',
                              (protein / _goalProtein).clamp(0.0, 1.0),
                              const Color(0xFF64B5F6),
                            ),
                            const SizedBox(height: 16),
                            _buildMacroBar(
                              'Carbs:',
                              '${carbs}g',
                              (carbs / _goalCarbs).clamp(0.0, 1.0),
                              const Color(0xFFFAA325),
                            ),
                            const SizedBox(height: 16),
                            _buildMacroBar(
                              'Fat:',
                              '${fat}g',
                              (fat / _goalFat).clamp(0.0, 1.0),
                              const Color(0xFF54E34F),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(
                                color: Color(0xFFEEEEEE),
                                height: 1,
                              ),
                            ),

                            // Donut Chart Section
                            Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CustomPaint(
                                        size: const Size(120, 120),
                                        painter: DonutChartPainter(
                                          carbsPercent: carbsPercent,
                                          proteinPercent: proteinPercent,
                                          fatPercent: fatPercent,
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$kcal',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          const Text(
                                            'kcal',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF666666),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildLegendItem(
                                        'Carbs',
                                        '${(carbsPercent * 100).toStringAsFixed(0)}%',
                                        const Color(0xFFFAA325),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildLegendItem(
                                        'Protein',
                                        '${(proteinPercent * 100).toStringAsFixed(0)}%',
                                        const Color(0xFF64B5F6),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildLegendItem(
                                        'Fat',
                                        '${(fatPercent * 100).toStringAsFixed(0)}%',
                                        const Color(0xFF54E34F),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Buttons
                            ElevatedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () async {
                                      try {
                                        setState(() => _isSaving = true);
                                        final now = DateTime.now();
                                        final savedMeal = Meal(
                                          id: now.millisecondsSinceEpoch
                                              .toString(),
                                          name: name,
                                          time:
                                              '${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
                                          kcal: kcal,
                                          protein: protein,
                                          carbs: carbs,
                                          fat: fat,
                                          icon: 'default',
                                        );
                                        await StorageService.saveMeal(
                                          now,
                                          savedMeal,
                                        );
                                        // Trigger notification about the meal
                                        NotificationService.showMealAnalysisNotification(
                                          name,
                                          kcal,
                                        ).catchError((_) {});
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      '✓ "$name" successfully logged in your meals history!',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: const Color(
                                                0xFF4A8B5C,
                                              ),
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                          ref
                                                  .read(
                                                    analyzedMealProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              null;
                                          ref
                                                  .read(
                                                    navigationIndexProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              0;
                                        }
                                      } on DuplicateMealException {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Row(
                                                children: [
                                                  Icon(
                                                    Icons.info_outline,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      'This meal has already been logged today.',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Color(
                                                0xFFF2A65A,
                                              ),
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      } on MealLimitExceededException {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
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
                                              backgroundColor: Colors.redAccent,
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error saving meal: $e',
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted)
                                          setState(() => _isSaving = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF569C6F),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Save Meal'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _isGeneratingAlternatives
                                  ? null
                                  : () async {
                                      setState(
                                        () => _isGeneratingAlternatives = true,
                                      );
                                      try {
                                        // Use the proper Recipe-typed provider
                                        await ref
                                            .read(alternativesProvider.notifier)
                                            .fetchAlternatives(meal);
                                        if (context.mounted) {
                                          ref
                                                  .read(
                                                    navigationIndexProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              3;
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error generating alternatives: $e',
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(
                                            () => _isGeneratingAlternatives =
                                                false,
                                          );
                                        }
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFEEEEEE),
                                ),
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                foregroundColor: const Color(0xFF333333),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isGeneratingAlternatives)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF333333),
                                      ),
                                    )
                                  else
                                    const Text('Get Healthier Recipes'),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.auto_awesome,
                                    size: 20,
                                    color: Color(0xFF4A8B5C),
                                  ),
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

  Widget _buildMacroBar(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF5F5F5),
              color: color,
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String percent, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
        const Spacer(),
        Text(
          percent,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double carbsPercent;
  final double proteinPercent;
  final double fatPercent;

  DonutChartPainter({
    required this.carbsPercent,
    required this.proteinPercent,
    required this.fatPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius - 8);
    const strokeWidth = 14.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track
    paint.color = const Color(0xFFEEEEEE);
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);

    // Total ratio sum to normalize just in case
    final double total = carbsPercent + proteinPercent + fatPercent;
    if (total == 0) return;

    const double startAngle = -math.pi / 2;
    const double gap = 0.05; // tiny gap for premium segmented look

    // Carbs
    paint.color = const Color(0xFFFAA325);
    final carbsSweep = (carbsPercent / total) * 2 * math.pi;
    canvas.drawArc(rect, startAngle, carbsSweep - gap, false, paint);

    // Protein
    paint.color = const Color(0xFF64B5F6);
    final proteinSweep = (proteinPercent / total) * 2 * math.pi;
    canvas.drawArc(
      rect,
      startAngle + carbsSweep,
      proteinSweep - gap,
      false,
      paint,
    );

    // Fat
    paint.color = const Color(0xFF54E34F);
    final fatSweep = (fatPercent / total) * 2 * math.pi;
    canvas.drawArc(
      rect,
      startAngle + carbsSweep + proteinSweep,
      fatSweep - gap,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
