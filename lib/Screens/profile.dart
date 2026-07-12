import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nutri_vision/Screens/login.dart';
import 'package:nutri_vision/Screens/Edit_Profile.dart';
import 'package:nutri_vision/Screens/Edit_Goals.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_vision/providers/theme_provider.dart';

/// Pure content widget — Scaffold, background & nav bar live in MainShell.
class ProfileContent extends ConsumerStatefulWidget {
  const ProfileContent({super.key});

  @override
  ConsumerState<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<ProfileContent> {
  bool _notificationsEnabled = true;
  final User? _user = FirebaseAuth.instance.currentUser;
  String _displayName = '';
  String? _profilePicB64;
  String _displayEmail = '';

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadGoals();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _loadName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _displayName = data['name'] ?? user.displayName ?? 'User Name';
            _displayEmail = data['email'] ?? user.email ?? 'user@email.com';
            _profilePicB64 = data['photoBase64'];
          });
        }
        return;
      }
    } catch (e) {
      print('Error loading name from Firestore: $e');
    }

    if (mounted) {
      setState(() {
        _displayName = user.displayName ?? 'User Name';
        _displayEmail = user.email ?? 'user@email.com';
        _profilePicB64 = null;
      });
    }
  }

  String _calories = '2000';
  String _protein = '150g';
  String _carbs = '250g';
  String _fat = '60g';

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _calories = prefs.getString('Calories') ?? '2000';
      _protein = '${prefs.getString('Protein') ?? '150'}g';
      _carbs = '${prefs.getString('Carbs') ?? '250'}g';
      _fat = '${prefs.getString('Fat') ?? '60'}g';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),

          // ── Profile Card ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
              children: [
                // Avatar with edit badge
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4A8B5C),
                          width: 3,
                        ),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                      child: ClipOval(
                        child: _profilePicB64 != null && _profilePicB64!.isNotEmpty
                            ? Image.memory(
                                base64Decode(_profilePicB64!),
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                              )
                            : Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                          ).then((_) => _loadName());
                        },
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4A8B5C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _displayEmail.isEmpty ? (_user?.email ?? 'user@email.com') : _displayEmail,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Health Goals Card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
                // Section title
                Row(
                  children: [
                    const Text('🏃', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Health Goals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Chart + Goals
                Row(
                  children: [
                    // Donut chart
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                            size: const Size(110, 110),
                            painter: _GoalChartPainter(
                              carbs: double.parse(_carbs.replaceAll('g', '').trim().isEmpty ? '250' : _carbs.replaceAll('g', '').trim()),
                              protein: double.parse(_protein.replaceAll('g', '').trim().isEmpty ? '150' : _protein.replaceAll('g', '').trim()),
                              fat: double.parse(_fat.replaceAll('g', '').trim().isEmpty ? '60' : _fat.replaceAll('g', '').trim()),
                              ringColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                               ),
                            ),
                          ),
                           Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _calories,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF2D3748),
                                ),
                              ),
                              Text(
                                'kcal',
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
                    const SizedBox(width: 20),

                    // Legend
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Nutrition Goals',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildGoalRow(
                            color: const Color(0xFFF2A65A),
                            goal: '$_carbs Carbs',
                            value: _carbs,
                          ),
                          const SizedBox(height: 8),
                          _buildGoalRow(
                            color: const Color(0xFF5A92D6),
                            goal: '$_protein Protein',
                            value: _protein,
                          ),
                          const SizedBox(height: 8),
                          _buildGoalRow(
                            color: const Color(0xFF4A8B5C),
                            goal: '$_fat Fat',
                            value: _fat,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Edit Goals Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const EditGoalsScreen()),
                      ).then((_) => _loadGoals());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C5E3B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Edit Goals',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Settings Card ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_rounded,
                        color: Colors.grey.shade500,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit Profile
                _buildSettingRow(
                  icon: Icons.person_rounded,
                  label: 'Edit Profile',
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    ).then((_) => _loadName());
                  },
                ),
                _buildDivider(),

                // Notifications
                _buildSettingRow(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF4A8B5C),
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: (val) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notifications_enabled', val);
                      if (mounted) {
                        setState(() {
                          _notificationsEnabled = val;
                        });
                      }
                    },
                  ),
                  onTap: null,
                ),
                _buildDivider(),

                // Dark Mode Toggle
                _buildSettingRow(
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark Mode',
                  trailing: Switch(
                    value: ref.watch(themeModeProvider) == ThemeMode.dark,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF4A8B5C),
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: (val) {
                      ref.read(themeModeProvider.notifier).toggleTheme(val);
                    },
                  ),
                  onTap: null,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Log Out ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFE57373),
                size: 20,
              ),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFE57373),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE57373)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow({
    required Color color,
    required String goal,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              goal,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required Widget trailing,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2C5E3B).withOpacity(0.2)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF4A8B5C), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF2D3748),
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, color: Colors.grey.withOpacity(0.15), indent: 44);
}

class _GoalChartPainter extends CustomPainter {
  final double carbs;
  final double protein;
  final double fat;
  final Color ringColor;

  _GoalChartPainter({
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 13.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const double startAngle = -math.pi / 2;
    const double gap = 0.08;

    final total = carbs + protein + fat;
    final carbsAngle = (carbs / total) * 2 * math.pi;
    final proteinAngle = (protein / total) * 2 * math.pi;
    final fatAngle = (fat / total) * 2 * math.pi;

    // Background ring
    paint.color = ringColor;
    canvas.drawCircle(center, radius, paint);

    // Carbs — orange
    paint.color = const Color(0xFFF2A65A);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      carbsAngle - gap,
      false,
      paint,
    );

    // Protein — blue
    paint.color = const Color(0xFF5A92D6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + carbsAngle,
      proteinAngle - gap,
      false,
      paint,
    );

    // Fat — green
    paint.color = const Color(0xFF4A8B5C);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + carbsAngle + proteinAngle,
      fatAngle - gap,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GoalChartPainter oldDelegate) =>
      oldDelegate.carbs != carbs ||
          oldDelegate.protein != protein ||
          oldDelegate.fat != fat;
}
