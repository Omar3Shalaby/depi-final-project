import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import your login screen if you want to navigate back to it
// import 'package:your_app_name/screens/login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _selectedGender = 'Male';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/register_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 100,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon if the asset isn't loaded
                          return Icon(
                            Icons.eco,
                            color: Colors.green[700],
                            size: 50,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'NutriVision',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Align(
                    alignment: Alignment.center,
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Registration Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name Field
                        _buildTextField(
                          hint: 'Name',
                          icon: Icons.person_outline,
                          controller: _nameController,
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        _buildTextField(
                          hint: 'Email',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        _buildTextField(
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          controller: _passwordController,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        _buildTextField(
                          hint: 'Confirm Password',
                          icon: Icons.lock_outline,
                          controller: _confirmPasswordController,
                          isPassword: true,
                          obscureText: _obscureConfirmPassword,
                          onToggleVisibility: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Weight Field
                        _buildTextField(
                          hint: 'Weight (kg)',
                          icon: Icons.fitness_center,
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 16),

                        // Height Field
                        _buildTextField(
                          hint: 'Height (cm)',
                          icon: Icons.height,
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 16),

                        // Gender Toggle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gender',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  _buildGenderButton('Male'),
                                  _buildGenderButton('Female'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Create Account Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() => _isLoading = true);

                                      final name = _nameController.text.trim();
                                      final email = _emailController.text.trim();
                                      final password = _passwordController.text.trim();

                                      FirebaseAuth.instance
                                          .createUserWithEmailAndPassword(
                                        email: email,
                                        password: password,
                                      )
                                          .then((userCredential) async {
                                        // Update display name
                                        await userCredential.user!
                                            .updateDisplayName(name);

                                        // Write document to Firestore
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userCredential.user!.uid)
                                            .set({
                                          'name': name,
                                          'email': email,
                                          'createdAt': FieldValue.serverTimestamp(),
                                          'photoBase64': null,
                                          'weight': _weightController.text.trim(),
                                          'height': _heightController.text.trim(),
                                          'gender': _selectedGender,
                                        });

                                        // Calculate suggested calories from BMR and save as default goal
                                        final double? weight = double.tryParse(_weightController.text.trim());
                                        final double? height = double.tryParse(_heightController.text.trim());
                                        if (weight != null && height != null) {
                                          const double age = 25;
                                          double bmr;
                                          if (_selectedGender == 'Male') {
                                            bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
                                          } else {
                                            bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
                                          }
                                          final int suggestedCalories = (bmr * 1.375).round();
                                          final int proteinG = ((suggestedCalories * 0.30) / 4).round();
                                          final int carbsG = ((suggestedCalories * 0.50) / 4).round();
                                          final int fatG = ((suggestedCalories * 0.20) / 9).round();
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.setString('Calories', '$suggestedCalories');
                                          await prefs.setString('Protein', '$proteinG');
                                          await prefs.setString('Carbs', '$carbsG');
                                          await prefs.setString('Fat', '$fatG');
                                        }

                                        if (!mounted) return;

                                        setState(() => _isLoading = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                                "Your account has been created successfully."),
                                            backgroundColor:
                                                Colors.green.shade700,
                                            behavior:
                                                SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                        Navigator.pushReplacementNamed(
                                            context, '/home');
                                      }).catchError((error) {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(error is FirebaseAuthException ? error.message ?? 'Registration failed' : error.toString())),
                                          );
                                        }
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF5A8F69,
                              ), // Matches the slightly muted green in the design
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Navigate back to Login Screen
                                Navigator.pop(context);
                                // OR if you want to push replacement:
                                // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                              },
                              child: const Row(
                                children: [
                                  Text(
                                    'Log in',
                                    style: TextStyle(
                                      color: Color(0xFF333333),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: Color(0xFF333333),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build text fields cleanly
  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (value) {
        // Weight and Height are optional
        if (hint == 'Weight (kg)' || hint == 'Height (cm)') {
          if (value != null && value.trim().isNotEmpty && double.tryParse(value.trim()) == null) {
            return 'Please enter a valid number.';
          }
          return null;
        }
        if (value == null || value.trim().isEmpty) {
          return '$hint is required.';
        }
        if (hint == 'Email' && !value.contains('@')) {
          return 'Please Enter a valid Email.';
        }
        if (hint == 'Password' && value.length < 6) {
          return 'Password Must be at least 6 characters.';
        }
        if (hint == 'Confirm Password' && value != _passwordController.text) {
          return 'Passwords do not match.';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
        prefixIcon: Icon(icon, color: Colors.green.shade700, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade600,
                  size: 22,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A8B5C)),
        ),
      ),
    );
  }

  Widget _buildGenderButton(String label) {
    final bool isSelected = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C5E3B) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
