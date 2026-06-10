import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crackvision/core/network/api_client.dart';
import 'package:crackvision/core/constants/api_endpoints.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';

class HistoryRepository {
  static const _boxName = 'history_cache';
  final Dio _dio;

  HistoryRepository(this._dio);

  Future<List<ScanResultModel>> getHistory(
      {int page = 1, int pageSize = 20}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.history,
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final items = (res.data['items'] as List)
          .map((j) => ScanResultModel.fromJson(j as Map<String, dynamic>))
          .toList();
      await _cacheHistory(items);
      return items;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return _getCachedHistory();
      }
      rethrow;
    } catch (_) {
      return _getCachedHistory();
    }
  }

  Future<ScanResultModel> getHistoryDetail(String id) async {
    final res = await _dio.get('${ApiEndpoints.history}/$id');
    return ScanResultModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteHistory(String id) async {
    await _dio.delete('${ApiEndpoints.history}/$id');
    final box = await _openBox();
    await box.delete(id);
  }

  Future<void> clearHistory() async {
    await _dio.delete(ApiEndpoints.history);
    final box = await _openBox();
    await box.clear();
  }

  Future<void> updateNote(String id, String note) async {
    await _dio.patch(
      '${ApiEndpoints.history}/$id/note',
      data: {'note': note},
    );
  }

  Future<List<ScanResultModel>> _getCachedHistory() async {
    final box = await _openBox();
    return box.values
        .map((j) =>
            ScanResultModel.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _cacheHistory(List<ScanResultModel> items) async {
    final box = await _openBox();
    await box.clear();
    final Map<String, Map<String, dynamic>> toSave = {};
    for (final item in items) {
      toSave[item.id] = {
        'id': item.id,
        'pred_label': item.predLabel,
        'meaning': item.meaning,
        'prob_positive': item.probPositive,
        'confidence': item.confidence,
        'threshold': item.threshold,
        'inference_time_seconds': item.inferenceTimeSeconds,
        'image_filename': item.imageFilename,
        'source': item.source,
        'note': item.note,
        'is_synced': item.isSynced,
        'created_at': item.createdAt.toIso8601String(),
      };
    }
    await box.putAll(toSave);
  }

  Future<Box> _openBox() => Hive.openBox(_boxName);
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(dioProvider));
});
