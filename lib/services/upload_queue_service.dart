import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/upload_task.dart';
import '../models/session_data.dart';
import 'drive_service.dart';

/// Service for managing the upload queue
/// Uses Hive for persistence and processes uploads in background
class UploadQueueService extends ChangeNotifier {
  static const String _boxName = 'upload_queue';
  static const int maxRetries = 3;
  static const _uuid = Uuid();

  late Box<UploadTask> _box;
  final DriveService _driveService = DriveService();
  bool _isProcessing = false;
  bool _isInitialized = false;

  /// Stream controller for completed task notifications
  final _completedTaskController = StreamController<UploadTask>.broadcast();

  /// Stream that emits tasks when they complete successfully with a Drive URL
  Stream<UploadTask> get onTaskCompleted => _completedTaskController.stream;

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Whether the queue is currently being processed
  bool get isProcessing => _isProcessing;

  /// All tasks in the queue
  List<UploadTask> get allTasks => _box.values.toList();

  /// Tasks waiting to be uploaded
  List<UploadTask> get pendingTasks => _box.values
      .where((t) => t.status == UploadStatus.pending)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// Task currently being uploaded
  UploadTask? get currentTask => _box.values
      .where((t) => t.status == UploadStatus.uploading)
      .firstOrNull;

  /// Tasks that failed
  List<UploadTask> get failedTasks => _box.values
      .where((t) => t.status == UploadStatus.failed)
      .toList()
    ..sort((a, b) => b.lastAttemptAt?.compareTo(a.lastAttemptAt ?? DateTime(0)) ?? 0);

  /// Completed tasks
  List<UploadTask> get completedTasks => _box.values
      .where((t) => t.status == UploadStatus.completed)
      .toList()
    ..sort((a, b) => b.completedAt?.compareTo(a.completedAt ?? DateTime(0)) ?? 0);

  /// Number of active tasks (pending + uploading)
  int get activeCount =>
      pendingTasks.length + (currentTask != null ? 1 : 0);

  /// Number of pending tasks
  int get pendingCount => pendingTasks.length;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UploadStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UploadTaskAdapter());
    }

    _box = await Hive.openBox<UploadTask>(_boxName);
    _isInitialized = true;

    // Reset any tasks that were uploading when app closed
    await _resetStuckTasks();

    // Start processing if there are pending tasks
    _startProcessing();

    notifyListeners();
  }

  /// Reset tasks that were stuck in uploading state
  Future<void> _resetStuckTasks() async {
    for (final task in _box.values) {
      if (task.status == UploadStatus.uploading) {
        task.status = UploadStatus.pending;
        await task.save();
      }
    }
  }

  /// Add a new upload task to the queue
  Future<String> enqueue(SessionData session) async {
    if (!_isInitialized) {
      throw Exception('UploadQueueService not initialized');
    }

    final taskId = _uuid.v4();

    // Copy photos to persistent storage
    final persistedPaths = await _persistPhotos(taskId, session.photos);
    final task = UploadTask(
      id: taskId,
      bcn: session.bcn,
      description: session.description,
      photoPaths: persistedPaths,
      status: UploadStatus.pending,
      progress: 0.0,
      createdAt: DateTime.now(),
      retryCount: 0,
    );

    await _box.put(taskId, task);
    notifyListeners();

    // Start processing if not already
    _startProcessing();

    return taskId;
  }

  /// Copy photos to persistent app directory
  Future<List<String>> _persistPhotos(String taskId, List<File> photos) async {
    final paths = <String>[];
    for (int i = 0; i < photos.length; i++) {
      final fileName = 'photo_${i + 1}.jpg';
      final path = await _persistFile(taskId, photos[i], fileName);
      paths.add(path);
    }
    return paths;
  }

  /// Copy a single file to persistent storage
  Future<String> _persistFile(String taskId, File file, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final taskDir = Directory(p.join(appDir.path, 'upload_queue', taskId));

    if (!await taskDir.exists()) {
      await taskDir.create(recursive: true);
    }

    final destPath = p.join(taskDir.path, fileName);
    await file.copy(destPath);
    return destPath;
  }

  /// Retry a failed task
  Future<void> retry(String taskId) async {
    final task = _box.get(taskId);
    if (task == null || task.status != UploadStatus.failed) return;

    task.status = UploadStatus.pending;
    task.error = null;
    task.progress = 0.0;
    await task.save();
    notifyListeners();

    _startProcessing();
  }

  /// Retry all failed tasks
  Future<void> retryAllFailed() async {
    for (final task in failedTasks) {
      if (task.canRetry) {
        task.status = UploadStatus.pending;
        task.error = null;
        task.progress = 0.0;
        await task.save();
      }
    }
    notifyListeners();
    _startProcessing();
  }

  /// Remove a task from the queue
  Future<void> remove(String taskId) async {
    final task = _box.get(taskId);
    if (task == null) return;

    // Don't remove if currently uploading
    if (task.status == UploadStatus.uploading) return;

    // Clean up files
    await _cleanupTaskFiles(taskId);
    await _box.delete(taskId);
    notifyListeners();
  }

  /// Clear all completed tasks
  Future<void> clearCompleted() async {
    final completed = completedTasks.toList();
    for (final task in completed) {
      await _cleanupTaskFiles(task.id);
      await _box.delete(task.id);
    }
    notifyListeners();
  }

  /// Clear all failed tasks
  Future<void> clearFailed() async {
    final failed = failedTasks.toList();
    for (final task in failed) {
      await _cleanupTaskFiles(task.id);
      await _box.delete(task.id);
    }
    notifyListeners();
  }

  /// Delete the task's persisted files
  Future<void> _cleanupTaskFiles(String taskId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final taskDir = Directory(p.join(appDir.path, 'upload_queue', taskId));
      if (await taskDir.exists()) {
        await taskDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error cleaning up task files: $e');
    }
  }

  /// Start processing the queue
  void _startProcessing() {
    if (_isProcessing) return;
    _processQueue();
  }

  /// Process the upload queue
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    notifyListeners();

    while (true) {
      // Get next task to process
      final task = _getNextTask();
      if (task == null) break;

      try {
        // Mark as uploading
        task.status = UploadStatus.uploading;
        task.lastAttemptAt = DateTime.now();
        task.error = null;
        await task.save();
        notifyListeners();

        // Convert paths back to Files
        final photos = task.photoPaths.map((p) => File(p)).toList();
        // Perform upload
        final driveUrl = await _driveService.uploadPhotos(
          bcn: task.bcn,
          photos: photos,
          description: task.description,
          onProgress: (progress) {
            task.progress = progress;
            notifyListeners();
          },
        );

        if (driveUrl != null) {
          // Success
          task.status = UploadStatus.completed;
          task.driveUrl = driveUrl;
          task.completedAt = DateTime.now();
          task.progress = 1.0;
          await task.save();

          // Clean up persisted files after successful upload
          await _cleanupTaskFiles(task.id);

          // Notify listeners that a task completed with a shareable URL
          _completedTaskController.add(task);
        } else {
          throw Exception('Upload returned null');
        }
      } catch (e) {
        // Failure
        task.status = UploadStatus.failed;
        task.error = e.toString();
        task.retryCount++;
        await task.save();
        debugPrint('Upload failed for task ${task.id}: $e');
      }

      notifyListeners();
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// Get the next task to process (pending tasks first, then retryable failed)
  UploadTask? _getNextTask() {
    // First check pending tasks
    if (pendingTasks.isNotEmpty) {
      return pendingTasks.first;
    }

    // Then check failed tasks that can be auto-retried
    // (only auto-retry once, manual retry after that)
    final autoRetryable = failedTasks
        .where((t) => t.retryCount == 1 && t.canRetry)
        .toList();
    if (autoRetryable.isNotEmpty) {
      return autoRetryable.first;
    }

    return null;
  }

  /// Get a task by ID
  UploadTask? getTask(String taskId) => _box.get(taskId);

  /// Dispose resources
  @override
  void dispose() {
    _completedTaskController.close();
    _box.close();
    super.dispose();
  }
}
