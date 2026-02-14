import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../models/upload_task.dart';
import '../services/language_service.dart';
import '../services/upload_queue_service.dart';
import '../utils/responsive.dart';

/// Screen for managing the upload queue
class UploadQueueScreen extends StatelessWidget {
  const UploadQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = context.isTabletOrLarger;
    final lang = context.watch<LanguageService>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTabletOrLarger ? 700 : double.infinity,
              ),
              child: Column(
                children: [
                  _buildHeader(context, lang),
                  Expanded(
                    child: Consumer<UploadQueueService>(
                      builder: (context, queueService, child) {
                        final allTasks = [
                          ...queueService.completedTasks,
                          if (queueService.currentTask != null) queueService.currentTask!,
                          ...queueService.pendingTasks,
                          ...queueService.failedTasks,
                        ];

                        if (allTasks.isEmpty) {
                          return _buildEmptyState(context, lang);
                        }

                        return _buildTaskList(context, queueService, lang);
                      },
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

  Widget _buildHeader(BuildContext context, LanguageService lang) {
    final isTabletOrLarger = context.isTabletOrLarger;
    final horizontalPadding = Responsive.horizontalPadding(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding / 2,
        isTabletOrLarger ? 12 : 8,
        horizontalPadding,
        horizontalPadding,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppTheme.glassWhite(0.9),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: isTabletOrLarger ? 12 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.translate('upload_queue'),
                  style: TextStyle(
                    fontSize: isTabletOrLarger ? 26 : 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.glassWhite(0.95),
                  ),
                ),
                Consumer<UploadQueueService>(
                  builder: (context, queueService, child) {
                    final activeCount = queueService.activeCount;
                    final completedCount = queueService.completedTasks.length;
                    final failedCount = queueService.failedTasks.length;

                    return Text(
                      '$activeCount ${lang.translate('active')}, $completedCount ${lang.translate('completed')}, $failedCount ${lang.translate('failed')}',
                      style: TextStyle(
                        fontSize: isTabletOrLarger ? 15 : 13,
                        color: AppTheme.glassWhite(0.6),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Consumer<UploadQueueService>(
            builder: (context, queueService, child) {
              if (queueService.completedTasks.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(
                  Icons.delete_sweep,
                  color: AppTheme.glassWhite(0.7),
                ),
                tooltip: lang.translate('clear_completed'),
                onPressed: () => queueService.clearCompleted(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, LanguageService lang) {
    final isTabletOrLarger = context.isTabletOrLarger;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_queue,
            size: isTabletOrLarger ? 100 : 80,
            color: AppTheme.glassWhite(0.3),
          ),
          SizedBox(height: isTabletOrLarger ? 24 : 16),
          Text(
            lang.translate('no_uploads'),
            style: TextStyle(
              fontSize: isTabletOrLarger ? 22 : 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.glassWhite(0.7),
            ),
          ),
          SizedBox(height: isTabletOrLarger ? 12 : 8),
          Text(
            lang.translate('scanned_assets_appear'),
            style: TextStyle(
              fontSize: isTabletOrLarger ? 16 : 14,
              color: AppTheme.glassWhite(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, UploadQueueService queueService, LanguageService lang) {
    final horizontalPadding = Responsive.horizontalPadding(context);
    final isTabletOrLarger = context.isTabletOrLarger;
    final sectionSpacing = isTabletOrLarger ? 24.0 : 16.0;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      children: [
        // Currently uploading
        if (queueService.currentTask != null) ...[
          _buildSectionHeader(context, lang.translate('uploading'), Icons.cloud_upload),
          _buildTaskCard(context, queueService.currentTask!, queueService, lang),
          SizedBox(height: sectionSpacing),
        ],

        // Pending tasks
        if (queueService.pendingTasks.isNotEmpty) ...[
          _buildSectionHeader(context, lang.translate('waiting'), Icons.schedule),
          ...queueService.pendingTasks.map(
            (task) => _buildTaskCard(context, task, queueService, lang),
          ),
          SizedBox(height: sectionSpacing),
        ],

        // Failed tasks
        if (queueService.failedTasks.isNotEmpty) ...[
          _buildSectionHeader(context, lang.translate('failed'), Icons.error_outline),
          ...queueService.failedTasks.map(
            (task) => _buildTaskCard(context, task, queueService, lang),
          ),
          SizedBox(height: sectionSpacing),
        ],

        // Completed tasks
        if (queueService.completedTasks.isNotEmpty) ...[
          _buildSectionHeader(context, lang.translate('completed'), Icons.check_circle_outline),
          ...queueService.completedTasks.map(
            (task) => _buildTaskCard(context, task, queueService, lang),
          ),
          SizedBox(height: sectionSpacing),
        ],

        SizedBox(height: isTabletOrLarger ? 32 : 20),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.glassWhite(0.6),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.glassWhite(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    UploadTask task,
    UploadQueueService queueService,
    LanguageService lang,
  ) {
    final isUploading = task.status == UploadStatus.uploading;
    final isFailed = task.status == UploadStatus.failed;
    final isCompleted = task.status == UploadStatus.completed;

    Color statusColor;
    if (isCompleted) {
      statusColor = Colors.green;
    } else if (isFailed) {
      statusColor = Colors.red;
    } else if (isUploading) {
      statusColor = AppTheme.getPrimaryColor(context);
    } else {
      statusColor = AppTheme.glassWhite(0.5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.glassWhite(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFailed
              ? Colors.red.withValues(alpha: 0.3)
              : AppTheme.glassWhite(0.1),
        ),
      ),
      child: Column(
        children: [
          // Progress bar for uploading tasks
          if (isUploading)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: LinearProgressIndicator(
                value: task.progress,
                backgroundColor: AppTheme.glassWhite(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.getPrimaryColor(context),
                ),
                minHeight: 3,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // BCN
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.bcn,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.glassWhite(0.9),
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${task.photoCount} photo(s) • ${_formatTime(task.createdAt, lang)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.glassWhite(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                // Error message for failed tasks
                if (isFailed && task.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.error!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action buttons
                if (isFailed || isCompleted) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Retry button for failed tasks
                      if (isFailed && task.canRetry)
                        TextButton.icon(
                          onPressed: () => queueService.retry(task.id),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(lang.translate('retry_button')),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.getPrimaryColor(context),
                          ),
                        ),

                      // Open Drive link for completed tasks
                      if (isCompleted && task.driveUrl != null)
                        TextButton.icon(
                          onPressed: () => _openDriveLink(task.driveUrl!),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: Text(lang.translate('view')),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.getPrimaryColor(context),
                          ),
                        ),

                      // Copy link for completed tasks
                      if (isCompleted && task.driveUrl != null)
                        IconButton(
                          onPressed: () => _copyLink(context, task.driveUrl!, lang),
                          icon: Icon(
                            Icons.copy,
                            size: 18,
                            color: AppTheme.glassWhite(0.6),
                          ),
                          tooltip: lang.translate('copy_link'),
                        ),

                      // Delete button (not for uploading tasks)
                      if (!isUploading)
                        IconButton(
                          onPressed: () => _confirmDelete(context, task, queueService, lang),
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppTheme.glassWhite(0.6),
                          ),
                          tooltip: lang.translate('remove'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time, LanguageService lang) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return lang.translate('just_now');
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  Future<void> _openDriveLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyLink(BuildContext context, String url, LanguageService lang) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang.translate('link_copied')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    UploadTask task,
    UploadQueueService queueService,
    LanguageService lang,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSlate900(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          lang.translate('remove_upload'),
          style: TextStyle(color: AppTheme.glassWhite(0.9)),
        ),
        content: Text(
          'Remove "${task.bcn}" from the queue?',
          style: TextStyle(color: AppTheme.glassWhite(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              lang.translate('cancel'),
              style: TextStyle(color: AppTheme.glassWhite(0.6)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(lang.translate('remove')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      queueService.remove(task.id);
    }
  }
}
