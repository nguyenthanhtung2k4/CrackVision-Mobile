import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crackvision/core/router/app_router.dart';
import 'package:crackvision/core/theme/app_theme.dart';
import 'package:crackvision/features/scanner/presentation/scan_provider.dart';
import 'package:crackvision/shared/widgets/app_snack_bar.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;
  bool _flash = false;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(_scanLineCtrl);
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (picked == null) return;
      final file = File(picked.path);
      final size = await file.length();
      if (size > 10 * 1024 * 1024) {
        if (mounted) _showError('Ảnh quá lớn. Vui lòng chọn ảnh dưới 10MB.');
        return;
      }
      ref.read(scanProvider.notifier).selectImage(file);
    } catch (_) {
      if (mounted) _showError('Không thể truy cập ảnh. Kiểm tra quyền truy cập.');
    }
  }

  Future<void> _analyze() async {
    _scanLineCtrl.repeat();
    await ref.read(scanProvider.notifier).analyze();
    _scanLineCtrl.stop();
    if (!mounted) return;
    final s = ref.read(scanProvider);
    if (s.status == ScanStatus.success && s.result != null) {
      context.push(AppRoutes.result, extra: s.result);
    }
  }

  void _showError(String msg) => AppSnackBar.error(context, msg);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanProvider);
    final isLoading = state.status == ScanStatus.loading;
    final isComplete = state.status == ScanStatus.success;

    ref.listen<ScanState>(scanProvider, (_, next) {
      if (next.status == ScanStatus.error && next.error != null) {
        _showError(next.error!);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image / camera feed ──
          _buildBackground(state),

          // ── Dark overlay ──
          Container(color: Colors.black.withValues(alpha: 0.3)),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(child: _buildViewfinder(state, isLoading, isComplete)),
                _buildBottomControls(state, isLoading),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(ScanState state) {
    if (state.selectedImage != null) {
      return Image.file(
        state.selectedImage!,
        fit: BoxFit.cover,
        color: _flash ? Colors.white.withValues(alpha: 0.4) : null,
        colorBlendMode: _flash ? BlendMode.lighten : null,
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A00), Color(0xFF2D1200), Color(0xFF1A0A00)],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _CircleButton(
            onTap: () => context.go(AppRoutes.home),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xB3C85600),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'Quét vết nứt',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          _CircleButton(
            onTap: () => setState(() => _flash = !_flash),
            color: _flash ? Colors.orange.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.45),
            child: Icon(
              _flash ? Icons.flash_on : Icons.flash_off,
              color: _flash ? Colors.amber : Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder(ScanState state, bool isLoading, bool isComplete) {
    final cornerColor = isLoading ? Colors.amber : Colors.white;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 280,
            height: 210,
            child: Stack(
              children: [
                // Frame border
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ),
                // Grid overlay
                CustomPaint(
                  size: const Size(280, 210),
                  painter: _GridPainter(),
                ),
                // Scan line animation
                if (isLoading)
                  AnimatedBuilder(
                    animation: _scanLineAnim,
                    builder: (_, __) => Positioned(
                      top: _scanLineAnim.value * 200,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Colors.transparent,
                            Color(0xFFE8751A),
                            Color(0xFFFFB347),
                            Color(0xFFE8751A),
                            Colors.transparent,
                          ]),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.7),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Corner brackets
                ..._buildCorners(cornerColor),
                // Center dot
                Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                // Complete overlay
                if (isComplete)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x995A1400),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Text(
              isLoading
                  ? 'Đang phân tích bằng AI...'
                  : state.selectedImage == null
                      ? 'Chụp ảnh hoặc chọn từ thư viện'
                      : 'Nhấn "Phân tích" để bắt đầu',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: 10),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Tag('Bê tông'),
                SizedBox(width: 6),
                _Tag('Đang xử lý...'),
                SizedBox(width: 6),
                _Tag('AI v2.4'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCorners(Color color) {
    const size = 28.0;
    const thickness = 3.0;
    return [
      Positioned(top: 0, left: 0, child: _Corner(color: color, size: size, t: thickness, top: true, left: true)),
      Positioned(top: 0, right: 0, child: _Corner(color: color, size: size, t: thickness, top: true, left: false)),
      Positioned(bottom: 0, left: 0, child: _Corner(color: color, size: size, t: thickness, top: false, left: true)),
      Positioned(bottom: 0, right: 0, child: _Corner(color: color, size: size, t: thickness, top: false, left: false)),
    ];
  }

  Widget _buildBottomControls(ScanState state, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 13, color: Color(0xCCFFC878)),
                SizedBox(width: 6),
                Text(
                  'Hỗ trợ JPEG, PNG • Tối đa 10MB • Online + Offline AI',
                  style: TextStyle(color: Color(0xCCFFC878), fontSize: 10),
                ),
              ],
            ),
          ),
          // Button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flip camera (left)
              _CircleButton(
                onTap: () {},
                size: 50,
                child: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 22),
              ),
              // Main capture / analyze button (center)
              GestureDetector(
                onTap: isLoading
                    ? null
                    : state.selectedImage == null
                        ? () => _pickImage(ImageSource.camera)
                        : _analyze,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isLoading
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFE8751A), Color(0xFFC4561A)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Color(0xFFFFE8D0)],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: isLoading
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 28),
                ),
              ),
              // Flash indicator (right)
              GestureDetector(
                onTap: () => setState(() => _flash = !_flash),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _flash
                        ? Colors.amber.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: _flash ? const Color(0xFFFFB347) : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _flash ? 'BẬT' : 'TẮT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Flash',
                        style: TextStyle(color: Colors.white54, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Error message
          if (state.status == ScanStatus.error && state.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.crackPositive.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.crackPositive.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.crackPositive, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.error!, style: const TextStyle(color: Colors.white, fontSize: 12))),
                  GestureDetector(
                    onTap: () => ref.read(scanProvider.notifier).reset(),
                    child: const Icon(Icons.close, color: Colors.white54, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double size;
  final Color? color;

  const _CircleButton({required this.child, this.onTap, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.black.withValues(alpha: 0.45),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Color color;
  final double size;
  final double t;
  final bool top;
  final bool left;

  const _Corner({required this.color, required this.size, required this.t, required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(color: color, thickness: t, top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top;
  final bool left;

  _CornerPainter({required this.color, required this.thickness, required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = thickness..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const r = 6.0;
    final w = size.width;
    final h = size.height;

    if (top && left) {
      canvas.drawLine(const Offset(r, 0), Offset(w, 0), paint);
      canvas.drawLine(const Offset(0, r), Offset(0, h), paint);
      canvas.drawArc(const Rect.fromLTWH(0, 0, r * 2, r * 2), -3.14, 3.14 / 2, false, paint);
    } else if (top && !left) {
      canvas.drawLine(const Offset(0, 0), Offset(w - r, 0), paint);
      canvas.drawLine(Offset(w, r), Offset(w, h), paint);
      canvas.drawArc(Rect.fromLTWH(w - r * 2, 0, r * 2, r * 2), -3.14 / 2, 3.14 / 2, false, paint);
    } else if (!top && left) {
      canvas.drawLine(const Offset(0, 0), Offset(0, h - r), paint);
      canvas.drawLine(Offset(r, h), Offset(w, h), paint);
      canvas.drawArc(Rect.fromLTWH(0, h - r * 2, r * 2, r * 2), 3.14, 3.14 / 2, false, paint);
    } else {
      canvas.drawLine(Offset(w, 0), Offset(w, h - r), paint);
      canvas.drawLine(Offset(0, h), Offset(w - r, h), paint);
      canvas.drawArc(Rect.fromLTWH(w - r * 2, h - r * 2, r * 2, r * 2), 0, 3.14 / 2, false, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter o) => o.color != color;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xBFC85600),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
