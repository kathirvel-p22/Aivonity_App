import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/rca_report.dart';

/// Export format options
enum ExportFormat { pdf, excel, csv }

/// Share method options
enum ShareMethod { save, email, share }

/// Export state for managing export process
class ExportState {
  final bool isExporting;
  final String? error;
  final String? successMessage;
  final double? progress;
  final String? currentOperation;
  final String? exportedFilePath;

  const ExportState({
    this.isExporting = false,
    this.error,
    this.successMessage,
    this.progress,
    this.currentOperation,
    this.exportedFilePath,
  });

  ExportState copyWith({
    bool? isExporting,
    String? error,
    String? successMessage,
    double? progress,
    String? currentOperation,
    String? exportedFilePath,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      progress: progress ?? this.progress,
      currentOperation: currentOperation ?? this.currentOperation,
      exportedFilePath: exportedFilePath ?? this.exportedFilePath,
    );
  }
}

/// Analytics data model for export
class AnalyticsData {
  final List<Map<String, dynamic>> data;
  final DateTime generatedAt;

  const AnalyticsData({
    required this.data,
    required this.generatedAt,
  });
}

/// Export options for configuring export
class ExportOptions {
  final ExportFormat format;
  final bool includeCharts;
  final bool includeRawData;
  final DateTime? startDate;
  final DateTime? endDate;

  const ExportOptions({
    required this.format,
    required this.includeCharts,
    required this.includeRawData,
    this.startDate,
    this.endDate,
  });
}

/// Share options for configuring sharing
class ShareOptions {
  final ShareMethod method;
  final String? recipient;
  final String? subject;
  final String? message;

  const ShareOptions({
    required this.method,
    this.recipient,
    this.subject,
    this.message,
  });
}

/// Export state notifier
class ExportStateNotifier extends StateNotifier<ExportState> {
  ExportStateNotifier() : super(const ExportState());

  Future<void> exportRCAReport(RCAReport report, ExportOptions options) async {
    state = state.copyWith(isExporting: true, error: null);

    try {
      // Mock export process
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(
        isExporting: false,
        successMessage: 'Report exported successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to export report: $e',
      );
    }
  }

  Future<void> exportAnalyticsData(
      AnalyticsData data, ExportOptions options,) async {
    state = state.copyWith(isExporting: true, error: null);

    try {
      // Mock export process
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(
        isExporting: false,
        successMessage: 'Analytics data exported successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to export analytics data: $e',
      );
    }
  }

  Future<void> shareExportedFile(ShareOptions options) async {
    state = state.copyWith(isExporting: true, error: null);

    try {
      // Mock share process
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(
        isExporting: false,
        successMessage: 'File shared successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to share file: $e',
      );
    }
  }

  void clearState() {
    state = const ExportState();
  }
}

/// Export state provider
final exportStateProvider =
    StateNotifierProvider<ExportStateNotifier, ExportState>((ref) {
  return ExportStateNotifier();
});

/// AIVONITY Export Dialog Widget
/// Allows users to configure and export reports
class ExportDialog extends ConsumerStatefulWidget {
  final AnalyticsData? analyticsData;
  final RCAReport? rcaReport;

  const ExportDialog({super.key, this.analyticsData, this.rcaReport});

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _includeCharts = true;
  bool _includeRawData = false;
  DateTime? _startDate;
  DateTime? _endDate;

  ShareMethod _shareMethod = ShareMethod.save;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subjectController.text = widget.rcaReport != null
        ? 'RCA Report: ${widget.rcaReport!.title}'
        : 'AIVONITY Analytics Report';
    _messageController.text = 'Please find the attached report from AIVONITY.';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportStateProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: exportState.isExporting
            ? _buildExportingState(exportState)
            : _buildExportOptions(),
      ),
    );
  }

  Widget _buildExportingState(ExportState exportState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Exporting Report',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        CircularProgressIndicator(value: exportState.progress),
        const SizedBox(height: 16),
        Text(
          exportState.currentOperation ?? 'Processing...',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${((exportState.progress ?? 0.0) * 100).toInt()}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
              ),
        ),
        if (exportState.error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exportState.error!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  ref.read(exportStateProvider.notifier).clearState();
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ],
        if (exportState.exportedFilePath != null &&
            exportState.error == null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Export completed successfully!',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _shareFile(),
                child: const Text('Share'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  ref.read(exportStateProvider.notifier).clearState();
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildExportOptions() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Export Report',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Format Selection
          _buildFormatSelection(),

          const SizedBox(height: 24),

          // Export Options
          _buildExportOptionsSection(),

          const SizedBox(height: 24),

          // Share Options
          _buildShareOptions(),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _startExport,
                child: const Text('Export'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Format',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: ExportFormat.values.map((format) {
            final isSelected = _selectedFormat == format;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFormat = format;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha:0.3),
                    ),
                  ),
                  child: Text(
                    format.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExportOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Options',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Include Charts'),
          subtitle: const Text('Visual charts and graphs'),
          value: _includeCharts,
          onChanged: (value) {
            setState(() {
              _includeCharts = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Include Raw Data'),
          subtitle: const Text('Detailed data tables'),
          value: _includeRawData,
          onChanged: (value) {
            setState(() {
              _includeRawData = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildShareOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share Method',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...ShareMethod.values.map((method) {
          return RadioListTile<ShareMethod>(
            title: Text(_getShareMethodName(method)),
            subtitle: Text(_getShareMethodDescription(method)),
            value: method,
            groupValue: _shareMethod,
            onChanged: (value) {
              setState(() {
                _shareMethod = value!;
              });
            },
            contentPadding: EdgeInsets.zero,
          );
        }),
        if (_shareMethod == ShareMethod.email) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ],
    );
  }

  String _getShareMethodName(ShareMethod method) {
    switch (method) {
      case ShareMethod.email:
        return 'Email';
      case ShareMethod.share:
        return 'Share';
      case ShareMethod.save:
        return 'Save to Device';
    }
  }

  String _getShareMethodDescription(ShareMethod method) {
    switch (method) {
      case ShareMethod.email:
        return 'Send via email';
      case ShareMethod.share:
        return 'Share with other apps';
      case ShareMethod.save:
        return 'Save to downloads folder';
    }
  }

  void _startExport() {
    final options = ExportOptions(
      format: _selectedFormat,
      includeCharts: _includeCharts,
      includeRawData: _includeRawData,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (widget.rcaReport != null) {
      ref
          .read(exportStateProvider.notifier)
          .exportRCAReport(widget.rcaReport!, options);
    } else if (widget.analyticsData != null) {
      ref
          .read(exportStateProvider.notifier)
          .exportAnalyticsData(widget.analyticsData!, options);
    }
  }

  void _shareFile() {
    final shareOptions = ShareOptions(
      method: _shareMethod,
      recipient:
          _emailController.text.isNotEmpty ? _emailController.text : null,
      subject:
          _subjectController.text.isNotEmpty ? _subjectController.text : null,
      message:
          _messageController.text.isNotEmpty ? _messageController.text : null,
    );

    ref.read(exportStateProvider.notifier).shareExportedFile(shareOptions);
  }
}

