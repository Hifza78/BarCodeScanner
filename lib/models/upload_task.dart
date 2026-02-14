import 'package:hive/hive.dart';

part 'upload_task.g.dart';

/// Status of an upload task in the queue
@HiveType(typeId: 0)
enum UploadStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  uploading,

  @HiveField(2)
  completed,

  @HiveField(3)
  failed,
}

/// Data model for an upload task in the queue
/// Persisted with Hive for survival across app restarts
@HiveType(typeId: 1)
class UploadTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String bcn;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<String> photoPaths;

  @HiveField(4)
  final String? barcodeImagePath;

  @HiveField(5)
  UploadStatus status;

  @HiveField(6)
  double progress;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  String? error;

  @HiveField(10)
  String? driveUrl;

  @HiveField(11)
  int retryCount;

  @HiveField(12)
  DateTime? lastAttemptAt;

  UploadTask({
    required this.id,
    required this.bcn,
    required this.description,
    required this.photoPaths,
    this.barcodeImagePath,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    required this.createdAt,
    this.completedAt,
    this.error,
    this.driveUrl,
    this.retryCount = 0,
    this.lastAttemptAt,
  });

  /// Number of photos in this task
  int get photoCount => photoPaths.length;

  /// Whether the task can be retried
  bool get canRetry => status == UploadStatus.failed && retryCount < 3;

  /// Whether the task is currently being processed
  bool get isActive =>
      status == UploadStatus.pending || status == UploadStatus.uploading;

  /// Human-readable status text
  String get statusText {
    switch (status) {
      case UploadStatus.pending:
        return 'Waiting';
      case UploadStatus.uploading:
        return 'Uploading ${(progress * 100).toInt()}%';
      case UploadStatus.completed:
        return 'Completed';
      case UploadStatus.failed:
        return 'Failed';
    }
  }

  /// Create a copy with updated fields
  UploadTask copyWith({
    UploadStatus? status,
    double? progress,
    DateTime? completedAt,
    String? error,
    String? driveUrl,
    int? retryCount,
    DateTime? lastAttemptAt,
  }) {
    return UploadTask(
      id: id,
      bcn: bcn,
      description: description,
      photoPaths: photoPaths,
      barcodeImagePath: barcodeImagePath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      error: error ?? this.error,
      driveUrl: driveUrl ?? this.driveUrl,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }
}
