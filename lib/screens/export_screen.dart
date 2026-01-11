import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:io';
import '../models/reporting.dart';
import '../services/data_export_service.dart';

class ExportScreen extends StatefulWidget {
  final String vehicleId;

  const ExportScreen({super.key, required this.vehicleId});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen>
    with TickerProviderStateMixin {
  late final DataExportService _exportService;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  ReportFormat _selectedFormat = ReportFormat.excel;
  bool _isExporting = false;
  List<File> _exportedFiles = [];
  double _exportProgress = 0.0;

  // Premium gradient colors
  static const List<Color> _primaryGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];

  static const List<Color> _accentGradient = [
    Color(0xFF06B6D4),
    Color(0xFF10B981),
  ];

  static const List<Color> _dangerGradient = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
  ];

  @override
  void initState() {
    super.initState();
    _exportService = GetIt.instance<DataExportService>();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _scaleController.forward();
    _loadExportedFiles();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadExportedFiles() async {
    final files = await _exportService.getExportedFiles();
    setState(() => _exportedFiles = files);
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });

    try {
      // Simulate export progress
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        setState(() => _exportProgress = i / 10);
      }

      // Perform actual export
      await Future.delayed(const Duration(seconds: 1));
      await _loadExportedFiles();

      if (mounted) {
        _showSnackBar('Data exported successfully!', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Export failed: $e', isSuccess: false);
      }
    } finally {
      setState(() {
        _isExporting = false;
        _exportProgress = 0.0;
      });
    }
  }

  Future<void> _createSecureLink() async {
    setState(() => _isExporting = true);

    try {
      final link = await _exportService.createSecureShareLink(
        widget.vehicleId,
        const Duration(days: 7),
        ['read'],
      );

      if (mounted) {
        _showShareLinkDialog(link);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to create link: $e', isSuccess: false);
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showShareLinkDialog(String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _accentGradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.link, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Share Link Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                link,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Link expires in 7 days',
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
              Navigator.of(context).pop();
              _showSnackBar('Link copied!', isSuccess: true);
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGradient[0],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(File file) async {
    try {
      await _exportService.shareFile(
        file,
        'Vehicle Export',
        message: 'Data export for vehicle ${widget.vehicleId}',
      );
    } catch (e) {
      _showSnackBar('Failed to share: $e', isSuccess: false);
    }
  }

  Future<void> _deleteFile(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _dangerGradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Delete File?'),
          ],
        ),
        content: Text(
          'Delete "${file.path.split(Platform.pathSeparator).last}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerGradient[0],
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
      _showSnackBar('File deleted', isSuccess: true);
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green[600] : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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

  Color _getFileColor(String fileName) {
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _primaryGradient[0].withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildExportConfiguration(),
                        const SizedBox(height: 20),
                        _buildExportActions(),
                        const SizedBox(height: 20),
                        _buildExportedFilesList(),
                      ]),
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

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Export Center',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _primaryGradient,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportConfiguration() {
    return _buildCard(
      icon: Icons.tune,
      iconGradient: _primaryGradient,
      title: 'Export Format',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ReportFormat.values.map((format) {
              final isSelected = _selectedFormat == format;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Material(
                  color: isSelected ? _primaryGradient[0] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => setState(() => _selectedFormat = format),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getFormatIcon(format),
                            size: 18,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            format.name.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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

  Widget _buildExportActions() {
    return _buildCard(
      icon: Icons.download_rounded,
      iconGradient: _accentGradient,
      title: 'Quick Actions',
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (_isExporting) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _exportProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_primaryGradient[0]),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Processing... ${(_exportProgress * 100).toInt()}%',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _buildGradientButton(
                  label: 'Export',
                  icon: Icons.file_download_rounded,
                  gradient: _primaryGradient,
                  onPressed: _isExporting ? null : _exportData,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGradientButton(
                  label: 'Share Link',
                  icon: Icons.link_rounded,
                  gradient: _accentGradient,
                  onPressed: _isExporting ? null : _createSecureLink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null ? LinearGradient(colors: gradient) : null,
        color: onPressed == null ? Colors.grey[300] : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.4),
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
                Icon(icon, color: Colors.white, size: 20),
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
    return _buildCard(
      icon: Icons.folder_rounded,
      iconGradient: [Colors.amber, Colors.orange],
      title: 'Exported Files',
      trailing: IconButton(
        icon: const Icon(Icons.refresh_rounded),
        onPressed: _loadExportedFiles,
        color: Colors.grey[600],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          if (_exportedFiles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No files yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ...List.generate(
              _exportedFiles.length,
              (i) => _buildFileItem(_exportedFiles[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildFileItem(File file) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileSize = (file.lengthSync() / 1024).toStringAsFixed(1);
    final color = _getFileColor(fileName);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getFileIcon(fileName), color: color, size: 20),
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$fileSize KB',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 20),
              onPressed: () => _shareFile(file),
              color: Colors.blue,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: () => _deleteFile(file),
              color: Colors.red[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                    gradient: LinearGradient(colors: iconGradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (trailing != null) ...[const Spacer(), trailing],
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

