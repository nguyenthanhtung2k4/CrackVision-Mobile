import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crackvision/core/l10n/app_strings.dart';
import 'package:crackvision/core/l10n/locale_provider.dart';
import 'package:crackvision/core/router/app_router.dart';
import 'package:crackvision/core/theme/app_theme.dart';
import 'package:crackvision/core/theme/theme_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith(AppRoutes.history)) return 1;
    if (loc.startsWith(AppRoutes.settings)) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = _currentIndex(context);
    final s = AppStrings.of(ref.watch(localeProvider));
    final isDark = ref.watch(themeProvider);
    final tabs = [
      _TabItem(
        label: s.navHome,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        path: AppRoutes.home,
      ),
      _TabItem(
        label: s.navHistory,
        icon: Icons.timeline_rounded,
        activeIcon: Icons.manage_search_rounded,
        path: AppRoutes.history,
      ),
      _TabItem(
        label: s.navSettings,
        icon: Icons.tune_rounded,
        activeIcon: Icons.settings_suggest_rounded,
        path: AppRoutes.settings,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xF21B1815)
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF3A2A20) : const Color(0xFFFFE0C8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final active = index == current;
              return Expanded(
                child: _NavItem(
                  tab: tab,
                  active: active,
                  isDark: isDark,
                  onTap: () => context.go(tab.path),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabItem tab;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark ? Colors.white54 : AppColors.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFFFF7A1A), Color(0xFFD84D0F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? tab.activeIcon : tab.icon,
                size: 21,
                color: active ? Colors.white : inactiveColor,
              ),
              const SizedBox(height: 3),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.white : inactiveColor,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}
