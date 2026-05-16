import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crackvision/core/theme/app_theme.dart';
import 'package:crackvision/core/router/app_router.dart';
import 'package:crackvision/core/l10n/locale_provider.dart';
import 'package:crackvision/core/l10n/app_strings.dart';

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

    final tabs = [
      _TabItem(label: s.navHome,     icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,        path: AppRoutes.home),
      _TabItem(label: s.navHistory,  icon: Icons.access_time_outlined,  activeIcon: Icons.access_time_rounded, path: AppRoutes.history),
      _TabItem(label: s.navSettings, icon: Icons.settings_outlined,     activeIcon: Icons.settings_rounded,    path: AppRoutes.settings),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFFFE0C8), width: 1)),
          boxShadow: [BoxShadow(color: Color(0x14C85600), blurRadius: 12, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final active = i == current;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.go(tab.path),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 28,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFFFFF0E0) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            active ? tab.activeIcon : tab.icon,
                            size: 20,
                            color: active ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
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
  const _TabItem({required this.label, required this.icon, required this.activeIcon, required this.path});
}
