class ScanResultModel {
  final String id;
  final String predLabel; // "CRACK" | "NO_CRACK"
  final String meaning; // "Có vết nứt" | "Không có vết nứt"
  final double probPositive;
  final double confidence;
  final double threshold;
  final double? inferenceTimeSeconds;
  final String? imageFilename;
  final String? imagePath;
  final String source; // "server" | "tflite" | "*+vision" | "texture_filter"
  final String? note;
  final bool isSynced;
  final DateTime createdAt;
  final String? textureWarning;

  const ScanResultModel({
    required this.id,
    required this.predLabel,
    required this.meaning,
    required this.probPositive,
    required this.confidence,
    required this.threshold,
    this.inferenceTimeSeconds,
    this.imageFilename,
    this.imagePath,
    required this.source,
    this.note,
    required this.isSynced,
    required this.createdAt,
    this.textureWarning,
  });

  bool get hasCrack => predLabel == 'CRACK' || predLabel == 'Positive';
  bool get isTextureRejected => source == 'texture_filter';

  bool get isServerSource => source.startsWith('server');
  bool get usedVisionFallback => source.contains('vision');

  String get sourceLabel {
    final base = isServerSource ? 'Server AI' : 'On-device AI';
    return usedVisionFallback ? '$base + Vision' : base;
  }

  String get sourceShortLabel {
    final base = isServerSource ? 'Online' : 'On-device';
    return usedVisionFallback ? '$base + Vision' : base;
  }

  factory ScanResultModel.fromJson(Map<String, dynamic> json) =>
      ScanResultModel(
        id: (json['id'] ?? json['scan_id']) as String,
        predLabel: _normalizePredLabel(json['pred_label'] as String),
        meaning: json['meaning'] as String,
        probPositive: (json['prob_positive'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
        threshold: (json['threshold'] as num).toDouble(),
        inferenceTimeSeconds: json['inference_time_seconds'] != null
            ? (json['inference_time_seconds'] as num).toDouble()
            : null,
        imageFilename: json['image_filename'] as String?,
        imagePath: json['image_path'] as String?,
        source: json['source'] as String? ?? 'server',
        note: json['note'] as String?,
        isSynced: json['is_synced'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        textureWarning: json['texture_warning'] as String?,
      );

  static String _normalizePredLabel(String label) {
    if (label == 'Positive') return 'CRACK';
    if (label == 'Negative') return 'NO_CRACK';
    return label;
  }
}
