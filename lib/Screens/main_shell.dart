import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../providers/theme_provider.dart';
import 'home.dart';
import 'log_meal.dart';
import 'history.dart';
import 'profile.dart';
import 'ai_recipe.dart';
import 'meal_details.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(isDark
                ? 'assets/images/main_bg_dark.png'
                : 'assets/images/main_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              IndexedStack(
                index: currentIndex,
                children: const [
                  HomeContent(),
                  HistoryContent(),
                  LogMealContent(),
                  AiRecipeAlternativeContent(),
                  ProfileContent(),
                  MealDetailsScreen(),
                ],
              ),
              // Navigation Bar
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(
                      left: 20, right: 20, bottom: 20),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.08),
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
                        currentIndex: currentIndex,
                        onTap: (i) => ref.read(navigationIndexProvider.notifier).state = i,
                      ),
                      _NavItem(
                        icon: Icons.bookmark_border_rounded,
                        label: 'History',
                        index: 1,
                        currentIndex: currentIndex,
                        onTap: (i) => ref.read(navigationIndexProvider.notifier).state = i,
                      ),
                      GestureDetector(
                        onTap: () => ref.read(navigationIndexProvider.notifier).state = currentIndex == 2 ? 0 : 2,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: currentIndex == 2
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
                            turns: currentIndex == 2 ? 0.125 : 0,
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
                        currentIndex: currentIndex,
                        onTap: (i) => ref.read(navigationIndexProvider.notifier).state = i,
                      ),
                      _NavItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        index: 4,
                        currentIndex: currentIndex,
                        onTap: (i) => ref.read(navigationIndexProvider.notifier).state = i,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                    : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade400),
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
                    : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.grey.shade500),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
