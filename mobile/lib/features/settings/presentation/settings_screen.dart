import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crackvision/core/l10n/app_strings.dart';
import 'package:crackvision/core/l10n/locale_provider.dart';
import 'package:crackvision/core/theme/app_theme.dart';
import 'package:crackvision/core/theme/theme_provider.dart';
import 'package:crackvision/features/auth/presentation/auth_provider.dart';
import 'package:crackvision/features/history/presentation/history_provider.dart';
import 'package:crackvision/features/settings/presentation/settings_provider.dart';
import 'package:crackvision/shared/widgets/app_snack_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showLangModal = false;
  String _tempLang = 'vi';

  static const _langs = [
    {'code': 'vi', 'mark': 'VI', 'native': 'Tiếng Việt', 'label': 'Vietnamese'},
    {'code': 'en', 'mark': 'EN', 'native': 'English', 'label': 'English'},
  ];

  String get _currentLang => ref.read(localeProvider);
  String get _currentMark => _langs.firstWhere((l) => l['code'] == _currentLang,
      orElse: () => _langs[0])['mark']!;
  String get _currentNative =>
      _langs.firstWhere((l) => l['code'] == _currentLang,
          orElse: () => _langs[0])['native']!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final lang = ref.watch(localeProvider);
    final isDark = ref.watch(themeProvider);
    final settings = ref.watch(appSettingsProvider);
    final history = ref.watch(historyProvider);
    final s = AppStrings.of(lang);
    final totalScans = history.items.length;
    final cracks = history.items.where((item) => item.hasCrack).length;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF11100E) : const Color(0xFFFFF5EC),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 104),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(
                    name: user?.fullName ??
                        (lang == 'en' ? 'User' : 'Người dùng'),
                    s: s,
                  ),
                  _buildQuickStats(
                    isDark: isDark,
                    settings: settings,
                    totalScans: totalScans,
                    cracks: cracks,
                  ),
                  _buildLanguageRow(s, isDark),
                  _buildSection(
                    title: s.sectionDetection,
                    isDark: isDark,
                    children: [
                      _ToggleRow(
                        icon: Icons.memory_rounded,
                        iconColor: AppColors.primary,
                        label: s.highAccLabel,
                        sub:
                            'Bật: ưu tiên server AI. Tắt: ưu tiên AI trên thiết bị khi có thể.',
                        value: settings.highAccuracy,
                        onChange: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setHighAccuracy(v),
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                      _ToggleRow(
                        icon: Icons.save_alt_rounded,
                        iconColor: AppColors.primaryMid,
                        label: s.autoSaveLabel,
                        sub:
                            'Bật để lưu vào lịch sử backend. Tắt thì chỉ xem kết quả tạm thời.',
                        value: settings.autoSave,
                        onChange: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setAutoSave(v),
                        color: AppColors.primaryMid,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  _buildSection(
                    title: s.sectionConnect,
                    isDark: isDark,
                    children: [
                      _ToggleRow(
                        icon: Icons.wifi_off_rounded,
                        iconColor: AppColors.crackNegative,
                        label: s.offlineModeLabel,
                        sub:
                            'Cho phép fallback sang AI trên thiết bị khi mất mạng hoặc server lỗi.',
                        value: settings.offlineMode,
                        onChange: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setOfflineMode(v),
                        color: AppColors.crackNegative,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  _buildSection(
                    title: s.sectionUI,
                    isDark: isDark,
                    children: [
                      _ToggleRow(
                        icon: Icons.notifications_outlined,
                        iconColor: const Color(0xFFFBBC04),
                        label: s.notifLabel,
                        sub:
                            'Hiển thị thông báo trong app khi phân tích xong. Chưa phải push notification hệ thống.',
                        value: settings.notifications,
                        onChange: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setNotifications(v),
                        color: const Color(0xFFFBBC04),
                        isDark: isDark,
                      ),
                      _ToggleRow(
                        icon: Icons.dark_mode_outlined,
                        iconColor: AppColors.primaryDark,
                        label: s.darkModeLabel,
                        sub: 'Lưu lựa chọn giao diện trên thiết bị.',
                        value: isDark,
                        onChange: (v) =>
                            ref.read(themeProvider.notifier).set(v),
                        color: AppColors.primaryDark,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  _buildActionSection(s, isDark),
                  _buildSettingsRealityCard(isDark),
                ],
              ),
            ),
          ),
          if (_showLangModal) _buildLanguageModal(s),
        ],
      ),
    );
  }

  Widget _buildHeader({required String name, required AppStrings s}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF7A1A), Color(0xFFD85612), Color(0xFF8B2E00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: 12,
            child: Text(
              'CRACKVISION',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.10),
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.settingsTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.settingsSubtitle,
                style: const TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.30)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB347), Color(0xFFFF7A1A)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.phone_android_rounded,
                          color: Colors.white, size: 23),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CrackVision',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$name · v2.4.1',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'LOCAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

  Widget _buildQuickStats({
    required bool isDark,
    required AppSettings settings,
    required int totalScans,
    required int cracks,
  }) {
    final stats = [
      _SettingsStat(
        icon: Icons.bar_chart_rounded,
        label: 'Tổng scan',
        value: '$totalScans',
        color: AppColors.primary,
      ),
      _SettingsStat(
        icon: settings.highAccuracy
            ? Icons.cloud_done_rounded
            : Icons.memory_rounded,
        label: 'Chế độ AI',
        value: settings.highAccuracy ? 'Server' : 'Nhanh',
        color: AppColors.crackNegative,
      ),
      _SettingsStat(
        icon: Icons.warning_amber_rounded,
        label: 'Có nứt',
        value: '$cracks',
        color: AppColors.crackPositive,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: stats
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: item == stats.last ? 0 : 8),
                  child: _StatCard(item: item, isDark: isDark),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLanguageRow(AppStrings s, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1F1A16) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final iconBg = isDark ? const Color(0xFF33241A) : AppColors.backgroundCream;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(s.sectionLanguage),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _tempLang = ref.read(localeProvider);
                setState(() => _showLangModal = true);
              },
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3A2A20) : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.language_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.languageLabel,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Lưu ngôn ngữ trên thiết bị',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentMark,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentNative,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(title),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1A16) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF3A2A20) : AppColors.border,
              ),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(AppStrings s, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(s.sectionGeneral),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1A16) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF3A2A20) : AppColors.border,
              ),
            ),
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.system_update_alt_rounded,
                  iconColor: AppColors.primary,
                  label: s.updateModel,
                  sub: 'Chưa có API cập nhật model từ backend.',
                  onTap: () => AppSnackBar.info(
                    context,
                    'Model hiện được đóng gói trong app/server. Chưa có backend cập nhật model từ Settings.',
                  ),
                  isDark: isDark,
                ),
                _ActionRow(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppColors.crackPositive,
                  label: s.clearHistory,
                  sub: 'Xóa lịch sử trên backend và cache local.',
                  onTap: () => _confirmClearHistory(s),
                  isDark: isDark,
                ),
                _ActionRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.textMuted,
                  label: s.aboutApp,
                  sub: 'CrackVision v2.4.1',
                  onTap: _showAbout,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.crackPositive.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                s.logout,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRealityCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF24170D) : AppColors.backgroundCream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF4A2D18) : AppColors.borderLight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.fact_check_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Các cài đặt này được lưu trên thiết bị. Auto-save tác động tới API scan; Offline mode và High accuracy tác động trực tiếp tới luồng phân tích.',
                style: TextStyle(
                  color: isDark ? const Color(0xFFFFD7A3) : AppColors.textMid,
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageModal(AppStrings s) {
    final isDark = ref.read(themeProvider);
    final modalBg = isDark ? const Color(0xFF1F1A16) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textDark;
    final closeBg =
        isDark ? const Color(0xFF35261C) : AppColors.backgroundCream;

    return GestureDetector(
      onTap: () => setState(() => _showLangModal = false),
      child: Container(
        color: const Color(0x8C3C0A00),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: modalBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF5A4A40)
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.chooseLanguage,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showLangModal = false),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: closeBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._langs.map((lang) {
                  final isSelected = _tempLang == lang['code'];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _tempLang = lang['code']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                lang['mark']!,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang['native']!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.primary
                                          : titleColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    lang['label']!,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 22),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(localeProvider.notifier).setLocale(_tempLang);
                      setState(() => _showLangModal = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _langs
                          .firstWhere((l) => l['code'] == _tempLang)['native']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
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
        title: Text(
          s.clearHistoryConfirm,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          s.clearHistoryConfirmDesc,
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              s.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crackPositive,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              s.deleteAll,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(historyProvider.notifier).clearAll();
      if (mounted) AppSnackBar.success(context, s.cleared);
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          'Không thể xóa lịch sử. Kiểm tra kết nối backend.',
        );
      }
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'CrackVision',
      applicationVersion: '2.4.1',
      applicationIcon: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.crisis_alert_rounded, color: Colors.white),
      ),
      children: const [
        Text('Ứng dụng phát hiện vết nứt bề mặt bằng AI.'),
      ],
    );
  }
}

class _SettingsStat {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SettingsStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _SettingsStat item;
  final bool isDark;

  const _StatCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1A16) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A2A20) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(item.icon, size: 18, color: item.color),
          const SizedBox(height: 5),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryMid,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChange;
  final Color color;
  final bool isDark;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChange,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF302821) : AppColors.backgroundLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
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

  const _AnimatedToggle({
    required this.value,
    required this.onChange,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChange(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? color : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
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
  final String label;
  final String sub;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sub,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? const Color(0xFF302821)
                    : AppColors.backgroundLight,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? Colors.white38 : AppColors.borderLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
