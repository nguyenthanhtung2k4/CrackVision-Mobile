import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crackvision/features/history/data/history_repository.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';

enum HistoryStatus { initial, loading, success, error }

class HistoryState {
  final HistoryStatus status;
  final List<ScanResultModel> items;
  final String? error;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.items = const [],
    this.error,
  });

  HistoryState copyWith({HistoryStatus? status, List<ScanResultModel>? items, String? error}) =>
      HistoryState(
        status: status ?? this.status,
        items: items ?? this.items,
        error: error,
      );
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final HistoryRepository _repo;

  HistoryNotifier(this._repo) : super(const HistoryState());

  Future<void> load() async {
    state = state.copyWith(status: HistoryStatus.loading);
    try {
      final items = await _repo.getHistory();
      state = state.copyWith(status: HistoryStatus.success, items: items);
    } catch (e) {
      state = state.copyWith(status: HistoryStatus.error, error: e.toString());
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repo.deleteHistory(id);
      state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
    } catch (_) {}
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref.watch(historyRepositoryProvider));
});
