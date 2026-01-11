import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../models/reporting.dart';
import '../models/analytics.dart';
import '../services/reporting_service.dart';

class ReportsScreen extends StatefulWidget {
  final String vehicleId;

  const ReportsScreen({super.key, required this.vehicleId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportingService _reportingService;
  List<Report> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reportingService = GetIt.instance<ReportingService>();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reports = await _reportingService.getReports(widget.vehicleId);
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load reports: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateReportDialog,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : _buildReportsList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Reports',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadReports, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Generated Reports',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateReportDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('New Report'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                return _buildReportCard(_reports[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(report.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generated: ${DateFormat('MMM dd, yyyy').format(report.generatedDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Type: ${report.type.name.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _downloadReport(report),
                      tooltip: 'Download',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _shareReport(report),
                      tooltip: 'Share',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case ReportStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case ReportStatus.generating:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case ReportStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
      case ReportStatus.scheduled:
        color = Colors.blue;
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ReportType>(
              decoration: const InputDecoration(labelText: 'Report Type'),
              items: ReportType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TimePeriod>(
              decoration: const InputDecoration(labelText: 'Time Period'),
              items: TimePeriod.values.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateReport();
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Generating report...')));
  }

  Future<void> _downloadReport(Report report) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Downloading ${report.title}...')));
  }

  Future<void> _shareReport(Report report) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Sharing ${report.title}...')));
  }
}

