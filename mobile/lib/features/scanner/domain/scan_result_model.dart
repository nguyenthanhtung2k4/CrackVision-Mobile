class ScanResultModel {
  final String id;
  final String predLabel;      // "CRACK" | "NO_CRACK"
  final String meaning;        // "Có vết nứt" | "Không có vết nứt"
  final double probPositive;
  final double confidence;
  final double threshold;
  final double? inferenceTimeSeconds;
  final String? imageFilename;
  final String source;         // "server" | "tflite"
  final String? note;
  final bool isSynced;
  final DateTime createdAt;

  const ScanResultModel({
    required this.id,
    required this.predLabel,
    required this.meaning,
    required this.probPositive,
    required this.confidence,
    required this.threshold,
    this.inferenceTimeSeconds,
    this.imageFilename,
    required this.source,
    this.note,
    required this.isSynced,
    required this.createdAt,
  });

  bool get hasCrack => predLabel == 'CRACK';

  factory ScanResultModel.fromJson(Map<String, dynamic> json) => ScanResultModel(
        id: json['id'] as String,
        predLabel: json['pred_label'] as String,
        meaning: json['meaning'] as String,
        probPositive: (json['prob_positive'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
        threshold: (json['threshold'] as num).toDouble(),
        inferenceTimeSeconds: json['inference_time_seconds'] != null
            ? (json['inference_time_seconds'] as num).toDouble()
            : null,
        imageFilename: json['image_filename'] as String?,
        source: json['source'] as String? ?? 'server',
        note: json['note'] as String?,
        isSynced: json['is_synced'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
