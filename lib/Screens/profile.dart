import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:nutri_vision/Screens/login.dart';

/// Pure content widget — Scaffold, background & nav bar live in MainShell.
class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),

          // ── Profile Card ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                        color: Colors.grey.shade200,
                      ),
                      child: ClipOval(
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
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
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Ahmad Malik',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ahmad.malik@email.com',
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
              color: Colors.white,
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
                    const Text(
                      'Health Goals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
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
                          CustomPaint(
                            size: const Size(110, 110),
                            painter: _GoalChartPainter(),
                          ),
                          const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '2000',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
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
                          const Text(
                            'Daily Nutrition Goals',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildGoalRow(
                            color: const Color(0xFFF2A65A),
                            goal: '250g Carbs',
                            value: '250g',
                          ),
                          const SizedBox(height: 8),
                          _buildGoalRow(
                            color: const Color(0xFF5A92D6),
                            goal: '150g Protein',
                            value: '150g',
                          ),
                          const SizedBox(height: 8),
                          _buildGoalRow(
                            color: const Color(0xFF4A8B5C),
                            goal: '60g Fat',
                            value: '12g',
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
                    onPressed: () {},
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
              color: Colors.white,
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
                  onTap: () {},
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
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),
                  onTap: null,
                ),
                _buildDivider(),

                // Privacy Policy
                _buildSettingRow(
                  icon: Icons.shield_rounded,
                  label: 'Privacy Policy',
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {},
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
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
              style: const TextStyle(fontSize: 12, color: Color(0xFF2D3748)),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
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
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF4A8B5C), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
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
      Divider(height: 1, color: Colors.grey.shade100, indent: 44);
}

// ── Goal Donut Chart Painter ──────────────────────────────────────────────────
class _GoalChartPainter extends CustomPainter {
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

    // Background ring
    paint.color = Colors.grey.shade100;
    canvas.drawCircle(center, radius, paint);

    // Carbs — orange, ~47%
    paint.color = const Color(0xFFF2A65A);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      math.pi * 0.94,
      false,
      paint,
    );

    // Protein — blue, ~31%
    paint.color = const Color(0xFF5A92D6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + math.pi * 0.94 + 0.08,
      math.pi * 0.62,
      false,
      paint,
    );

    // Fat — green, ~22%
    paint.color = const Color(0xFF4A8B5C);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + math.pi * 0.94 + math.pi * 0.62 + 0.16,
      math.pi * 0.36,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
