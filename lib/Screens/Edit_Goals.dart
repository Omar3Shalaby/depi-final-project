import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditGoalsScreen extends StatefulWidget {
  const EditGoalsScreen({super.key});

  @override
  State <EditGoalsScreen> createState() => _EditGoalsScreenState();
}

class _EditGoalsScreenState extends State<EditGoalsScreen> {
  // TextEditingControllers for each field with default values
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  bool _isLoadingGoals = true;
  bool _isAutoCalculating = false;
  String? _macroWarning;
  int? _suggestedCalories;
  String? _gender;
  double? _weight;
  double? _height;

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _caloriesController.addListener(_onCaloriesChanged);
    _proteinController.addListener(_checkMacroMismatch);
    _carbsController.addListener(_checkMacroMismatch);
    _fatController.addListener(_checkMacroMismatch);
  }

  void _onCaloriesChanged() {
    if (_isLoadingGoals || _isAutoCalculating) return;
    final calories = int.tryParse(_caloriesController.text);
    if (calories == null || calories <= 0) return;

    _isAutoCalculating = true;
    final proteinG = ((calories * 0.30) / 4).round();
    final carbsG = ((calories * 0.50) / 4).round();
    final fatG = ((calories * 0.20) / 9).round();
    _proteinController.text = proteinG.toString();
    _carbsController.text = carbsG.toString();
    _fatController.text = fatG.toString();
    _isAutoCalculating = false;
    _checkMacroMismatch();
  }

  void _checkMacroMismatch() {
    if (_isLoadingGoals || _isAutoCalculating) return;
    final calories = int.tryParse(_caloriesController.text) ?? 0;
    final protein = int.tryParse(_proteinController.text) ?? 0;
    final carbs = int.tryParse(_carbsController.text) ?? 0;
    final fat = int.tryParse(_fatController.text) ?? 0;

    final macroCalories = (protein * 4) + (carbs * 4) + (fat * 9);
    final diff = (macroCalories - calories).abs();
    final tolerance = calories * 0.1;

    setState(() {
      _macroWarning = (calories > 0 && diff > tolerance)
          ? 'Your macros (~$macroCalories kcal) don\'t match your calorie goal ($calories kcal).'
          : null;
    });
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _caloriesController.text = prefs.getString('Calories') ?? '2000';
      _proteinController.text = prefs.getString('Protein') ?? '150';
      _carbsController.text = prefs.getString('Carbs') ?? '250';
      _fatController.text = prefs.getString('Fat') ?? '60';
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _gender = data['gender'] ?? 'Male';
          _weight = double.tryParse(data['weight']?.toString() ?? '');
          _height = double.tryParse(data['height']?.toString() ?? '');

          if (_weight != null && _height != null) {
            final double age = 25;
            double bmr = 0;
            if (_gender?.toLowerCase() == 'male') {
              bmr = (10 * _weight!) + (6.25 * _height!) - (5 * age) + 5;
            } else {
              bmr = (10 * _weight!) + (6.25 * _height!) - (5 * age) - 161;
            }
            _suggestedCalories = (bmr * 1.375).round();
          }
        }
      } catch (_) {
        // silently ignore calorie suggestion errors
      }
    }

    setState(() {
      _isLoadingGoals = false;
    });
  }

  @override
  void dispose() {
    _caloriesController.removeListener(_onCaloriesChanged);
    _proteinController.removeListener(_checkMacroMismatch);
    _carbsController.removeListener(_checkMacroMismatch);
    _fatController.removeListener(_checkMacroMismatch);
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
    final calories = int.tryParse(_caloriesController.text);
    if (calories == null || calories < 500 || calories > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily Calories must be between 500 and 10,000 kcal.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('Calories', _caloriesController.text);
    await prefs.setString('Protein', _proteinController.text);
    await prefs.setString('Carbs', _carbsController.text);
    await prefs.setString('Fat', _fatController.text);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Goal saved!'),
        backgroundColor: Color(0xFF2C5E3B),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFEDF4EF);
    const Color primaryGreen = Color(0xFF2C5E3B);
    const Color inputBgColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Goals',
          style: GoogleFonts.nunito(
            color: const Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Empty space for illustration (as requested)
                  SvgPicture.asset(
                    'assets/icons/goals_illustration.svg',
                    height:200,
                    fit: BoxFit.contain,
                  ),

                  // Daily Goals Label
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Daily Goals',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),

                  // Form Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInputRow(
                            label: 'Daily Calories',
                            controller: _caloriesController,
                            unit: 'kcal',
                            icon: null,
                          ),
                          _buildInputRow(
                            label: 'Protein',
                            controller: _proteinController,
                            unit: 'g',
                            icon: SvgPicture.asset(
                              'assets/icons/protein.svg',
                              width: 32,
                              height: 32,)
                            //icon: const Text('🧊', style: TextStyle(fontSize: 20)),
                          ),
                          _buildInputRow(
                            label: 'Carbs',
                            controller: _carbsController,
                            unit: 'g',
                            icon: SvgPicture.asset(
                              'assets/icons/carbs.svg',
                              width:32,
                              height: 32,)
                            //icon: const Text('🥚', style: TextStyle(fontSize: 20)),
                          ),
                          _buildInputRow(
                              label: 'Fat',
                              controller: _fatController,
                              unit: 'g',
                              icon: SvgPicture.asset(
                                'assets/icons/fat.svg',
                                width: 26,
                                height: 26,)
                            //icon: const Text('🍑', style: TextStyle(fontSize: 20)),
                          ),
                          if (_macroWarning != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _macroWarning!,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Suggested Calories Card
                  if (_suggestedCalories != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C5E3B), Color(0xFF4A9465)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2C5E3B).withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Suggested for You',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$_suggestedCalories',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    'kcal / day',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Based on your ${_gender?.toLowerCase() ?? 'profile'}, ${_weight?.toStringAsFixed(0) ?? '?'} kg, ${_height?.toStringAsFixed(0) ?? '?'} cm\n(Mifflin-St Jeor · lightly active)',
                              style: GoogleFonts.nunito(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () {
                                _isAutoCalculating = true;
                                _caloriesController.text = '$_suggestedCalories';
                                _isAutoCalculating = false;
                                _onCaloriesChanged();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white38),
                                ),
                                child: Text(
                                  '✦ Use this value',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Add your weight, height, and gender in Edit Profile to see your personalised calorie suggestion.',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 100), // Extra space to scroll above button
                ],
              ),
            ),
          ),

          // Pinned Save Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildInputRow({
    required String label,
    required TextEditingController controller,
    required String unit,
    Widget? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.left,
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Text(
                    unit,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}