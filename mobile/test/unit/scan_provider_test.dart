import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';
import 'package:crackvision/features/scanner/data/scan_repository.dart'
    show ScanException;
import 'package:crackvision/features/scanner/presentation/scan_state.dart';

// ── Minimal upload interface — avoids tflite_flutter compile path ──

abstract class _IUploader {
  Future<ScanResultModel> uploadAndScan(File file);
}

class _MockUploader extends Mock implements _IUploader {}
class _FakeFile extends Fake implements File {}

// Standalone notifier that replicates ScanNotifier logic using _IUploader.
// Does NOT extend ScanNotifier (avoids ScanRepository / tflite dependency).
class _FakeScanNotifier extends StateNotifier<ScanState> {
  final _IUploader _uploader;

  _FakeScanNotifier(this._uploader) : super(const ScanState());

  void selectImage(File image) => state = state.withImage(image);
  void reset() => state = state.reset();

  Future<void> analyze() async {
    final image = state.selectedImage;
    if (image == null) return;
    state = state.copyWith(status: ScanStatus.loading, error: null);
    try {
      final result = await _uploader.uploadAndScan(image);
      state = state.copyWith(status: ScanStatus.success, result: result);
    } on ScanException catch (e) {
      state = state.copyWith(status: ScanStatus.error, error: e.message);
    } catch (_) {
      state = state.copyWith(
        status: ScanStatus.error,
        error: 'Đã có lỗi xảy ra. Vui lòng thử lại.',
      );
    }
  }
}

// Provider used only in tests
final _testScanProvider =
    StateNotifierProvider<_FakeScanNotifier, ScanState>((ref) {
  throw UnimplementedError('override in test');
});

// ──────────────────────────────────────────────────────────────────

void main() {
  late _MockUploader mockUploader;
  late ProviderContainer container;

  final fakeResult = ScanResultModel(
    id: 'r1',
    predLabel: 'CRACK',
    meaning: 'Có vết nứt',
    probPositive: 0.87,
    confidence: 0.87,
    threshold: 0.5,
    source: 'server',
    isSynced: true,
    createdAt: DateTime(2026, 5, 16),
  );

  setUpAll(() => registerFallbackValue(_FakeFile()));

  setUp(() {
    mockUploader = _MockUploader();
    container = ProviderContainer(
      overrides: [
        _testScanProvider
            .overrideWith((ref) => _FakeScanNotifier(mockUploader)),
      ],
    );
  });

  tearDown(() => container.dispose());

  _FakeScanNotifier notifier() => container.read(_testScanProvider.notifier);
  ScanState scanState() => container.read(_testScanProvider);

  // ── Initial state ─────────────────────────────────────────────

  test('initial state is idle', () {
    expect(scanState().status, ScanStatus.idle);
    expect(scanState().selectedImage, isNull);
    expect(scanState().result, isNull);
    expect(scanState().error, isNull);
  });

  // ── selectImage ───────────────────────────────────────────────

  test('selectImage sets image and stays idle', () {
    notifier().selectImage(File('test.jpg'));

    expect(scanState().status, ScanStatus.idle);
    expect(scanState().selectedImage, isNotNull);
  });

  // ── reset ─────────────────────────────────────────────────────

  test('reset clears image and returns idle', () {
    notifier().selectImage(File('test.jpg'));
    notifier().reset();

    expect(scanState().status, ScanStatus.idle);
    expect(scanState().selectedImage, isNull);
  });

  // ── analyze — no image ────────────────────────────────────────

  test('analyze with no image does nothing', () async {
    await notifier().analyze();
    verifyNever(() => mockUploader.uploadAndScan(any()));
    expect(scanState().status, ScanStatus.idle);
  });

  // ── analyze — success ─────────────────────────────────────────

  test('analyze success → status.success with result', () async {
    when(() => mockUploader.uploadAndScan(any()))
        .thenAnswer((_) async => fakeResult);

    notifier().selectImage(File('crack.jpg'));
    await notifier().analyze();

    expect(scanState().status, ScanStatus.success);
    expect(scanState().result, fakeResult);
    expect(scanState().error, isNull);
  });

  // ── analyze — ScanException ───────────────────────────────────

  test('analyze ScanException → error with exact message', () async {
    when(() => mockUploader.uploadAndScan(any()))
        .thenThrow(const ScanException('Ảnh không hợp lệ.'));

    notifier().selectImage(File('bad.gif'));
    await notifier().analyze();

    expect(scanState().status, ScanStatus.error);
    expect(scanState().error, 'Ảnh không hợp lệ.');
    expect(scanState().result, isNull);
  });

  // ── analyze — unexpected exception ───────────────────────────

  test('analyze unexpected exception → generic error message', () async {
    when(() => mockUploader.uploadAndScan(any()))
        .thenThrow(Exception('Network down'));

    notifier().selectImage(File('test.jpg'));
    await notifier().analyze();

    expect(scanState().status, ScanStatus.error);
    expect(scanState().error, isNotNull);
    expect(scanState().error, isNot(contains('Exception')));
  });

  // ── ScanState value object helpers ───────────────────────────

  test('ScanState.withImage resets to idle, clears error', () {
    const s = ScanState(status: ScanStatus.error, error: 'old');
    final next = s.withImage(File('new.jpg'));

    expect(next.status, ScanStatus.idle);
    expect(next.error, isNull);
    expect(next.selectedImage, isNotNull);
  });

  test('ScanState.reset returns clean idle state', () {
    final s = ScanState(
      status: ScanStatus.success,
      selectedImage: File('x.jpg'),
      result: fakeResult,
    );
    final clean = s.reset();

    expect(clean.status, ScanStatus.idle);
    expect(clean.selectedImage, isNull);
    expect(clean.result, isNull);
  });

  test('ScanState.copyWith only updates specified fields', () {
    const s = ScanState(status: ScanStatus.idle);
    final updated = s.copyWith(status: ScanStatus.loading);

    expect(updated.status, ScanStatus.loading);
    expect(updated.selectedImage, isNull);
  });
}
