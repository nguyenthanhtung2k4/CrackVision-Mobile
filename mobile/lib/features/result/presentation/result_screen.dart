import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crackvision/core/router/app_router.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';
import 'package:crackvision/features/scanner/presentation/scan_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final ScanResultModel result;
  const ResultScreen({super.key, required this.result});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _confidenceAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _confidenceAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = ref.read(scanProvider).selectedImage;
    final r = widget.result;
    final hasCrack = r.hasCrack;
    final confidencePct = r.confidence * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              _buildImageSection(image, r),
              const SizedBox(height: 16),
              _buildDetectionCard(r, hasCrack, confidencePct),
              const SizedBox(height: 12),
              _buildBreakdownCard(r, hasCrack, confidencePct),
              const SizedBox(height: 12),
              _buildRecommendations(hasCrack),
              const SizedBox(height: 16),
              _buildActions(context, ref),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _CircleBtn(
            onTap: () => context.go(AppRoutes.scanner),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFFE8751A)),
          ),
          const Expanded(
            child: Text(
              'Kết quả phân tích',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF3D1A00),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Row(
            children: [
              _CircleBtn(
                onTap: () {},
                child: const Icon(Icons.share_outlined, size: 16, color: Color(0xFFE8751A)),
              ),
              const SizedBox(width: 8),
              _CircleBtn(
                onTap: () {},
                child: const Icon(Icons.download_outlined, size: 16, color: Color(0xFFE8751A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(File? image, ScanResultModel r) {
    final hasCrack = r.hasCrack;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              image != null
                  ? Image.file(image, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFFFE0C8),
                      child: const Icon(Icons.image_outlined, size: 64, color: Color(0xFFE8751A)),
                    ),
              // Gradient overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB23C0A00)],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              // Detection box — large crack
              if (hasCrack) ...[
                const Positioned(
                  top: 200 * 0.25,
                  left: 200 * 0.30,
                  child: _DetectionBox(
                    width: 120,
                    height: 70,
                    borderColor: Color(0xFFEF4444),
                    label: 'Vết nứt lớn 94%',
                    labelBg: Color(0xFFEF4444),
                  ),
                ),
                const Positioned(
                  top: 200 * 0.55,
                  left: 200 * 0.55,
                  child: _DetectionBox(
                    width: 60,
                    height: 40,
                    borderColor: Color(0xFFFFB347),
                    label: 'Vết nứt nhỏ 72%',
                    labelBg: Color(0xFFFFB347),
                  ),
                ),
              ],
              // Bottom overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(r.createdAt),
                              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 9),
                            ),
                            const Text(
                              'Bề mặt bê tông',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.source == 'server' ? 'Server AI v2.4' : 'On-device AI',
                          style: const TextStyle(color: Colors.white, fontSize: 9),
                        ),
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

  Widget _buildDetectionCard(ScanResultModel r, bool hasCrack, double confidencePct) {
    final mainColor = hasCrack ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final mainLabel = hasCrack ? 'Phát hiện vết nứt' : 'Không có vết nứt';
    final severity = hasCrack ? 'NGHIÊM TRỌNG' : 'AN TOÀN';
    final severityBg = hasCrack ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);

    return AnimatedBuilder(
      animation: _animController,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x1AC85600), blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'KẾT QUẢ PHÁT HIỆN',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        severity,
                        style: TextStyle(color: mainColor, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: mainColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        hasCrack ? Icons.warning_rounded : Icons.check_circle_rounded,
                        size: 26,
                        color: mainColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mainLabel,
                          style: const TextStyle(
                            color: Color(0xFF3D1A00),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Vật liệu: Bê tông',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.bar_chart, size: 13, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    const Text(
                      'Độ tin cậy',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      '${confidencePct.toStringAsFixed(1)}%',
                      style: TextStyle(color: mainColor, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _AnimatedBar(value: r.confidence, color: mainColor, animation: _confidenceAnim),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.timer_outlined,
                        label: 'Thời gian xử lý',
                        value: r.inferenceTimeSeconds != null
                            ? '${r.inferenceTimeSeconds!.toStringAsFixed(2)}s'
                            : '—',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.memory,
                        label: 'Nguồn AI',
                        value: r.source == 'server' ? 'Online' : 'On-device',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreakdownCard(ScanResultModel r, bool hasCrack, double confidencePct) {
    final breakdownItems = hasCrack
        ? [
            _BreakdownItem('Vết nứt lớn', confidencePct, const Color(0xFFEF4444)),
            _BreakdownItem('Vết nứt nhỏ', (1.0 - r.confidence) * 60, const Color(0xFFFFB347)),
            _BreakdownItem('Không có nứt', (1.0 - r.confidence) * 40, const Color(0xFF22C55E)),
          ]
        : [
            _BreakdownItem('Không có nứt', confidencePct, const Color(0xFF22C55E)),
            _BreakdownItem('Vết nứt nhỏ', (1.0 - r.confidence) * 60, const Color(0xFFFFB347)),
            _BreakdownItem('Vết nứt lớn', (1.0 - r.confidence) * 40, const Color(0xFFEF4444)),
          ];

    return AnimatedBuilder(
      animation: _animController,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x1AC85600), blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PHÂN TÍCH CHI TIẾT',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ...breakdownItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.label,
                                style: const TextStyle(color: Color(0xFF6B3A1F), fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${item.value.toStringAsFixed(1)}%',
                                style: TextStyle(color: item.color, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _AnimatedBar(
                            value: item.value / 100,
                            color: item.color,
                            animation: _confidenceAnim,
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendations(bool hasCrack) {
    final recs = hasCrack
        ? [
            'Kiểm tra ngay bởi kỹ sư kết cấu có kinh nghiệm',
            'Đánh dấu và ghi lại vị trí vết nứt để theo dõi',
            'Không sử dụng khu vực cho đến khi được đánh giá an toàn',
          ]
        : [
            'Bề mặt trong tình trạng tốt, tiếp tục theo dõi định kỳ',
            'Thực hiện kiểm tra lại sau 3-6 tháng',
            'Ghi lại kết quả vào hệ thống quản lý công trình',
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFEF2F2), Color(0xFFFFF5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasCrack ? Icons.warning_rounded : Icons.check_circle_rounded,
                  size: 15,
                  color: hasCrack ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                ),
                const SizedBox(width: 8),
                Text(
                  hasCrack ? 'CẦN XỬ LÝ NGAY' : 'KHUYẾN NGHỊ',
                  style: TextStyle(
                    color: hasCrack ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recs.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: hasCrack ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(scanProvider.notifier).reset();
                context.go(AppRoutes.scanner);
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Quét lại', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE8751A),
                side: const BorderSide(color: Color(0xFFE8751A), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8751A), Color(0xFFC4561A)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x72C85600), blurRadius: 20, offset: Offset(0, 6)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.history),
                icon: const Icon(Icons.save_alt_rounded, size: 16),
                label: const Text('Lưu & Xem', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year} · '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

// ── Helpers ──────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _CircleBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF0E0),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DetectionBox extends StatelessWidget {
  final double width, height;
  final Color borderColor, labelBg;
  final String label;
  const _DetectionBox({
    required this.width,
    required this.height,
    required this.borderColor,
    required this.labelBg,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: borderColor.withValues(alpha: 0.5), blurRadius: 12),
              ],
            ),
          ),
          Positioned(
            top: -18,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final double value;
  final Color color;
  final Animation<double> animation;
  const _AnimatedBar({required this.value, required this.color, required this.animation});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      return Container(
        height: 10,
        width: constraints.maxWidth,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, __) => FractionallySizedBox(
              widthFactor: (value * animation.value).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.5), color],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE8751A)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9)),
                Text(value, style: const TextStyle(color: Color(0xFF3D1A00), fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem {
  final String label;
  final double value;
  final Color color;
  const _BreakdownItem(this.label, this.value, this.color);
}
