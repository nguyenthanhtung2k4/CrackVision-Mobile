import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crackvision/core/router/app_router.dart';
import 'package:crackvision/features/auth/presentation/auth_provider.dart';
import 'package:crackvision/features/scanner/presentation/scan_provider.dart';
import 'package:crackvision/core/l10n/locale_provider.dart';
import 'package:crackvision/core/l10n/app_strings.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _orbitCtrl;
  late Animation<double> _heroAnim;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _heroAnim = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroCtrl.forward();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    ref.read(scanProvider.notifier).selectImage(File(picked.path));
    if (mounted) context.push(AppRoutes.scanner);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final s = AppStrings.of(ref.watch(localeProvider));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(user?.fullName ?? (s.homeGreeting == 'Hello' ? 'friend' : 'bạn'), s),
              _buildHeroPreview(),
              _buildActionButtons(s),
              _buildQuickTips(s),
              _buildOfflineBanner(s),
              _buildRecentActivity(s),
              const SizedBox(height: 88),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader(String name, AppStrings s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
          // Rotating orbit rings
          ..._buildOrbitRings(),
          // "ĐẠI NAM" watermark
          const Positioned(
            bottom: -4,
            right: 0,
            child: Opacity(
              opacity: 0.16,
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
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.homeTagline,
                          style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.homeGreeting}, $name!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Offline badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 12, color: Color(0xFF4ADE80)),
                        SizedBox(width: 4),
                        Text('Offline AI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Logout
                  GestureDetector(
                    onTap: () => ref.read(authProvider.notifier).logout(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats strip
              Row(
                children: [
                  _StatChip(value: '12', label: s.statsToday),
                  _StatChip(value: '97.3%', label: s.statsAccuracy),
                  _StatChip(value: '8+', label: s.statsMaterials),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrbitRings() {
    return [80, 130, 180, 230, 280, 330].asMap().entries.map((e) {
      final size = e.value.toDouble();
      final i = e.key;
      return Positioned(
        top: -20.0 + i * 8,
        right: -30.0 + i * 4,
        child: AnimatedBuilder(
          animation: _orbitCtrl,
          builder: (_, __) => Transform.rotate(
            angle: _orbitCtrl.value * 2 * 3.14159,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: (0.12 - i * 0.01).clamp(0, 1)),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ── Hero Preview ────────────────────────────────────────────
  Widget _buildHeroPreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AnimatedBuilder(
        animation: _heroAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, 20 * (1 - _heroAnim.value)),
          child: Opacity(opacity: _heroAnim.value, child: child),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: const Color(0xFFFFD4A8),
                  child: const Icon(Icons.image_search_rounded, size: 64, color: Color(0xFFE8751A)),
                ),
                // Dark gradient overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x1A5A1400), Color(0xBF5A1400)],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
                // Corner scan frame
                Center(
                  child: Container(
                    width: 120,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFFB347), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Stack(
                      children: [
                        _Corner(top: true, left: true),
                        _Corner(top: true, left: false),
                        _Corner(top: false, left: true),
                        _Corner(top: false, left: false),
                      ],
                    ),
                  ),
                ),
                // Bottom: crack label + confidence
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xE6C85600),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(radius: 4, backgroundColor: Colors.white),
                              SizedBox(width: 6),
                              Text('VẾT NỨT LỚN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('94.2% Độ tin cậy',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
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

  // ── Action Buttons ──────────────────────────────────────────
  Widget _buildActionButtons(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.startScanning,
            style: const TextStyle(
              color: Color(0xFF6B3A1F),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8751A), Color(0xFFC4561A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shadowColor: const Color(0x72C85600),
                  icon: Icons.camera_alt_rounded,
                  title: s.scanCamera,
                  subtitle: s.scanCameraDesc,
                  onTap: () => context.push(AppRoutes.scanner),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B2E00), Color(0xFF5C1900)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shadowColor: const Color(0x725A1400),
                  icon: Icons.photo_library_rounded,
                  title: s.scanGallery,
                  subtitle: s.scanGalleryDesc,
                  onTap: _pickFromGallery,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick Tips ──────────────────────────────────────────────
  Widget _buildQuickTips(AppStrings s) {
    final tips = [
      _TipItem(icon: Icons.wb_sunny_rounded, color: const Color(0xFFE8751A), title: s.tipLightTitle, desc: s.tipLightDesc),
      _TipItem(icon: Icons.straighten_rounded, color: const Color(0xFFC4561A), title: s.tipDistTitle, desc: s.tipDistDesc),
      _TipItem(icon: Icons.center_focus_strong_rounded, color: const Color(0xFF0F9D58), title: s.tipSteadyTitle, desc: s.tipSteadyDesc),
      _TipItem(icon: Icons.bolt_rounded, color: const Color(0xFFFBBC04), title: s.tipLensTitle, desc: s.tipLensDesc),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                s.quickTips,
                style: const TextStyle(color: Color(0xFF6B3A1F), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFFF0E0), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 10, color: Color(0xFFE8751A)),
                    const SizedBox(width: 2),
                    Text(s.bestAccuracy, style: const TextStyle(color: Color(0xFFE8751A), fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: tips.map((t) => _TipCard(tip: t)).toList(),
          ),
        ],
      ),
    );
  }

  // ── Offline Banner ──────────────────────────────────────────
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0BC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 20, color: Color(0xFFE8751A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.offlineTitle,
                      style: const TextStyle(color: Color(0xFF7D3A00), fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(s.offlineDesc,
                      style: const TextStyle(color: Color(0xFFC4561A), fontSize: 10)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE8751A), Color(0xFFC4561A)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(s.offlineTag, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent Activity ─────────────────────────────────────────
  Widget _buildRecentActivity(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                s.recentActivity,
                style: const TextStyle(color: Color(0xFF6B3A1F), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(AppRoutes.history),
                child: Text(s.seeAll, style: const TextStyle(color: Color(0xFFE8751A), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RecentItem(
            icon: Icons.camera_alt_rounded,
            name: s.langCode == 'en' ? 'Concrete Wall' : 'Tường bê tông',
            status: s.langCode == 'en' ? 'Large Crack' : 'Vết nứt lớn',
            confidence: 94,
            time: s.minutesAgo,
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 8),
          _RecentItem(
            icon: Icons.camera_alt_rounded,
            name: s.langCode == 'en' ? 'Steel Beam' : 'Dầm thép',
            status: s.langCode == 'en' ? 'No Crack' : 'Không có nứt',
            confidence: 98,
            time: s.hourAgo,
            color: const Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String value, label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 10)),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top, left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: Color(0xFFE8751A), width: 2) : BorderSide.none,
            bottom: top ? BorderSide.none : const BorderSide(color: Color(0xFFE8751A), width: 2),
            left: left ? const BorderSide(color: Color(0xFFE8751A), width: 2) : BorderSide.none,
            right: left ? BorderSide.none : const BorderSide(color: Color(0xFFE8751A), width: 2),
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(3) : Radius.zero,
            topRight: top && !left ? const Radius.circular(3) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(3) : Radius.zero,
            bottomRight: !top && !left ? const Radius.circular(3) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final LinearGradient gradient;
  final Color shadowColor;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionCard({
    required this.gradient,
    required this.shadowColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: shadowColor, blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 26, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            Text(subtitle, style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _TipItem {
  final IconData icon;
  final Color color;
  final String title, desc;
  const _TipItem({required this.icon, required this.color, required this.title, required this.desc});
}

class _TipCard extends StatelessWidget {
  final _TipItem tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14C85600), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tip.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tip.icon, size: 18, color: tip.color),
          ),
          const SizedBox(height: 8),
          Text(tip.title, style: const TextStyle(color: Color(0xFF3D1A00), fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(tip.desc, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9, height: 1.4)),
        ],
      ),
    );
  }
}

class _RecentItem extends StatelessWidget {
  final IconData icon;
  final String name, status, time;
  final int confidence;
  final Color color;
  const _RecentItem({
    required this.icon,
    required this.name,
    required this.status,
    required this.time,
    required this.confidence,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14C85600), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Color(0xFF3D1A00), fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(status, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Text(time, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          Text('$confidence%', style: const TextStyle(color: Color(0xFF3D1A00), fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
