import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:io';
import '../models/analytics.dart';
import '../models/reporting.dart';
import '../services/data_export_service.dart';
import '../services/analytics_service.dart';
import '../services/predictive_analytics_service.dart';

class DataExportScreen extends StatefulWidget {
  final String vehicleId;

  const DataExportScreen({super.key, required this.vehicleId});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen>
    with TickerProviderStateMixin {
  late final DataExportService _exportService;
  late final AnalyticsService _analyticsService;
  late final PredictiveAnalyticsService _predictiveService;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  ReportFormat _selectedFormat = ReportFormat.excel;
  TimePeriod _selectedPeriod = TimePeriod.month;
  final Set<String> _selectedDataTypes = {'analytics', 'predictions'};
  bool _isExporting = false;
  List<File> _exportedFiles = [];
  double _exportProgress = 0.0;

  // Gradient colors for premium UI
  static const List<Color> _gradientColors = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
  ];

  static const List<Color> _successGradient = [
    Color(0xFF11998e),
    Color(0xFF38ef7d),
  ];

  static const List<Color> _warningGradient = [
    Color(0xFFf093fb),
    Color(0xFFf5576c),
  ];

  @override
  void initState() {
    super.initState();
    _exportService = GetIt.instance<DataExportService>();
    _analyticsService = GetIt.instance<AnalyticsService>();
    _predictiveService = GetIt.instance<PredictiveAnalyticsService>();

    // Setup animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _slideController.forward();
    _loadExportedFiles();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadExportedFiles() async {
    final files = await _exportService.getExportedFiles();
    setState(() {
      _exportedFiles = files;
    });
  }

  Duration _getPeriodDuration() {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        return const Duration(days: 1);
      case TimePeriod.week:
        return const Duration(days: 7);
      case TimePeriod.month:
        return const Duration(days: 30);
      case TimePeriod.quarter:
        return const Duration(days: 90);
      case TimePeriod.year:
        return const Duration(days: 365);
    }
  }

  Future<void> _exportData() async {
    if (_selectedDataTypes.isEmpty) {
      _showAnimatedSnackBar(
        'Please select at least one data type',
        isError: true,
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });

    try {
      File? exportedFile;

      // Simulate progress for better UX
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() => _exportProgress = i / 10);
      }

      if (_selectedDataTypes.contains('analytics') &&
          _selectedDataTypes.contains('predictions')) {
        // Export all data
        final metrics = await _analyticsService.getHistoricalMetrics(
          widget.vehicleId,
          DateTime.now().subtract(_getPeriodDuration()),
          DateTime.now(),
        );
        final kpis = await _analyticsService.getKPIMetrics(widget.vehicleId);
        final predictions = await _predictiveService.getMaintenancePredictions(
          widget.vehicleId,
        );
        final insights = await _predictiveService.generateInsights(
          widget.vehicleId,
          [],
        );

        final exportedFiles = await _exportService.exportAllData(
          widget.vehicleId,
          metrics,
          kpis,
          predictions,
          insights,
        );
        if (exportedFiles.isNotEmpty) {
          exportedFile = exportedFiles.first;
        }
      } else if (_selectedDataTypes.contains('analytics')) {
        final metrics = await _analyticsService.getHistoricalMetrics(
          widget.vehicleId,
          DateTime.now().subtract(_getPeriodDuration()),
          DateTime.now(),
        );
        final kpis = await _analyticsService.getKPIMetrics(widget.vehicleId);

        exportedFile = await _exportService.exportAnalyticsData(
          widget.vehicleId,
          metrics,
          kpis,
          _selectedFormat,
        );
      } else if (_selectedDataTypes.contains('predictions')) {
        final predictions = await _predictiveService.getMaintenancePredictions(
          widget.vehicleId,
        );
        final insights = await _predictiveService.generateInsights(
          widget.vehicleId,
          [],
        );

        exportedFile = await _exportService.exportPredictiveData(
          widget.vehicleId,
          predictions,
          insights,
          _selectedFormat,
        );
      }

      if (exportedFile != null) {
        await _loadExportedFiles();
        _showAnimatedSnackBar(
          'Data exported to ${exportedFile.path.split('/').last}',
          isError: false,
        );
      }
    } catch (e) {
      _showAnimatedSnackBar('Export failed: $e', isError: true);
    } finally {
      setState(() {
        _isExporting = false;
        _exportProgress = 0.0;
      });
    }
  }

  Future<void> _exportAndShare() async {
    await _exportData();
    if (_exportedFiles.isNotEmpty) {
      await _shareFile(_exportedFiles.first);
    }
  }

  Future<void> _createSecureLink() async {
    try {
      setState(() => _isExporting = true);

      final link = await _exportService.createSecureShareLink(
        widget.vehicleId,
        const Duration(days: 7),
        ['read'],
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => _buildShareLinkDialog(link),
      );
    } catch (e) {
      _showAnimatedSnackBar('Failed to create share link: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Widget _buildShareLinkDialog(String link) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _successGradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.link, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text('Secure Share Link'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share link created successfully!',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SelectableText(
              link,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Expires in 7 days',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Copy to clipboard functionality
            Navigator.of(context).pop();
            _showAnimatedSnackBar('Link copied to clipboard!', isError: false);
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy Link'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _gradientColors[0],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _shareFile(File file) async {
    try {
      await _exportService.shareFile(
        file,
        'Vehicle Data Export',
        message: 'Vehicle analytics data for ${widget.vehicleId}',
      );
    } catch (e) {
      _showAnimatedSnackBar('Failed to share file: $e', isError: true);
    }
  }

  Future<void> _deleteFile(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _warningGradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Delete File'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${file.path.split('/').last}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _exportService.deleteExportedFile(file);
      await _loadExportedFiles();
      _showAnimatedSnackBar('File deleted', isError: false);
    }
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _warningGradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cleaning_services, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Cleanup Old Files'),
          ],
        ),
        content: const Text(
          'Delete all exported files older than 30 days? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _exportService.cleanupOldExports();
              await _loadExportedFiles();
              _showAnimatedSnackBar('Old files cleaned up', isError: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cleanup'),
          ),
        ],
      ),
    );
  }

  void _showAnimatedSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.csv')) return Icons.table_chart;
    if (fileName.endsWith('.xlsx')) return Icons.grid_on;
    if (fileName.endsWith('.json')) return Icons.code;
    if (fileName.endsWith('.pdf')) return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }

  Color _getFormatColor(String fileName) {
    if (fileName.endsWith('.csv')) return Colors.green;
    if (fileName.endsWith('.xlsx')) return Colors.blue;
    if (fileName.endsWith('.json')) return Colors.orange;
    if (fileName.endsWith('.pdf')) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            _buildAnimatedAppBar(),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExportConfiguration(),
                      const SizedBox(height: 24),
                      _buildExportActions(),
                      const SizedBox(height: 24),
                      _buildExportedFilesList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Data Export & Sharing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _gradientColors,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.cleaning_services),
          onPressed: _showCleanupDialog,
          tooltip: 'Cleanup Old Files',
        ),
      ],
    );
  }

  Widget _buildExportConfiguration() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isExporting ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _gradientColors[0].withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: _gradientColors),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Export Configuration',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Format Selection
              _buildSectionTitle('Export Format'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ReportFormat.values.map((format) {
                  final isSelected = _selectedFormat == format;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getFormatIcon(format),
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text(format.name.toUpperCase()),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFormat = format);
                        }
                      },
                      selectedColor: _gradientColors[0],
                      backgroundColor: Colors.grey[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Time Period Selection
              _buildSectionTitle('Time Period'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<TimePeriod>(
                  initialValue: _selectedPeriod,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  items: TimePeriod.values.map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Row(
                        children: [
                          Icon(
                            _getPeriodIcon(period),
                            size: 20,
                            color: _gradientColors[0],
                          ),
                          const SizedBox(width: 12),
                          Text(_getPeriodLabel(period)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPeriod = value);
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Data Types Selection
              _buildSectionTitle('Data Types'),
              const SizedBox(height: 12),
              _buildDataTypeCard(
                'analytics',
                'Analytics Data',
                'Performance metrics and KPIs',
                Icons.analytics,
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildDataTypeCard(
                'predictions',
                'Predictive Data',
                'Maintenance predictions and insights',
                Icons.auto_graph,
                Colors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }

  IconData _getFormatIcon(ReportFormat format) {
    switch (format) {
      case ReportFormat.csv:
        return Icons.table_chart;
      case ReportFormat.excel:
        return Icons.grid_on;
      case ReportFormat.json:
        return Icons.code;
      case ReportFormat.pdf:
        return Icons.picture_as_pdf;
    }
  }

  IconData _getPeriodIcon(TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return Icons.today;
      case TimePeriod.week:
        return Icons.date_range;
      case TimePeriod.month:
        return Icons.calendar_month;
      case TimePeriod.quarter:
        return Icons.calendar_view_month;
      case TimePeriod.year:
        return Icons.calendar_today;
    }
  }

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return 'Last 24 Hours';
      case TimePeriod.week:
        return 'Last 7 Days';
      case TimePeriod.month:
        return 'Last 30 Days';
      case TimePeriod.quarter:
        return 'Last 90 Days';
      case TimePeriod.year:
        return 'Last Year';
    }
  }

  Widget _buildDataTypeCard(
    String key,
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
  ) {
    final isSelected = _selectedDataTypes.contains(key);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? accentColor.withValues(alpha: 0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? accentColor : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedDataTypes.add(key);
            } else {
              _selectedDataTypes.remove(key);
            }
          });
        },
        activeColor: accentColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildExportActions() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _successGradient[0].withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _successGradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.file_download,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Export Actions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress indicator
            if (_isExporting) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _exportProgress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_gradientColors[0]),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Exporting... ${(_exportProgress * 100).toInt()}%',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: _isExporting ? 'Exporting...' : 'Export Data',
                    icon: _isExporting
                        ? Icons.hourglass_top
                        : Icons.download_rounded,
                    gradient: _gradientColors,
                    onPressed: _isExporting ? null : _exportData,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'Export & Share',
                    icon: Icons.share_rounded,
                    gradient: _successGradient,
                    onPressed: _isExporting ? null : _exportAndShare,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                label: 'Create Secure Share Link',
                icon: Icons.link_rounded,
                gradient: [Colors.orange, Colors.deepOrange],
                onPressed: _isExporting ? null : _createSecureLink,
                outlined: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    VoidCallback? onPressed,
    bool outlined = false,
  }) {
    if (outlined) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gradient[0], width: 2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: gradient[0]),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: gradient[0],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null ? LinearGradient(colors: gradient) : null,
        color: onPressed == null ? Colors.grey[300] : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportedFilesList() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.folder_open,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Exported Files',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _loadExportedFiles,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_exportedFiles.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_off_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No exported files found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Export some data to see files here',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exportedFiles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _buildFileListItem(_exportedFiles[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileListItem(File file) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileSize = file.lengthSync();
    final fileSizeKB = (fileSize / 1024).toStringAsFixed(1);
    final fileColor = _getFormatColor(fileName);

    return Container(
      decoration: BoxDecoration(
        color: fileColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fileColor.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: fileColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getFileIcon(fileName), color: fileColor),
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$fileSizeKB KB',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.share_rounded, color: Colors.blue[600]),
              onPressed: () => _shareFile(file),
              tooltip: 'Share',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red[400]),
              onPressed: () => _deleteFile(file),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

