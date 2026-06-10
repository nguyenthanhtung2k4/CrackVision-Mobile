import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crackvision/core/router/app_router.dart';
import 'package:crackvision/core/constants/api_endpoints.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';
import 'package:crackvision/features/history/presentation/history_provider.dart';
import 'package:crackvision/core/l10n/locale_provider.dart';
import 'package:crackvision/core/l10n/app_strings.dart';
import 'package:crackvision/core/theme/theme_provider.dart';

// ── Filter types ──────────────────────────────────────────────
enum _CrackFilter { all, large, small, none }

enum _DateFilter { all, today, week, month }

enum _ConfFilter { all, high, medium, low }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  _CrackFilter _crack = _CrackFilter.all;
  _DateFilter _date = _DateFilter.all;
  _ConfFilter _conf = _ConfFilter.all;
  bool _showFilterModal = false;

  // Temp state for modal
  _DateFilter _tempDate = _DateFilter.all;
  _ConfFilter _tempConf = _ConfFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ScanResultModel> _filtered(List<ScanResultModel> items) {
    final q = _searchCtrl.text.toLowerCase();
    return items.where((item) {
      // Search
      if (q.isNotEmpty &&
          !item.meaning.toLowerCase().contains(q) &&
          !(item.imageFilename ?? '').toLowerCase().contains(q)) {
        return false;
      }
      // Crack filter
      if (_crack == _CrackFilter.large && item.predLabel != 'CRACK') {
        return false;
      }
      if (_crack == _CrackFilter.none && item.predLabel != 'NO_CRACK') {
        return false;
      }
      if (_crack == _CrackFilter.small) {
        return false;
      } // server doesn't distinguish small yet
      // Date filter
      final now = DateTime.now();
      if (_date == _DateFilter.today && !_sameDay(item.createdAt, now)) {
        return false;
      }
      if (_date == _DateFilter.week &&
          now.difference(item.createdAt).inDays > 7) {
        return false;
      }
      if (_date == _DateFilter.month &&
          now.difference(item.createdAt).inDays > 30) {
        return false;
      }
      // Confidence filter
      final pct = item.confidence * 100;
      if (_conf == _ConfFilter.high && pct <= 90) return false;
      if (_conf == _ConfFilter.medium && (pct < 70 || pct > 90)) return false;
      if (_conf == _ConfFilter.low && pct >= 70) return false;
      return true;
    }).toList();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Map<String, List<ScanResultModel>> _grouped(List<ScanResultModel> items) {
    final map = <String, List<ScanResultModel>>{};
    for (final item in items) {
      final key =
          '${item.createdAt.day.toString().padLeft(2, '0')}/${item.createdAt.month.toString().padLeft(2, '0')}/${item.createdAt.year}';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);
    final s = AppStrings.of(ref.watch(localeProvider));
    final isDark = ref.watch(themeProvider);
    final filtered = _filtered(state.items);
    final grouped = _grouped(filtered);
    final total = state.items.length;
    final cracks = state.items.where((i) => i.hasCrack).length;
    final clean = total - cracks;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF5EC),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(total, cracks, clean, s, isDark),
                Expanded(
                  child: state.status == HistoryStatus.loading &&
                          state.items.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFE8751A)))
                      : state.status == HistoryStatus.error &&
                              state.items.isEmpty
                          ? _buildError(s)
                          : _buildList(grouped, filtered, s, isDark),
                ),
              ],
            ),
          ),
          if (_showFilterModal) _buildFilterModal(s),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader(
      int total, int cracks, int clean, AppStrings s, bool isDark) {
    final headerBg = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final titleColor =
        isDark ? const Color(0xFFF5F5F5) : const Color(0xFF3D1A00);
    final deleteBg = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFFFF0E0);
    final searchBg = isDark ? const Color(0xFF333333) : const Color(0xFFFFF5EC);
    final searchBorder =
        isDark ? const Color(0xFF4A4A4A) : const Color(0xFFFFE0C8);

    return Container(
      color: headerBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.historyTitle,
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    Text('$total ${s.langCode == 'en' ? 'scans' : 'lần quét'}',
                        style: const TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 11)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _confirmClearAll,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: deleteBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Color(0xFFE8751A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _StatBadge(
                  label: s.historyTotalLabel,
                  value: total,
                  color: const Color(0xFFE8751A),
                  isDark: isDark),
              const SizedBox(width: 8),
              _StatBadge(
                  label: s.historyCrackLabel,
                  value: cracks,
                  color: const Color(0xFFEF4444),
                  isDark: isDark),
              const SizedBox(width: 8),
              _StatBadge(
                  label: s.historyCleanLabel,
                  value: clean,
                  color: const Color(0xFF22C55E),
                  isDark: isDark),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: searchBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: searchBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    size: 16, color: Color(0xFFE8751A)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: titleColor, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: s.searchHint,
                      hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 13),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _tempDate = _date;
                    _tempConf = _conf;
                    setState(() => _showFilterModal = true);
                  },
                  child: const Icon(Icons.filter_list_rounded,
                      size: 16, color: Color(0xFFE8751A)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                    label: s.filterAll,
                    active: _crack == _CrackFilter.all,
                    onTap: () => setState(() => _crack = _CrackFilter.all),
                    isDark: isDark),
                const SizedBox(width: 8),
                _FilterPill(
                    label: s.filterLarge,
                    active: _crack == _CrackFilter.large,
                    onTap: () => setState(() => _crack = _CrackFilter.large),
                    isDark: isDark),
                const SizedBox(width: 8),
                _FilterPill(
                    label: s.filterSmall,
                    active: _crack == _CrackFilter.small,
                    onTap: () => setState(() => _crack = _CrackFilter.small),
                    isDark: isDark),
                const SizedBox(width: 8),
                _FilterPill(
                    label: s.filterSafe,
                    active: _crack == _CrackFilter.none,
                    onTap: () => setState(() => _crack = _CrackFilter.none),
                    isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────
  Widget _buildList(Map<String, List<ScanResultModel>> grouped,
      List<ScanResultModel> filtered, AppStrings s, bool isDark) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: Color(0xFFFFCF9E)),
            const SizedBox(height: 12),
            Text(s.noResults,
                style: const TextStyle(color: Color(0xFFC4561A), fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFE8751A),
      onRefresh: () => ref.read(historyProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    color: Color(0xFFC4561A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...entry.value.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HistoryCard(
                    item: e.value,
                    index: e.key,
                    onTap: () =>
                        context.push('${AppRoutes.history}/${e.value.id}'),
                    onDelete: () =>
                        ref.read(historyProvider.notifier).delete(e.value.id),
                    isDark: isDark,
                  ),
                );
              }),
              const SizedBox(height: 6),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final s = AppStrings.of(ref.read(localeProvider));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.deleteAllTitle,
            style: const TextStyle(
                color: Color(0xFF3D1A00), fontWeight: FontWeight.w700)),
        content: Text(s.deleteAllDesc,
            style: const TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel,
                style: const TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                Text(s.deleteAll, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(historyProvider.notifier).clearAll();
    }
  }

  Widget _buildError(AppStrings s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 48, color: Color(0xFFFFCF9E)),
          const SizedBox(height: 12),
          Text(s.noHistory,
              style: const TextStyle(color: Color(0xFFC4561A), fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(historyProvider.notifier).load(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8751A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.retry, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Filter Modal ─────────────────────────────────────────────
  Widget _buildFilterModal(AppStrings s) {
    final isDark = ref.read(themeProvider);
    final modalBg = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final titleColor =
        isDark ? const Color(0xFFF5F5F5) : const Color(0xFF3D1A00);
    final closeBg = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFFFF0E0);
    final dividerColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFFFF0E0);

    return GestureDetector(
      onTap: () => setState(() => _showFilterModal = false),
      child: Container(
        color: const Color(0x8C3C0A00),
        child: Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {}, // block dismiss when tapping inside
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: modalBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modal header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(s.filterTitle,
                              style: TextStyle(
                                  color: titleColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showFilterModal = false),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: closeBg, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: Color(0xFFE8751A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: dividerColor),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date section
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 16, color: Color(0xFFE8751A)),
                            const SizedBox(width: 8),
                            Text(s.filterByDate,
                                style: TextStyle(
                                    color: titleColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ModalPill(
                                label: s.dateAll,
                                active: _tempDate == _DateFilter.all,
                                onTap: () =>
                                    setState(() => _tempDate = _DateFilter.all),
                                isDark: isDark),
                            _ModalPill(
                                label: s.dateToday,
                                active: _tempDate == _DateFilter.today,
                                onTap: () => setState(
                                    () => _tempDate = _DateFilter.today),
                                isDark: isDark),
                            _ModalPill(
                                label: s.dateWeek,
                                active: _tempDate == _DateFilter.week,
                                onTap: () => setState(
                                    () => _tempDate = _DateFilter.week),
                                isDark: isDark),
                            _ModalPill(
                                label: s.dateMonth,
                                active: _tempDate == _DateFilter.month,
                                onTap: () => setState(
                                    () => _tempDate = _DateFilter.month),
                                isDark: isDark),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Confidence section
                        Row(
                          children: [
                            const Icon(Icons.trending_up_rounded,
                                size: 16, color: Color(0xFFE8751A)),
                            const SizedBox(width: 8),
                            Text(s.filterByConf,
                                style: TextStyle(
                                    color: titleColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ModalPill(
                                label: s.confAll,
                                active: _tempConf == _ConfFilter.all,
                                onTap: () =>
                                    setState(() => _tempConf = _ConfFilter.all),
                                isDark: isDark),
                            _ModalPill(
                                label: s.confHigh,
                                active: _tempConf == _ConfFilter.high,
                                onTap: () => setState(
                                    () => _tempConf = _ConfFilter.high),
                                isDark: isDark),
                            _ModalPill(
                                label: s.confMed,
                                active: _tempConf == _ConfFilter.medium,
                                onTap: () => setState(
                                    () => _tempConf = _ConfFilter.medium),
                                isDark: isDark),
                            _ModalPill(
                                label: s.confLow,
                                active: _tempConf == _ConfFilter.low,
                                onTap: () =>
                                    setState(() => _tempConf = _ConfFilter.low),
                                isDark: isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: dividerColor),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() {
                              _tempDate = _DateFilter.all;
                              _tempConf = _ConfFilter.all;
                            }),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE8751A),
                              side: const BorderSide(
                                  color: Color(0xFFE8751A), width: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(s.clearFilter,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFE8751A),
                                Color(0xFFC4561A)
                              ]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x44C85600),
                                    blurRadius: 12,
                                    offset: Offset(0, 4))
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => setState(() {
                                _date = _tempDate;
                                _conf = _tempConf;
                                _showFilterModal = false;
                              }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(s.apply,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool isDark;
  const _StatBadge(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: color.withValues(alpha: isDark ? 0.25 : 0.15)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;
  const _FilterPill(
      {required this.label,
      required this.active,
      required this.onTap,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final inactiveBg =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFFFF0E0);
    final inactiveBorder =
        isDark ? const Color(0xFF4A4A4A) : const Color(0xFFFFCF9E);
    final inactiveText =
        isDark ? const Color(0xFFE8751A) : const Color(0xFFC4561A);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8751A) : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? const Color(0xFFE8751A) : inactiveBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : inactiveText,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ModalPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;
  const _ModalPill(
      {required this.label,
      required this.active,
      required this.onTap,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final inactiveBg =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFFFF0E0);
    final inactiveBorder =
        isDark ? const Color(0xFF4A4A4A) : const Color(0xFFFFCF9E);
    final inactiveText =
        isDark ? const Color(0xFFE8751A) : const Color(0xFFC4561A);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8751A) : inactiveBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? const Color(0xFFE8751A) : inactiveBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : inactiveText,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ScanResultModel item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDark;
  const _HistoryCard(
      {required this.item,
      required this.index,
      required this.onTap,
      required this.onDelete,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasCrack = item.hasCrack;
    final color = hasCrack ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final icon = hasCrack ? Icons.warning_rounded : Icons.check_circle_rounded;
    final cardBg = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final titleColor =
        isDark ? const Color(0xFFF5F5F5) : const Color(0xFF3D1A00);
    final pctColor = isDark ? const Color(0xFFFFB080) : const Color(0xFF6B3A1F);
    final dotBorder = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x17C85600), blurRadius: 10, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: item.imagePath != null
                        ? Image.network(
                            ApiEndpoints.imageUrl(item.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color:
                                  color.withValues(alpha: isDark ? 0.18 : 0.1),
                              child: Icon(Icons.image_outlined,
                                  size: 28,
                                  color: color.withValues(alpha: 0.5)),
                            ),
                          )
                        : Container(
                            color: color.withValues(alpha: isDark ? 0.18 : 0.1),
                            child: Icon(Icons.image_outlined,
                                size: 28, color: color.withValues(alpha: 0.5)),
                          ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: dotBorder, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.imageFilename ?? 'Ảnh #${index + 1}',
                    style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(icon, size: 11, color: color),
                      const SizedBox(width: 4),
                      Text(item.meaning,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Mini confidence bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: item.confidence,
                            minHeight: 4,
                            backgroundColor: isDark
                                ? const Color(0xFF4A3A30)
                                : const Color(0xFFFFE0C8),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(item.confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: pctColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(item.createdAt),
                  style:
                      const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                ),
                const SizedBox(height: 8),
                Icon(Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFFFFCF9E)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
