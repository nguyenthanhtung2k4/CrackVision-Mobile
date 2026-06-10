import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crackvision/core/router/app_router.dart';
import 'package:crackvision/core/constants/api_endpoints.dart';
import 'package:crackvision/features/history/data/history_repository.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';

class HistoryDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const HistoryDetailScreen({super.key, required this.id});

  @override
  ConsumerState<HistoryDetailScreen> createState() =>
      _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends ConsumerState<HistoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _confAnim;
  ScanResultModel? _item;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _confAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadDetail();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final item =
          await ref.read(historyRepositoryProvider).getHistoryDetail(widget.id);
      if (mounted) {
        setState(() {
          _item = item;
          _loading = false;
        });
        _animCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa kết quả?',
            style: TextStyle(
                color: Color(0xFF3D1A00), fontWeight: FontWeight.w700)),
        content: const Text('Hành động này không thể hoàn tác.',
            style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Hủy', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(historyRepositoryProvider).deleteHistory(widget.id);
      if (mounted) context.go(AppRoutes.history);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8F2),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFFE8751A))),
      );
    }
    if (_error != null || _item == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F2),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFFFCF9E)),
              const SizedBox(height: 12),
              Text(_error ?? 'Không tìm thấy kết quả',
                  style: const TextStyle(color: Color(0xFFC4561A))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.history),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8751A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Quay lại',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final item = _item!;
    final hasCrack = item.hasCrack;
    final mainColor =
        hasCrack ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final severityLabel = hasCrack ? 'NGHIÊM TRỌNG' : 'AN TOÀN';
    final severityBg =
        hasCrack ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              _buildImage(item),
              const SizedBox(height: 16),
              _buildResultCard(
                  item, hasCrack, mainColor, severityLabel, severityBg),
              const SizedBox(height: 12),
              _buildScanDetails(item),
              const SizedBox(height: 12),
              _buildDeleteButton(),
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
            onTap: () => context.go(AppRoutes.history),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: Color(0xFFE8751A)),
          ),
          const Expanded(
            child: Text('Chi tiết quét',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF3D1A00),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          Row(
            children: [
              _CircleBtn(
                  onTap: () {},
                  child: const Icon(Icons.share_outlined,
                      size: 16, color: Color(0xFFE8751A))),
              const SizedBox(width: 8),
              _CircleBtn(
                  onTap: () {},
                  child: const Icon(Icons.download_outlined,
                      size: 16, color: Color(0xFFE8751A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(ScanResultModel item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              item.imagePath != null
                  ? Image.network(
                      ApiEndpoints.imageUrl(item.imagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFFFE0C8),
                        child: const Icon(Icons.image_outlined,
                            size: 64, color: Color(0xFFE8751A)),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFFFE0C8),
                      child: const Icon(Icons.image_outlined,
                          size: 64, color: Color(0xFFE8751A)),
                    ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xA63C0A00)],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 11, color: Color(0xCCFFC878)),
                        SizedBox(width: 4),
                        Text('Vị trí scan',
                            style: TextStyle(
                                color: Color(0xCCFFC878), fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.imageFilename ?? 'Ảnh #${widget.id}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
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

  Widget _buildResultCard(ScanResultModel item, bool hasCrack, Color mainColor,
      String severityLabel, Color severityBg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1AC85600), blurRadius: 16, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('KẾT QUẢ PHÁT HIỆN',
                    style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: severityBg,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(severityLabel,
                      style: TextStyle(
                          color: mainColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
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
                      hasCrack
                          ? Icons.warning_rounded
                          : Icons.check_circle_rounded,
                      size: 26,
                      color: mainColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.meaning,
                          style: const TextStyle(
                              color: Color(0xFF3D1A00),
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      Text('Nguồn: ${item.sourceLabel}',
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Độ tin cậy',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                const Spacer(),
                Text('${(item.confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: mainColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            // Animated confidence bar
            AnimatedBuilder(
              animation: _confAnim,
              builder: (_, __) => LayoutBuilder(builder: (_, c) {
                return Container(
                  height: 10,
                  width: c.maxWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8D0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor:
                          (item.confidence * _confAnim.value).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              mainColor.withValues(alpha: 0.5),
                              mainColor
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.timer_outlined,
                    label: 'Thời gian xử lý',
                    value: item.inferenceTimeSeconds != null
                        ? '${item.inferenceTimeSeconds!.toStringAsFixed(2)}s'
                        : '—',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.access_time_rounded,
                    label: 'Thời gian scan',
                    value: _formatDate(item.createdAt),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanDetails(ScanResultModel item) {
    final rows = [
      ['AI Model', item.sourceLabel],
      ['Thời gian', _formatFull(item.createdAt)],
      ['Scan ID', item.id],
      ['Xác suất dương', '${(item.probPositive * 100).toStringAsFixed(2)}%'],
      ['Ngưỡng', '${(item.threshold * 100).toStringAsFixed(0)}%'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1AC85600), blurRadius: 16, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CHI TIẾT SCAN',
                style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 12),
            ...rows.map((r) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Color(0xFFFFF0E0))),
                  ),
                  child: Row(
                    children: [
                      Text(r[0],
                          style: const TextStyle(
                              color: Color(0xFFC4561A), fontSize: 12)),
                      const Spacer(),
                      Text(r[1],
                          style: const TextStyle(
                              color: Color(0xFF3D1A00),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: _confirmDelete,
        icon: const Icon(Icons.delete_outline_rounded, size: 18),
        label: const Text('Xóa kết quả này',
            style: TextStyle(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEF4444),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 0),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _formatFull(DateTime dt) =>
      '${_formatDate(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Helpers ────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _CircleBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
              color: Color(0xFFFFF0E0), shape: BoxShape.circle),
          child: Center(child: child),
        ),
      );
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5EC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFFE8751A)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 9)),
                  Text(value,
                      style: const TextStyle(
                          color: Color(0xFF3D1A00),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      );
}
