import 'package:flutter/material.dart';
import 'package:nutri_vision/Screens/meal_details.dart';
import 'home.dart';
import 'log_meal.dart';
import 'history.dart';
import 'profile.dart';
import 'ai_recipe.dart'; // 1. Imported the new AI recipe file

/// Exposes MainShell's tab-switching and AI states to child content widgets.
class MainShellScope extends InheritedWidget {
  const MainShellScope({
    super.key,
    required this.currentIndex,
    required this.setIndex,
    required this.currentAnalyzedMeal,
    required this.updateAnalyzedMeal,
    required this.currentAlternatives,
    required this.updateAlternatives,
    required super.child,
  });

  final int currentIndex;
  final void Function(int) setIndex;
  final Map<String, dynamic>? currentAnalyzedMeal;
  final void Function(Map<String, dynamic>?) updateAnalyzedMeal;
  final List<Map<String, dynamic>> currentAlternatives;
  final void Function(List<Map<String, dynamic>>) updateAlternatives;

  static MainShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainShellScope>();

  @override
  bool updateShouldNotify(MainShellScope oldWidget) {
    return oldWidget.currentIndex != currentIndex ||
        oldWidget.currentAnalyzedMeal != currentAnalyzedMeal ||
        oldWidget.currentAlternatives != currentAlternatives;
  }
}

/// The persistent shell: owns the background image and nav bar.
/// Content is swapped via IndexedStack — no full-page transitions.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  Map<String, dynamic>? _currentAnalyzedMeal;
  List<Map<String, dynamic>> _currentAlternatives = [];

  void _setIndex(int index) {
    if (_currentIndex != index) setState(() => _currentIndex = index);
  }

  void _updateAnalyzedMeal(Map<String, dynamic>? meal) {
    setState(() => _currentAnalyzedMeal = meal);
  }

  void _updateAlternatives(List<Map<String, dynamic>> alternatives) {
    setState(() => _currentAlternatives = alternatives);
  }

  @override
  Widget build(BuildContext context) {
    return MainShellScope(
      currentIndex: _currentIndex,
      setIndex: _setIndex,
      currentAnalyzedMeal: _currentAnalyzedMeal,
      updateAnalyzedMeal: _updateAnalyzedMeal,
      currentAlternatives: _currentAlternatives,
      updateAlternatives: _updateAlternatives,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/main_bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // ── Page content (no animation, instant swap) ──────────
                IndexedStack(
                  index: _currentIndex,
                  children: [
                    HomeContent(),      // index 0
                    HistoryContent(),   // index 1
                    LogMealContent(),   // index 2
                    AiRecipeAlternativeContent(), // index 3
                    ProfileContent(),   // index 4
                    MealDetailsScreen(), // index 5
                  ],
                ),

                // ── Persistent Navigation Bar ──────────────────────────
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(
                        left: 20, right: 20, bottom: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _NavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          index: 0,
                          currentIndex: _currentIndex,
                          onTap: _setIndex,
                        ),
                        _NavItem(
                          icon: Icons.bookmark_border_rounded,
                          label: 'History',
                          index: 1,
                          currentIndex: _currentIndex,
                          onTap: _setIndex,
                        ),
                        // ── Center FAB ─────────────────────────────
                        GestureDetector(
                          onTap: () => _setIndex(_currentIndex == 2 ? 0 : 2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _currentIndex == 2
                                  ? const Color(0xFF2C5E3B)
                                  : const Color(0xFF4A8B5C),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4A8B5C)
                                      .withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: AnimatedRotation(
                              turns: _currentIndex == 2 ? 0.125 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                        _NavItem(
                          icon: Icons.auto_awesome_rounded,
                          label: 'AI Recipes',
                          index: 3,
                          currentIndex: _currentIndex,
                          onTap: _setIndex,
                        ),
                        _NavItem(
                          icon: Icons.person_outline_rounded,
                          label: 'Profile',
                          index: 4,
                          currentIndex: _currentIndex,
                          onTap: _setIndex,
                        ),
                      ],
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
}

// ── Reusable Nav Item ─────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(isActive),
                color: isActive
                    ? const Color(0xFF4A8B5C)
                    : Colors.grey.shade400,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? const Color(0xFF4A8B5C)
                    : Colors.grey.shade500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stub for unbuilt pages ────────────────────────────────────────────────────
class _StubPage extends StatelessWidget {
  const _StubPage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF4A8B5C),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}