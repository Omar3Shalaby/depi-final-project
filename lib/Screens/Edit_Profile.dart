import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String _selectedGender = 'Male';
  bool _isLoading = true;
  String? _profilePicB64;

  // Style Constants
  static const Color _primaryGreen = Color(0xFF5F8F7B);
  static const Color _darkButtonGreen = Color(0xFF2C5E3B);
  static const Color _darkGrey = Color(0xFF333333);
  static const Color _lightGrey = Color(0xFFF5F7F6);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? user.displayName ?? '';
        _weightController.text = data['weight']?.toString() ?? '';
        _heightController.text = data['height']?.toString() ?? '';
        _selectedGender = data['gender'] ?? 'Male';
        _profilePicB64 = data['photoBase64'];
      } else {
        _nameController.text = user.displayName ?? '';
        _weightController.text = '';
        _heightController.text = '';
        _selectedGender = 'Male';
        _profilePicB64 = null;
      }
    } catch (_) {
      // silently ignore load errors
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 60,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);

      // Check size limit: ~700KB (716,800 characters)
      if (base64String.length > 716800) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Image too large, please choose a smaller photo"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _profilePicB64 = base64String;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to pick image: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => _isLoading = true);

      try {
        final updates = <String, dynamic>{
          'name': _nameController.text.trim(),
          'weight': _weightController.text.trim(),
          'height': _heightController.text.trim(),
          'gender': _selectedGender,
          'photoBase64': _profilePicB64,
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updates, SetOptions(merge: true));

        await user.updateDisplayName(_nameController.text.trim());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: _primaryGreen,
          ),
        );

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) Navigator.pop(context);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: _primaryGreen),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on background tap
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8F1EE), Color(0xFFF5F7F6)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Custom Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: _primaryGreen),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Profile Header Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
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
                                  GestureDetector(
                                    onTap: _pickImage,
                                    behavior: HitTestBehavior.opaque,
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 50,
                                          backgroundColor: _lightGrey,
                                          backgroundImage: _profilePicB64 != null && _profilePicB64!.isNotEmpty
                                              ? MemoryImage(base64Decode(_profilePicB64!))
                                              : null,
                                          child: _profilePicB64 != null && _profilePicB64!.isNotEmpty
                                              ? null
                                              : Icon(Icons.person, size: 60, color: Colors.grey[400]),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: _primaryGreen,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  _nameController.text.isEmpty ? 'Your Name' : _nameController.text,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _darkGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Edit Form Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _darkGrey,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Full Name
                                _buildInputField(
                                  label: 'Full Name',
                                  controller: _nameController,
                                  icon: Icons.person_outline,
                                  hint: 'Type Your Name',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                ),

                                // Weight
                                _buildInputField(
                                  label: 'Weight',
                                  controller: _weightController,
                                  icon: Icons.fitness_center, // Swapped from clock for relevance
                                  hint: 'Your Weight',
                                  suffix: 'kg',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                ),

                                // Height and Gender Row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildInputField(
                                        label: 'Height',
                                        controller: _heightController,
                                        icon: Icons.height, // Swapped from lock for relevance
                                        hint: 'Height',
                                        suffix: 'cm',
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          if (double.tryParse(value) == null) {
                                            return 'Invalid number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Gender',
                                            style: TextStyle(fontSize: 14, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: _lightGrey,
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            child: Row(
                                              children: [
                                                _buildGenderButton('Male', _selectedGender == 'Male'),
                                                _buildGenderButton('Female', _selectedGender == 'Female'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Save Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _darkButtonGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (val) => setState(() {}), // Updates header name dynamically
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            suffixText: suffix,
            filled: true,
            fillColor: _lightGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGenderButton(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? _darkButtonGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}