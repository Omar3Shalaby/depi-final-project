import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/register bg.png'),
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
                        'assets/logo.png',
                        height: 70,
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
                  child: Column(
                    children: [
                      // Name Field
                      _buildTextField(hint: 'Name', icon: Icons.person_outline),
                      const SizedBox(height: 16),

                      // Email Field
                      _buildTextField(
                        hint: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      _buildTextField(
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      _buildTextField(
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Create Account Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle registration logic
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
                          child: const Text(
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
                            style: TextStyle(color: Colors.grey, fontSize: 14),
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
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
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
}
