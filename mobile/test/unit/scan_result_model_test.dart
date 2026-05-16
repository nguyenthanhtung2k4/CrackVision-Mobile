import 'package:flutter_test/flutter_test.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';

void main() {
  group('ScanResultModel', () {
    // ── Factory constructor ────────────────────────────────────────

    test('fromJson parses Positive result correctly', () {
      final json = {
        'id': 'abc-123',
        'pred_label': 'CRACK',
        'meaning': 'Có vết nứt',
        'prob_positive': 0.87,
        'confidence': 0.87,
        'threshold': 0.5,
        'inference_time_seconds': 0.042,
        'image_filename': 'wall.jpg',
        'source': 'server',
        'note': null,
        'is_synced': true,
        'created_at': '2026-05-16T10:00:00.000Z',
      };
      final model = ScanResultModel.fromJson(json);

      expect(model.id, 'abc-123');
      expect(model.predLabel, 'CRACK');
      expect(model.meaning, 'Có vết nứt');
      expect(model.probPositive, closeTo(0.87, 0.001));
      expect(model.confidence, closeTo(0.87, 0.001));
      expect(model.threshold, closeTo(0.5, 0.001));
      expect(model.inferenceTimeSeconds, closeTo(0.042, 0.0001));
      expect(model.imageFilename, 'wall.jpg');
      expect(model.source, 'server');
      expect(model.isSynced, true);
    });

    test('fromJson parses Negative result correctly', () {
      final json = {
        'id': 'xyz-456',
        'pred_label': 'NO_CRACK',
        'meaning': 'Không có vết nứt',
        'prob_positive': 0.15,
        'confidence': 0.85,
        'threshold': 0.5,
        'inference_time_seconds': null,
        'image_filename': null,
        'source': 'tflite',
        'note': 'ghi chú test',
        'is_synced': false,
        'created_at': '2026-05-15T08:30:00.000Z',
      };
      final model = ScanResultModel.fromJson(json);

      expect(model.predLabel, 'NO_CRACK');
      expect(model.inferenceTimeSeconds, isNull);
      expect(model.imageFilename, isNull);
      expect(model.source, 'tflite');
      expect(model.note, 'ghi chú test');
      expect(model.isSynced, false);
    });

    test('fromJson defaults source to "server" when null', () {
      final json = {
        'id': 's1',
        'pred_label': 'CRACK',
        'meaning': 'Có vết nứt',
        'prob_positive': 0.9,
        'confidence': 0.9,
        'threshold': 0.5,
        'inference_time_seconds': null,
        'image_filename': null,
        'source': null,
        'note': null,
        'is_synced': true,
        'created_at': '2026-05-16T00:00:00.000Z',
      };
      final model = ScanResultModel.fromJson(json);
      expect(model.source, 'server');
    });

    test('fromJson defaults is_synced to true when null', () {
      final json = {
        'id': 's2',
        'pred_label': 'NO_CRACK',
        'meaning': 'Không có vết nứt',
        'prob_positive': 0.1,
        'confidence': 0.9,
        'threshold': 0.5,
        'inference_time_seconds': null,
        'image_filename': null,
        'source': 'server',
        'note': null,
        'is_synced': null,
        'created_at': '2026-05-16T00:00:00.000Z',
      };
      final model = ScanResultModel.fromJson(json);
      expect(model.isSynced, true);
    });

    test('fromJson handles integer prob_positive (num → double)', () {
      final json = {
        'id': 's3',
        'pred_label': 'CRACK',
        'meaning': 'Có vết nứt',
        'prob_positive': 1,      // int, not double
        'confidence': 1,
        'threshold': 0,
        'inference_time_seconds': null,
        'image_filename': null,
        'source': 'server',
        'note': null,
        'is_synced': true,
        'created_at': '2026-05-16T00:00:00.000Z',
      };
      final model = ScanResultModel.fromJson(json);
      expect(model.probPositive, isA<double>());
      expect(model.confidence, isA<double>());
    });

    // ── Computed properties ────────────────────────────────────────

    test('hasCrack returns true for CRACK label', () {
      final model = _makeModel(predLabel: 'CRACK');
      expect(model.hasCrack, true);
    });

    test('hasCrack returns false for NO_CRACK label', () {
      final model = _makeModel(predLabel: 'NO_CRACK');
      expect(model.hasCrack, false);
    });

    test('hasCrack returns false for Positive label (server format)', () {
      final model = _makeModel(predLabel: 'Positive');
      expect(model.hasCrack, false); // only 'CRACK' returns true
    });

    // ── DateTime parsing ──────────────────────────────────────────

    test('createdAt is parsed as DateTime', () {
      final model = _makeModel();
      expect(model.createdAt, isA<DateTime>());
      expect(model.createdAt.year, 2026);
    });
  });
}

ScanResultModel _makeModel({
  String id = 'test-id',
  String predLabel = 'CRACK',
  String meaning = 'Có vết nứt',
  double probPositive = 0.87,
  double confidence = 0.87,
  double threshold = 0.5,
  String source = 'server',
}) =>
    ScanResultModel(
      id: id,
      predLabel: predLabel,
      meaning: meaning,
      probPositive: probPositive,
      confidence: confidence,
      threshold: threshold,
      source: source,
      isSynced: true,
      createdAt: DateTime(2026, 5, 16),
    );
