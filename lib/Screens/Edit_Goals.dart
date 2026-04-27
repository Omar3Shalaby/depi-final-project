import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/svg.dart';

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
        textTheme: GoogleFonts.nunitoTextTheme(),
      ),
      home: const EditGoalsScreen(),
    );
  }
}

class EditGoalsScreen extends StatefulWidget {
  const EditGoalsScreen({super.key});

  @override
  State <EditGoalsScreen> createState() => _EditGoalsScreenState();
}

class _EditGoalsScreenState extends State<EditGoalsScreen>

{
  // TextEditingControllers for each field with default values
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _caloriesController.text = prefs.getString('Calories') ?? '2000';
      _proteinController.text = prefs.getString('Protein') ?? '150';
      _carbsController.text = prefs.getString('Carbs') ?? '250';
      _fatController.text = prefs.getString('Fat') ?? '60';
    });
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
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