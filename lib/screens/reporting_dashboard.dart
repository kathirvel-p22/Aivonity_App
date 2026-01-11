import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../models/reporting.dart';
import '../models/analytics.dart' show TimePeriod;
import '../services/reporting_service.dart';

class ReportingDashboard extends StatefulWidget {
  final String vehicleId;

  const ReportingDashboard({super.key, required this.vehicleId});

  @override
  State<ReportingDashboard> createState() => _ReportingDashboardState();
}

class _ReportingDashboardState extends State<ReportingDashboard>
    with TickerProviderStateMixin {
  late final ReportingService _reportingService;
  late final TabController _tabController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  List<Report> _reports = [];
  List<ReportTemplate> _templates = [];
  final List<ReportSchedule> _schedules = [];
  bool _isLoading = true;
  String? _error;

  // Premium gradient colors
  static const List<Color> _primaryGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];

  static const List<Color> _successGradient = [
    Color(0xFF10B981),
    Color(0xFF34D399),
  ];

  static const List<Color> _warningGradient = [
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
  ];

  static const List<Color> _infoGradient = [
    Color(0xFF06B6D4),
    Color(0xFF22D3EE),
  ];

  @override
  void initState() {
    super.initState();
    _reportingService = GetIt.instance<ReportingService>();
    _tabController = TabController(length: 3, vsync: this);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
    _loadReportingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadReportingData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        _reportingService.getReports(widget.vehicleId),
        _reportingService.getReportTemplates(),
      ]);

      setState(() {
        _reports = futures[0] as List<Report>;
        _templates = futures[1] as List<ReportTemplate>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load reporting data: $e';
        _isLoading = false;
      });
    }
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
              _primaryGradient[0].withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildAnimatedAppBar(innerBoxIsScrolled),
          ],
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: _isLoading
                ? _buildLoadingIndicator()
                : _error != null
                ? _buildErrorWidget()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReportsTab(),
                      _buildTemplatesTab(),
                      _buildSchedulesTab(),
                    ],
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateReportDialog,
        backgroundColor: _primaryGradient[0],
        icon: const Icon(Icons.add),
        label: const Text('New Report'),
      ),
    );
  }

  Widget _buildAnimatedAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      forceElevated: innerBoxIsScrolled,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Reports & Analytics',
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
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              const Positioned(
                right: 20,
                bottom: 60,
                child: Icon(
                  Icons.description_outlined,
                  size: 80,
                  color: Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadReportingData,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.description_outlined), text: 'Reports'),
          Tab(icon: Icon(Icons.dashboard_outlined), text: 'Templates'),
          Tab(icon: Icon(Icons.schedule_outlined), text: 'Scheduled'),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _primaryGradient),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryGradient[0].withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading reports...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.red[700]!],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Data',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildGradientButton(
              label: 'Retry',
              icon: Icons.refresh,
              gradient: _primaryGradient,
              onPressed: _loadReportingData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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

  Widget _buildReportsTab() {
    if (_reports.isEmpty) {
      return _buildEmptyState(
        icon: Icons.description_outlined,
        title: 'No Reports Yet',
        message: 'Create your first report to get started',
        actionLabel: 'Create Report',
        onAction: _showCreateReportDialog,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Generated Reports', _reports.length),
          const SizedBox(height: 16),
          ..._reports.map((report) => _buildReportCard(report)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: _primaryGradient),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.description, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _primaryGradient[0].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: _primaryGradient[0],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(Report report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.description,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(report.status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(report.generatedDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.category, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  report.type.name.toUpperCase(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildIconButton(
                  icon: Icons.download_rounded,
                  color: _successGradient[0],
                  onPressed: () => _downloadReport(report),
                  tooltip: 'Download',
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: Icons.share_rounded,
                  color: _infoGradient[0],
                  onPressed: () => _shareReport(report),
                  tooltip: 'Share',
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: Icons.visibility_rounded,
                  color: _primaryGradient[0],
                  onPressed: () => _viewReport(report),
                  tooltip: 'View',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case ReportStatus.completed:
        color = _successGradient[0];
        icon = Icons.check_circle;
        break;
      case ReportStatus.generating:
        color = _warningGradient[0];
        icon = Icons.hourglass_empty;
        break;
      case ReportStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
      case ReportStatus.scheduled:
        color = _infoGradient[0];
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    if (_templates.isEmpty) {
      return _buildEmptyState(
        icon: Icons.dashboard_outlined,
        title: 'No Templates Available',
        message: 'Templates will appear here',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _infoGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Report Templates',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._templates.map((template) => _buildTemplateCard(template)),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(ReportTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                Expanded(
                  child: Text(
                    template.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildGradientButton(
                  label: 'Generate',
                  icon: Icons.play_arrow,
                  gradient: _successGradient,
                  onPressed: () => _generateFromTemplate(template),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              template.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: template.sections.map((section) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryGradient[0].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: _primaryGradient[0],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesTab() {
    if (_schedules.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule_outlined,
        title: 'No Scheduled Reports',
        message: 'Schedule reports to run automatically',
        actionLabel: 'Schedule Report',
        onAction: _showScheduleReportDialog,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                      gradient: const LinearGradient(colors: _warningGradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Scheduled Reports',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildGradientButton(
                label: 'Add',
                icon: Icons.add,
                gradient: _warningGradient,
                onPressed: _showScheduleReportDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._schedules.map((schedule) => _buildScheduleCard(schedule)),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ReportSchedule schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: schedule.isActive
              ? _successGradient[0].withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                Text(
                  'Template: ${schedule.reportTemplateId}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: schedule.isActive,
                  onChanged: (value) => _toggleSchedule(schedule, value),
                  activeThumbColor: _successGradient[0],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildScheduleInfo(
                  Icons.repeat,
                  schedule.frequency.name.toUpperCase(),
                ),
                const SizedBox(width: 16),
                _buildScheduleInfo(
                  Icons.access_time,
                  DateFormat('MMM dd, HH:mm').format(schedule.nextRun),
                ),
                const SizedBox(width: 16),
                _buildScheduleInfo(
                  Icons.people,
                  '${schedule.recipients.length} recipients',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              _buildGradientButton(
                label: actionLabel,
                icon: Icons.add,
                gradient: _primaryGradient,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateReportDialog() {
    ReportType selectedType = ReportType.performance;
    TimePeriod selectedPeriod = TimePeriod.month;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Create New Report',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text('Report Type', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ReportType.values.map((type) {
                  final isSelected = selectedType == type;
                  return ChoiceChip(
                    label: Text(type.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() => selectedType = type);
                      }
                    },
                    selectedColor: _primaryGradient[0],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[800],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Time Period', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TimePeriod.values.map((period) {
                  final isSelected = selectedPeriod == period;
                  return ChoiceChip(
                    label: Text(period.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() => selectedPeriod = period);
                      }
                    },
                    selectedColor: _infoGradient[0],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[800],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: _primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: MaterialButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _generateReport(selectedType, selectedPeriod);
                        },
                        child: const Text(
                          'Generate Report',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleReportDialog() {
    _showSnackBar('Schedule report feature coming soon');
  }

  void _generateReport(ReportType type, TimePeriod period) async {
    _showSnackBar('Generating ${type.name} report...');
    await Future.delayed(const Duration(seconds: 2));
    await _loadReportingData();
    _showSnackBar('Report generated successfully!');
  }

  void _generateFromTemplate(ReportTemplate template) async {
    _showSnackBar('Generating report from ${template.name}...');
    await Future.delayed(const Duration(seconds: 2));
    await _loadReportingData();
    _showSnackBar('Report generated successfully!');
  }

  void _downloadReport(Report report) {
    _showSnackBar('Downloading ${report.title}...');
  }

  void _shareReport(Report report) {
    _showSnackBar('Sharing ${report.title}...');
  }

  void _viewReport(Report report) {
    _showSnackBar('Opening ${report.title}...');
  }

  void _toggleSchedule(ReportSchedule schedule, bool isActive) {
    _showSnackBar(isActive ? 'Schedule activated' : 'Schedule deactivated');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

