import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crackvision/features/auth/presentation/auth_provider.dart';
import 'package:crackvision/core/l10n/locale_provider.dart';
import 'package:crackvision/core/l10n/app_strings.dart';

// ── Settings state ────────────────────────────────────────────
class _SettingsState {
  final bool offlineMode;
  final bool notifications;
  final bool autoSave;
  final bool highAccuracy;
  final bool darkMode;
  final String language; // 'vi' | 'en'

  const _SettingsState({
    this.offlineMode = true,
    this.notifications = true,
    this.autoSave = true,
    this.highAccuracy = true,
    this.darkMode = false,
    this.language = 'vi',
  });

  _SettingsState copyWith({
    bool? offlineMode,
    bool? notifications,
    bool? autoSave,
    bool? highAccuracy,
    bool? darkMode,
    String? language,
  }) =>
      _SettingsState(
        offlineMode: offlineMode ?? this.offlineMode,
        notifications: notifications ?? this.notifications,
        autoSave: autoSave ?? this.autoSave,
        highAccuracy: highAccuracy ?? this.highAccuracy,
        darkMode: darkMode ?? this.darkMode,
        language: language ?? this.language,
      );
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _SettingsState _s = const _SettingsState();
  bool _showLangModal = false;
  String _tempLang = 'vi';

  static const _langs = [
    {'code': 'vi', 'flag': '🇻🇳', 'native': 'Tiếng Việt', 'label': 'Vietnamese'},
    {'code': 'en', 'flag': '🇺🇸', 'native': 'English', 'label': 'English'},
  ];

  String get _currentLang => ref.read(localeProvider);
  String get _currentFlag =>
      _langs.firstWhere((l) => l['code'] == _currentLang, orElse: () => _langs[0])['flag']!;
  String get _currentNative =>
      _langs.firstWhere((l) => l['code'] == _currentLang, orElse: () => _langs[0])['native']!;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final lang = ref.watch(localeProvider);
    final s = AppStrings.of(lang);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EC),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(user?.fullName ?? (lang == 'en' ? 'User' : 'Người dùng'), s),
                  _buildQuickStats(s),
                  _buildLanguageRow(s),
                  _buildSection(s.sectionDetection, [
                    _ToggleRow(
                      icon: Icons.memory_rounded,
                      iconColor: const Color(0xFFE8751A),
                      label: s.highAccLabel,
                      sub: s.highAccDesc,
                      value: _s.highAccuracy,
                      onChange: (v) => setState(() => _s = _s.copyWith(highAccuracy: v)),
                      color: const Color(0xFFE8751A),
                    ),
                    _ToggleRow(
                      icon: Icons.save_alt_rounded,
                      iconColor: const Color(0xFFC4561A),
                      label: s.autoSaveLabel,
                      sub: s.autoSaveDesc,
                      value: _s.autoSave,
                      onChange: (v) => setState(() => _s = _s.copyWith(autoSave: v)),
                      color: const Color(0xFFC4561A),
                    ),
                  ]),
                  _buildSection(s.sectionConnect, [
                    _ToggleRow(
                      icon: Icons.wifi_off_rounded,
                      iconColor: const Color(0xFF22C55E),
                      label: s.offlineModeLabel,
                      sub: s.offlineModeDesc,
                      value: _s.offlineMode,
                      onChange: (v) => setState(() => _s = _s.copyWith(offlineMode: v)),
                      color: const Color(0xFF22C55E),
                    ),
                  ]),
                  _buildSection(s.sectionUI, [
                    _ToggleRow(
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFFFBBC04),
                      label: s.notifLabel,
                      sub: s.notifDesc,
                      value: _s.notifications,
                      onChange: (v) => setState(() => _s = _s.copyWith(notifications: v)),
                      color: const Color(0xFFFBBC04),
                    ),
                    _ToggleRow(
                      icon: Icons.dark_mode_outlined,
                      iconColor: const Color(0xFF8B2E00),
                      label: s.darkModeLabel,
                      sub: s.darkModeDesc,
                      value: _s.darkMode,
                      onChange: (v) => setState(() => _s = _s.copyWith(darkMode: v)),
                      color: const Color(0xFF8B2E00),
                    ),
                  ]),
                  _buildActionSection(s),
                  _buildOfflineBanner(s),
                  const SizedBox(height: 88),
                ],
              ),
            ),
          ),
          if (_showLangModal) _buildLanguageModal(s),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader(String name, AppStrings s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8751A), Color(0xFFC4561A), Color(0xFF8B2E00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            bottom: 0,
            right: 0,
            child: Opacity(
              opacity: 0.1,
              child: Text(
                'ĐẠI NAM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.settingsTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(s.settingsSubtitle,
                  style: const TextStyle(color: Color(0xA6FFFFFF), fontSize: 12)),
              const SizedBox(height: 16),
              // Profile card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB347), Color(0xFFE8751A)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.phone_android_rounded, size: 22, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CrackVision',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                          Text('Professional Edition · v2.4.1',
                              style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('PRO',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick stats ──────────────────────────────────────────────
  Widget _buildQuickStats(AppStrings s) {
    final stats = [
      {'icon': Icons.bar_chart_rounded, 'label': s.statsTotal, 'value': '48', 'color': const Color(0xFFE8751A)},
      {'icon': Icons.verified_rounded, 'label': s.statsAccSet, 'value': '97%', 'color': const Color(0xFF22C55E)},
      {'icon': Icons.storage_rounded, 'label': s.statsStorage, 'value': '24MB', 'color': const Color(0xFFC4561A)},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: stats.map((s) {
          final color = s['color'] as Color;
          final icon = s['icon'] as IconData;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: stats.last == s ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Color(0x17C85600), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(height: 4),
                  Text(s['value'] as String,
                      style: const TextStyle(color: Color(0xFF3D1A00), fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(s['label'] as String,
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Language row ─────────────────────────────────────────────
  Widget _buildLanguageRow(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(s.sectionLanguage,
                style: const TextStyle(
                    color: Color(0xFFC4561A), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
          GestureDetector(
            onTap: () {
              _tempLang = ref.read(localeProvider);
              setState(() => _showLangModal = true);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x17C85600), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.language_rounded, size: 20, color: Color(0xFFE8751A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.languageLabel,
                            style: const TextStyle(color: Color(0xFF3D1A00), fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(s.languageDesc,
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFCF9E)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currentFlag, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(_currentNative,
                            style: const TextStyle(
                                color: Color(0xFFE8751A), fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFFFCF9E)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Toggle section ───────────────────────────────────────────
  Widget _buildSection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title,
                style: const TextStyle(
                    color: Color(0xFFC4561A), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x17C85600), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  // ── Action section ───────────────────────────────────────────
  Widget _buildActionSection(AppStrings s) {
    final actions = [
      _ActionRow(icon: Icons.system_update_alt_rounded, iconColor: const Color(0xFFE8751A),
          label: s.updateModel, sub: s.updateModelDesc, onTap: () {}),
      _ActionRow(icon: Icons.delete_outline_rounded, iconColor: const Color(0xFFEF4444),
          label: s.clearHistory, sub: s.clearHistoryDesc,
          onTap: () => _confirmClearHistory(s)),
      _ActionRow(icon: Icons.star_outline_rounded, iconColor: const Color(0xFFFBBC04),
          label: s.rateApp, sub: s.rateAppDesc, onTap: () {}),
      _ActionRow(icon: Icons.help_outline_rounded, iconColor: const Color(0xFF8B2E00),
          label: s.helpSupport, sub: s.helpSupportDesc, onTap: () {}),
      _ActionRow(icon: Icons.info_outline_rounded, iconColor: const Color(0xFF9CA3AF),
          label: s.aboutApp, sub: s.aboutAppDesc, onTap: () {}),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(s.sectionGeneral,
                style: const TextStyle(
                    color: Color(0xFFC4561A), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x17C85600), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Column(children: actions),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x44EF4444), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: ElevatedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(s.logout, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Offline banner ────────────────────────────────────────────
  Widget _buildOfflineBanner(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF0E0), Color(0xFFFFF8F2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFCF9E)),
        ),
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, size: 20, color: Color(0xFFE8751A)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.offlineBannerTitle,
                      style: const TextStyle(color: Color(0xFF7D3A00), fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(s.offlineBannerDesc,
                      style: const TextStyle(color: Color(0xFFC4561A), fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE8751A), Color(0xFFC4561A)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('OFFLINE',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Language modal ────────────────────────────────────────────
  Widget _buildLanguageModal(AppStrings s) {
    return GestureDetector(
      onTap: () => setState(() => _showLangModal = false),
      child: Container(
        color: const Color(0x8C3C0A00),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD4A8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(s.chooseLanguage,
                            style: const TextStyle(
                                color: Color(0xFF3D1A00), fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showLangModal = false),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                              color: Color(0xFFFFF0E0), shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFE8751A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFFFF0E0)),
                ..._langs.map((lang) {
                  final isSelected = _tempLang == lang['code'];
                  return GestureDetector(
                    onTap: () => setState(() => _tempLang = lang['code']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF0E0) : Colors.transparent,
                        border: const Border(bottom: BorderSide(color: Color(0xFFFFF8F2))),
                      ),
                      child: Row(
                        children: [
                          Text(lang['flag']!, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['native']!,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFFE8751A) : const Color(0xFF3D1A00),
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                Text(lang['label']!,
                                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [Color(0xFFE8751A), Color(0xFFC4561A)]),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFE8751A), Color(0xFFC4561A)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x44C85600), blurRadius: 20, offset: Offset(0, 6))
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(localeProvider.notifier).setLocale(_tempLang);
                        setState(() => _showLangModal = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        '${_langs.firstWhere((l) => l['code'] == _tempLang)['flag']} '
                        '${_langs.firstWhere((l) => l['code'] == _tempLang)['native']}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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

  Future<void> _confirmClearHistory(AppStrings s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.clearHistoryConfirm,
            style: const TextStyle(color: Color(0xFF3D1A00), fontWeight: FontWeight.w700)),
        content: Text(s.clearHistoryConfirmDesc,
            style: const TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel, style: const TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.deleteAll, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.cleared),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChange;
  final Color color;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChange,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFFFF5EC))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF3D1A00), fontSize: 13, fontWeight: FontWeight.w600)),
                Text(sub, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _AnimatedToggle(value: value, onChange: onChange, color: color),
        ],
      ),
    );
  }
}

class _AnimatedToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChange;
  final Color color;
  const _AnimatedToggle({required this.value, required this.onChange, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChange(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? color : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, sub;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFFFF5EC))),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Color(0xFF3D1A00), fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(sub, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFFFCF9E)),
          ],
        ),
      ),
    );
  }
}
