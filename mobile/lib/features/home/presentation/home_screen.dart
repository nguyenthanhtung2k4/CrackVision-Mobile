import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crackvision/core/l10n/app_strings.dart';
import 'package:crackvision/core/l10n/locale_provider.dart';
import 'package:crackvision/core/router/app_router.dart';
import 'package:crackvision/core/theme/app_theme.dart';
import 'package:crackvision/core/theme/theme_provider.dart';
import 'package:crackvision/features/auth/presentation/auth_provider.dart';
import 'package:crackvision/features/history/presentation/history_provider.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';
import 'package:crackvision/features/scanner/presentation/scan_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _scanCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _introAnim;
  late final Animation<double> _pulseAnim;
  StreamSubscription? _connectivitySub;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _introAnim =
        CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutCubic);
    _pulseAnim = Tween<double>(begin: 0.98, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _introCtrl.forward();
    _hydrateConnectivity();
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_handleConnectivity);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _introCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _hydrateConnectivity() async {
    try {
      _handleConnectivity(await Connectivity().checkConnectivity());
    } catch (_) {
      if (mounted) setState(() => _isOffline = false);
    }
  }

  void _handleConnectivity(Object? result) {
    final offline = _isOfflineResult(result);
    if (!mounted) return;
    setState(() => _isOffline = offline);
  }

  bool _isOfflineResult(Object? result) {
    bool hasNetwork(Iterable<ConnectivityResult> values) {
      return values.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
    }

    if (result is Iterable<ConnectivityResult>) return !hasNetwork(result);
    if (result is ConnectivityResult) {
      return !hasNetwork([result]);
    }
    return false;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatRelativeTime(DateTime createdAt, AppStrings s) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return s.langCode == 'en' ? '${m}m ago' : '$m phút trước';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours.clamp(1, 23);
      return s.langCode == 'en' ? '${h}h ago' : '$h giờ trước';
    }
    final d = math.max(diff.inDays, 1);
    return s.langCode == 'en' ? '${d}d ago' : '$d ngày trước';
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (picked == null || !mounted) return;
    ref.read(scanProvider.notifier).selectImage(picked);
    context.push(AppRoutes.scanner);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final history = ref.watch(historyProvider);
    final s = AppStrings.of(ref.watch(localeProvider));
    final isDark = ref.watch(themeProvider);
    final name = user?.fullName ?? (s.langCode == 'en' ? 'friend' : 'bạn');
    final items = [...history.items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final total = items.length;
    final todayCount =
        items.where((i) => _isSameDay(i.createdAt, DateTime.now())).length;
    final crackCount = items.where((i) => i.hasCrack).length;
    final safeCount = total - crackCount;
    final cleanRate = total == 0 ? 0.0 : safeCount / total;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0D0B) : const Color(0xFFF6F0EA),
      body: FadeTransition(
        opacity: _introAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _HeroPanel(
                name: name,
                isDark: isDark,
                isOffline: _isOffline,
                total: total,
                todayCount: todayCount,
                crackCount: crackCount,
                cleanRate: cleanRate,
                onLogout: () => ref.read(authProvider.notifier).logout(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 104),
              sliver: SliverList.list(
                children: [
                  _ScanActions(
                    isDark: isDark,
                    s: s,
                    onCamera: () => context.push(AppRoutes.scanner),
                    onGallery: _pickFromGallery,
                    scanCtrl: _scanCtrl,
                    pulseAnim: _pulseAnim,
                  ),
                  const SizedBox(height: 22),
                  _QuickTipsGrid(isDark: isDark, s: s),
                  if (_isOffline) ...[
                    const SizedBox(height: 22),
                    _OfflineBanner(isDark: isDark, s: s),
                  ],
                  const SizedBox(height: 22),
                  _RecentActivity(
                    isDark: isDark,
                    s: s,
                    items: items.take(4).toList(),
                    formatter: _formatRelativeTime,
                    onSeeAll: () => context.go(AppRoutes.history),
                    onOpen: (item) =>
                        context.push('${AppRoutes.history}/${item.id}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String name;
  final bool isDark;
  final bool isOffline;
  final int total;
  final int todayCount;
  final int crackCount;
  final double cleanRate;
  final VoidCallback onLogout;

  const _HeroPanel({
    required this.name,
    required this.isDark,
    required this.isOffline,
    required this.total,
    required this.todayCount,
    required this.crackCount,
    required this.cleanRate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF7A1A), Color(0xFFD84D0F), Color(0xFF7C2500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _HeaderPatternPainter()),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _BrandMark(),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CrackVision',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'AI crack inspection',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _HeaderChip(
                    icon: isOffline
                        ? Icons.wifi_off_rounded
                        : Icons.cloud_done_rounded,
                    label: isOffline ? 'Offline' : 'Online',
                  ),
                  const SizedBox(width: 8),
                  _IconGlassButton(
                    icon: Icons.logout_rounded,
                    onTap: onLogout,
                    tooltip: 'Đăng xuất',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Xin chào, $name',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Quét bề mặt, phân tích rủi ro và lưu lịch sử kiểm tra trong một luồng làm việc.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: compact
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 20) / 3,
                        child: _HeroStat(
                          icon: Icons.document_scanner_rounded,
                          value: '$total',
                          label: 'Tổng lượt',
                        ),
                      ),
                      SizedBox(
                        width: compact
                            ? (constraints.maxWidth - 10) / 2
                            : (constraints.maxWidth - 20) / 3,
                        child: _HeroStat(
                          icon: Icons.today_rounded,
                          value: '$todayCount',
                          label: 'Hôm nay',
                        ),
                      ),
                      SizedBox(
                        width: compact
                            ? (constraints.maxWidth - 10) / 2
                            : (constraints.maxWidth - 20) / 3,
                        child: _HeroStat(
                          icon: Icons.warning_amber_rounded,
                          value: '$crackCount',
                          label: 'Có nứt',
                          accent: crackCount > 0,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _HeroHealthBar(cleanRate: cleanRate),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child:
          const Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 22),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _IconGlassButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool accent;

  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent
            ? const Color(0xFFFF4D2E).withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent
              ? const Color(0xFFFFD2C4).withValues(alpha: 0.42)
              : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHealthBar extends StatelessWidget {
  final double cleanRate;
  const _HeroHealthBar({required this.cleanRate});

  @override
  Widget build(BuildContext context) {
    final pct = (cleanRate * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_rounded,
                  color: Color(0xFFBBF7D0), size: 16),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Tỷ lệ bề mặt an toàn',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: Color(0xFFBBF7D0),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: cleanRate.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanActions extends StatelessWidget {
  final bool isDark;
  final AppStrings s;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final AnimationController scanCtrl;
  final Animation<double> pulseAnim;

  const _ScanActions({
    required this.isDark,
    required this.s,
    required this.onCamera,
    required this.onGallery,
    required this.scanCtrl,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'SCAN HUB',
          title: s.startScanning,
          subtitle: 'Camera hoặc thư viện đều đi qua cùng luồng AI.',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _PrimaryScanCard(
          label: s.scanCamera,
          sublabel: 'Mở camera và căn khung bề mặt cần kiểm tra',
          onTap: onCamera,
          scanCtrl: scanCtrl,
          pulseAnim: pulseAnim,
        ),
        const SizedBox(height: 10),
        _SecondaryScanCard(
          label: s.scanGallery,
          sublabel: s.scanGalleryDesc,
          onTap: onGallery,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _PrimaryScanCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final AnimationController scanCtrl;
  final Animation<double> pulseAnim;

  const _PrimaryScanCard({
    required this.label,
    required this.sublabel,
    required this.onTap,
    required this.scanCtrl,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7A1A), Color(0xFFE05212)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedBuilder(
                    animation: scanCtrl,
                    builder: (context, child) {
                      final x = scanCtrl.value * 1.35 - 0.2;
                      return Transform.translate(
                        offset: Offset(MediaQuery.sizeOf(context).width * x, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 68,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.10),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: pulseAnim,
                      builder: (_, child) =>
                          Transform.scale(scale: pulseAnim.value, child: child),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.34),
                          ),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 25),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sublabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xD9FFFFFF),
                              fontSize: 11,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryScanCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final bool isDark;

  const _SecondaryScanCard({
    required this.label,
    required this.sublabel,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1B1815) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTipsGrid extends StatelessWidget {
  final bool isDark;
  final AppStrings s;

  const _QuickTipsGrid({required this.isDark, required this.s});

  @override
  Widget build(BuildContext context) {
    final tips = [
      _TipData(
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFFF97316),
        title: s.tipLightTitle,
        desc: s.tipLightDesc,
      ),
      _TipData(
        icon: Icons.straighten_rounded,
        color: const Color(0xFF2563EB),
        title: s.tipDistTitle,
        desc: s.tipDistDesc,
      ),
      _TipData(
        icon: Icons.center_focus_strong_rounded,
        color: const Color(0xFF16A34A),
        title: s.tipSteadyTitle,
        desc: s.tipSteadyDesc,
      ),
      _TipData(
        icon: Icons.cleaning_services_rounded,
        color: const Color(0xFFF59E0B),
        title: s.tipLensTitle,
        desc: s.tipLensDesc,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'PHOTO QA',
          title: s.quickTips,
          subtitle: 'Giảm lỗi ảnh mờ, bóng tối và sai khoảng cách.',
          isDark: isDark,
          trailing: const _TinyBadge(label: 'Pro tips'),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 360 ? 1 : 2;
            final gap = columns == 1 ? 0.0 : 10.0;
            final width = (constraints.maxWidth - gap) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: tips
                  .map((tip) => SizedBox(
                        width: width,
                        child: _TipCard(tip: tip, isDark: isDark),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TipData {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _TipData({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
}

class _TipCard extends StatelessWidget {
  final _TipData tip;
  final bool isDark;
  const _TipCard({required this.tip, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1B1815) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textDark;
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A2A20) : const Color(0xFFFFE5CC),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tip.color.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(tip.icon, color: tip.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip.desc,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final bool isDark;
  final AppStrings s;
  const _OfflineBanner({required this.isDark, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF24170D), const Color(0xFF17110C)]
              : [const Color(0xFFFFF4E8), const Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF4A2D18) : const Color(0xFFFFD7B0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.memory_rounded,
                color: Color(0xFF22C55E), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.offlineTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s.offlineDesc,
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
          const _TinyBadge(label: 'OFFLINE'),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final bool isDark;
  final AppStrings s;
  final List<ScanResultModel> items;
  final String Function(DateTime, AppStrings) formatter;
  final VoidCallback onSeeAll;
  final ValueChanged<ScanResultModel> onOpen;

  const _RecentActivity({
    required this.isDark,
    required this.s,
    required this.items,
    required this.formatter,
    required this.onSeeAll,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'RECENT',
          title: s.recentActivity,
          subtitle: 'Kết quả mới nhất, trạng thái rõ ràng và dễ đọc.',
          isDark: isDark,
          trailing: TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: AppColors.primary,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.seeAll,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _EmptyRecentCard(isDark: isDark)
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecentCard(
                item: item,
                time: formatter(item.createdAt, s),
                langCode: s.langCode,
                isDark: isDark,
                onTap: () => onOpen(item),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyRecentCard extends StatelessWidget {
  final bool isDark;
  const _EmptyRecentCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1815) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3A2A20) : const Color(0xFFFFE5CC),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.document_scanner_outlined,
                color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chưa có lượt kiểm tra nào. Hãy bắt đầu bằng camera hoặc thư viện ảnh.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textMid,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final ScanResultModel item;
  final String time;
  final String langCode;
  final bool isDark;
  final VoidCallback onTap;

  const _RecentCard({
    required this.item,
    required this.time,
    required this.langCode,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCrack = item.hasCrack;
    final statusColor =
        hasCrack ? AppColors.crackPositive : AppColors.crackNegative;
    final titleColor = isDark ? Colors.white : AppColors.textDark;
    final statusLabel = hasCrack
        ? (langCode == 'en' ? 'Crack detected' : 'Có vết nứt')
        : (langCode == 'en' ? 'No crack' : 'An toàn');
    final confidence = item.confidence.clamp(0.0, 1.0);
    final confidencePct = (confidence * 100).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1815) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF3A2A20) : const Color(0xFFFFE5CC),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  hasCrack
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_rounded,
                  color: statusColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.imageFilename ??
                          (langCode == 'en' ? 'Scan result' : 'Kết quả quét'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _StatusPill(label: statusLabel, color: statusColor),
                        _StatusPill(
                          label: item.sourceShortLabel,
                          color: AppColors.primary,
                        ),
                        _MutedPill(label: time),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: confidence,
                              minHeight: 5,
                              backgroundColor: isDark
                                  ? const Color(0xFF332B26)
                                  : const Color(0xFFF0E4DA),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$confidencePct%',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppColors.textMid,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : const Color(0xFFD8B89A),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget? trailing;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : AppColors.textDark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  const _TinyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MutedPill extends StatelessWidget {
  final String label;
  const _MutedPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF9CA3AF).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    final crackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (double x = -size.height; x < size.width; x += 52) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), linePaint);
    }

    final path = Path()
      ..moveTo(size.width * 0.78, 8)
      ..lineTo(size.width * 0.73, size.height * 0.17)
      ..lineTo(size.width * 0.81, size.height * 0.28)
      ..lineTo(size.width * 0.76, size.height * 0.41)
      ..lineTo(size.width * 0.84, size.height * 0.58);
    canvas.drawPath(path, crackPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
