import 'dart:io' show File;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crackvision/core/router/app_router.dart';
import 'package:crackvision/core/theme/app_theme.dart';
import 'package:crackvision/features/scanner/presentation/scan_provider.dart';
import 'package:crackvision/features/settings/presentation/settings_provider.dart';
import 'package:crackvision/shared/widgets/app_snack_bar.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  late final AnimationController _scanLineCtrl;
  late final Animation<double> _scanLineAnim;
  bool _flash = false;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scanLineAnim =
        CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut);
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
      final size = await picked.length();
      if (size > 10 * 1024 * 1024) {
        if (mounted) {
          _showError('Ảnh quá lớn. Vui lòng chọn ảnh dưới 10MB.');
        }
        return;
      }
      ref.read(scanProvider.notifier).selectImage(picked);
    } catch (_) {
      if (mounted) {
        _showError('Không thể truy cập ảnh. Kiểm tra quyền truy cập.');
      }
    }
  }

  Future<void> _analyze() async {
    _scanLineCtrl.repeat(reverse: true);
    await ref.read(scanProvider.notifier).analyze();
    _scanLineCtrl.stop();
    _scanLineCtrl.reset();
    if (!mounted) return;
    final s = ref.read(scanProvider);
    if (s.status == ScanStatus.success && s.result != null) {
      if (ref.read(appSettingsProvider).notifications) {
        final message = s.result!.hasCrack
            ? 'Đã phân tích xong: phát hiện vết nứt.'
            : 'Đã phân tích xong: bề mặt an toàn.';
        AppSnackBar.success(context, message);
      }
      context.push(AppRoutes.result, extra: s.result);
    }
  }

  void _showError(String msg) => AppSnackBar.error(context, msg);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanProvider);
    final isLoading = state.status == ScanStatus.loading;
    final hasImage = state.selectedImage != null;

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
          _buildBackground(state),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: hasImage ? 0.20 : 0.08),
                  Colors.black.withValues(alpha: 0.72),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, hasImage),
                Expanded(
                  child: _buildScannerBody(state, isLoading, hasImage),
                ),
                _buildBottomControls(state, isLoading, hasImage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(ScanState state) {
    final xFile = state.selectedImage;
    if (xFile != null) {
      final color = _flash ? Colors.white.withValues(alpha: 0.38) : null;
      const blendMode = BlendMode.lighten;
      if (kIsWeb) {
        return Image.network(
          xFile.path,
          fit: BoxFit.cover,
          color: color,
          colorBlendMode: blendMode,
        );
      }
      return Image.file(
        File(xFile.path),
        fit: BoxFit.cover,
        color: color,
        colorBlendMode: blendMode,
      );
    }
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF140600), Color(0xFF2A0E00), Color(0xFF070403)],
        ),
      ),
      child: _ScannerBackdrop(),
    );
  }

  Widget _buildTopBar(BuildContext context, bool hasImage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Quay lại',
            onTap: () => context.go(AppRoutes.home),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.crisis_alert_rounded,
                      color: AppColors.primary, size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasImage ? 'Ảnh đã sẵn sàng' : 'Quét vết nứt',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: hasImage
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFFFB347),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _GlassIconButton(
            icon: _flash ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            tooltip: 'Flash',
            active: _flash,
            onTap: () => setState(() => _flash = !_flash),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerBody(ScanState state, bool isLoading, bool hasImage) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameWidth = math.min(constraints.maxWidth - 44, 340.0);
        final width = math.max(frameWidth, 260.0);
        final height = width * 0.74;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Viewfinder(
                  width: width,
                  height: height,
                  hasImage: hasImage,
                  isLoading: isLoading,
                  animation: _scanLineAnim,
                ),
                const SizedBox(height: 18),
                _ScanHint(hasImage: hasImage, isLoading: isLoading),
                if (hasImage || isLoading) ...[
                  const SizedBox(height: 14),
                  _ScannerPipeline(isLoading: isLoading),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls(ScanState state, bool isLoading, bool hasImage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: Color(0xFFFFC878)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'JPEG/PNG tối đa 10MB. Nếu mất mạng, app tự chuyển sang AI trên thiết bị.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFFFD7A3),
                      fontSize: 10,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _BottomToolButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Thư viện',
                  onTap:
                      isLoading ? null : () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 14),
              _CaptureButton(
                isLoading: isLoading,
                hasImage: hasImage,
                onTap: isLoading
                    ? null
                    : hasImage
                        ? _analyze
                        : () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _BottomToolButton(
                  icon:
                      hasImage ? Icons.close_rounded : Icons.camera_alt_rounded,
                  label: hasImage ? 'Đổi ảnh' : 'Camera',
                  onTap: isLoading
                      ? null
                      : hasImage
                          ? () => ref.read(scanProvider.notifier).reset()
                          : () => _pickImage(ImageSource.camera),
                ),
              ),
            ],
          ),
          if (state.status == ScanStatus.error && state.error != null) ...[
            const SizedBox(height: 14),
            _ScannerError(
              message: state.error!,
              onClose: () => ref.read(scanProvider.notifier).reset(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScannerBackdrop extends StatelessWidget {
  const _ScannerBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScannerBackdropPainter());
  }
}

class _ScannerBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final crackPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.20)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.18)
      ..lineTo(size.width * 0.35, size.height * 0.31)
      ..lineTo(size.width * 0.29, size.height * 0.43)
      ..lineTo(size.width * 0.45, size.height * 0.56)
      ..lineTo(size.width * 0.39, size.height * 0.72);
    canvas.drawPath(path, crackPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Viewfinder extends StatelessWidget {
  final double width;
  final double height;
  final bool hasImage;
  final bool isLoading;
  final Animation<double> animation;

  const _Viewfinder({
    required this.width,
    required this.height,
    required this.hasImage,
    required this.isLoading,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final cornerColor = isLoading ? const Color(0xFFFFB347) : Colors.white;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: hasImage ? 0.04 : 0.16),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
          ),
          if (!hasImage)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_rounded,
                        color: Colors.white, size: 28),
                    SizedBox(height: 8),
                    Text(
                      'Đưa bề mặt vào khung',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isLoading)
            AnimatedBuilder(
              animation: animation,
              builder: (_, __) => Positioned(
                top: 14 + animation.value * (height - 30),
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFFFF7A1A),
                        Color(0xFFFFD28A),
                        Color(0xFFFF7A1A),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.75),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ..._buildCorners(cornerColor),
          Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners(Color color) {
    const size = 34.0;
    const thickness = 3.2;
    return [
      Positioned(
        top: 0,
        left: 0,
        child: _Corner(
          color: color,
          size: size,
          t: thickness,
          top: true,
          left: true,
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: _Corner(
          color: color,
          size: size,
          t: thickness,
          top: true,
          left: false,
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: _Corner(
          color: color,
          size: size,
          t: thickness,
          top: false,
          left: true,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: _Corner(
          color: color,
          size: size,
          t: thickness,
          top: false,
          left: false,
        ),
      ),
    ];
  }
}

class _ScanHint extends StatelessWidget {
  final bool hasImage;
  final bool isLoading;

  const _ScanHint({required this.hasImage, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final text = isLoading
        ? 'AI đang phân tích bề mặt...'
        : hasImage
            ? 'Nhấn nút phân tích để chạy mô hình nhận diện.'
            : 'Chụp ảnh mới hoặc chọn ảnh bề mặt từ thư viện.';
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLoading
                ? Icons.auto_awesome_rounded
                : hasImage
                    ? Icons.task_alt_rounded
                    : Icons.photo_camera_rounded,
            color: const Color(0xFFFFC878),
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerPipeline extends StatelessWidget {
  final bool isLoading;
  const _ScannerPipeline({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final steps = [
      const _PipelineStep(Icons.image_search_rounded, 'Input', true),
      const _PipelineStep(Icons.high_quality_rounded, 'Quality', true),
      _PipelineStep(Icons.memory_rounded, 'AI model', isLoading),
      const _PipelineStep(Icons.fact_check_rounded, 'Report', false),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: steps
          .map((step) => _PipelineChip(step: step, active: step.active))
          .toList(),
    );
  }
}

class _PipelineStep {
  final IconData icon;
  final String label;
  final bool active;
  const _PipelineStep(this.icon, this.label, this.active);
}

class _PipelineChip extends StatelessWidget {
  final _PipelineStep step;
  final bool active;
  const _PipelineChip({required this.step, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.22)
            : Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(step.icon,
              color: active ? const Color(0xFFFFD7A3) : Colors.white54,
              size: 13),
          const SizedBox(width: 5),
          Text(
            step.label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final bool isLoading;
  final bool hasImage;
  final VoidCallback? onTap;

  const _CaptureButton({
    required this.isLoading,
    required this.hasImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isLoading || hasImage
              ? const LinearGradient(
                  colors: [Color(0xFFFF7A1A), Color(0xFFD84D0F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFE8D0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: (isLoading || hasImage ? AppColors.primary : Colors.white)
                  .withValues(alpha: 0.30),
              blurRadius: 26,
              spreadRadius: 3,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.7,
                  ),
                )
              : Icon(
                  hasImage
                      ? Icons.travel_explore_rounded
                      : Icons.camera_alt_rounded,
                  color: hasImage ? Colors.white : AppColors.primary,
                  size: 30,
                ),
        ),
      ),
    );
  }
}

class _BottomToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BottomToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.44),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool active;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.primary.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.34),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Icon(
            icon,
            color: active ? const Color(0xFFFFD7A3) : Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ScannerError({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.crackPositive.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.crackPositive.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.crackPositive, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close_rounded,
                color: Colors.white70, size: 18),
          ),
        ],
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

  const _Corner({
    required this.color,
    required this.size,
    required this.t,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          thickness: t,
          top: top,
          left: left,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top;
  final bool left;

  _CornerPainter({
    required this.color,
    required this.thickness,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const r = 8.0;
    final w = size.width;
    final h = size.height;

    if (top && left) {
      canvas.drawLine(const Offset(r, 0), Offset(w, 0), paint);
      canvas.drawLine(const Offset(0, r), Offset(0, h), paint);
      canvas.drawArc(
        const Rect.fromLTWH(0, 0, r * 2, r * 2),
        -math.pi,
        math.pi / 2,
        false,
        paint,
      );
    } else if (top && !left) {
      canvas.drawLine(const Offset(0, 0), Offset(w - r, 0), paint);
      canvas.drawLine(Offset(w, r), Offset(w, h), paint);
      canvas.drawArc(
        Rect.fromLTWH(w - r * 2, 0, r * 2, r * 2),
        -math.pi / 2,
        math.pi / 2,
        false,
        paint,
      );
    } else if (!top && left) {
      canvas.drawLine(const Offset(0, 0), Offset(0, h - r), paint);
      canvas.drawLine(Offset(r, h), Offset(w, h), paint);
      canvas.drawArc(
        Rect.fromLTWH(0, h - r * 2, r * 2, r * 2),
        math.pi,
        math.pi / 2,
        false,
        paint,
      );
    } else {
      canvas.drawLine(Offset(w, 0), Offset(w, h - r), paint);
      canvas.drawLine(Offset(0, h), Offset(w - r, h), paint);
      canvas.drawArc(
        Rect.fromLTWH(w - r * 2, h - r * 2, r * 2, r * 2),
        0,
        math.pi / 2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => oldDelegate.color != color;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final guidePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width * 0.62,
          height: size.height * 0.42,
        ),
        const Radius.circular(18),
      ),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
