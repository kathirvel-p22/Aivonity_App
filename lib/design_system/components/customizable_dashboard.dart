import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Widget configuration for dashboard customization
class DashboardWidget {
  final String id;
  final String title;
  final IconData icon;
  final Widget Function(BuildContext) builder;
  final Size defaultSize;
  bool isVisible;
  int position;

  DashboardWidget({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
    this.defaultSize = const Size(2, 2),
    this.isVisible = true,
    this.position = 0,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'isVisible': isVisible, 'position': position};
  }

  factory DashboardWidget.fromJson(
    Map<String, dynamic> json,
    DashboardWidget template,
  ) {
    return DashboardWidget(
      id: template.id,
      title: template.title,
      icon: template.icon,
      builder: template.builder,
      defaultSize: template.defaultSize,
      isVisible: json['isVisible'] ?? true,
      position: json['position'] ?? 0,
    );
  }
}

/// Manager for dashboard customization
class DashboardManager extends ChangeNotifier {
  static const String _dashboardKey = 'dashboard_config';

  List<DashboardWidget> _widgets = [];
  bool _isEditMode = false;

  List<DashboardWidget> get widgets => _widgets;
  bool get isEditMode => _isEditMode;

  List<DashboardWidget> get visibleWidgets =>
      _widgets.where((w) => w.isVisible).toList()
        ..sort((a, b) => a.position.compareTo(b.position));

  /// Initialize dashboard with default widgets
  void initialize(List<DashboardWidget> defaultWidgets) {
    _widgets = List.from(defaultWidgets);
    _loadConfiguration();
  }

  /// Load saved dashboard configuration
  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_dashboardKey);

      if (configJson != null) {
        final config = json.decode(configJson) as List;
        final savedWidgets = <DashboardWidget>[];

        for (final widgetConfig in config) {
          final template = _widgets.firstWhere(
            (w) => w.id == widgetConfig['id'],
            orElse: () => _widgets.first,
          );
          savedWidgets.add(DashboardWidget.fromJson(widgetConfig, template));
        }

        // Merge with any new widgets that weren't saved
        for (final widget in _widgets) {
          if (!savedWidgets.any((w) => w.id == widget.id)) {
            savedWidgets.add(widget);
          }
        }

        _widgets = savedWidgets;
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, use default configuration
      debugPrint('Failed to load dashboard configuration: $e');
    }
  }

  /// Save dashboard configuration
  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final config = _widgets.map((w) => w.toJson()).toList();
      await prefs.setString(_dashboardKey, json.encode(config));
    } catch (e) {
      debugPrint('Failed to save dashboard configuration: $e');
    }
  }

  /// Toggle edit mode
  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  /// Toggle widget visibility
  Future<void> toggleWidgetVisibility(String widgetId) async {
    final widget = _widgets.firstWhere((w) => w.id == widgetId);
    widget.isVisible = !widget.isVisible;
    notifyListeners();
    await _saveConfiguration();
  }

  /// Reorder widgets
  Future<void> reorderWidgets(int oldIndex, int newIndex) async {
    final visibleWidgets = this.visibleWidgets;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final widget = visibleWidgets.removeAt(oldIndex);
    visibleWidgets.insert(newIndex, widget);

    // Update positions
    for (int i = 0; i < visibleWidgets.length; i++) {
      visibleWidgets[i].position = i;
    }

    notifyListeners();
    await _saveConfiguration();
  }

  /// Reset to default configuration
  Future<void> resetToDefault() async {
    for (int i = 0; i < _widgets.length; i++) {
      _widgets[i].isVisible = true;
      _widgets[i].position = i;
    }
    notifyListeners();
    await _saveConfiguration();
  }
}

/// Customizable dashboard widget
class CustomizableDashboard extends StatefulWidget {
  final List<DashboardWidget> widgets;
  final EdgeInsetsGeometry padding;

  const CustomizableDashboard({
    super.key,
    required this.widgets,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<CustomizableDashboard> createState() => _CustomizableDashboardState();
}

class _CustomizableDashboardState extends State<CustomizableDashboard> {
  late DashboardManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = DashboardManager();
    _manager.initialize(widget.widgets);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, child) {
        return Column(
          children: [
            // Dashboard controls
            if (_manager.isEditMode) _buildEditControls(),

            // Dashboard content
            Expanded(
              child: _manager.isEditMode
                  ? _buildEditableDashboard()
                  : _buildNormalDashboard(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit),
          const SizedBox(width: 8),
          const Text('Customize Dashboard'),
          const Spacer(),
          TextButton(
            onPressed: _manager.resetToDefault,
            child: const Text('Reset'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _manager.toggleEditMode,
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalDashboard() {
    final visibleWidgets = _manager.visibleWidgets;

    return GridView.builder(
      padding: widget.padding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: visibleWidgets.length,
      itemBuilder: (context, index) {
        final widget = visibleWidgets[index];
        return widget.builder(context);
      },
    );
  }

  Widget _buildEditableDashboard() {
    final visibleWidgets = _manager.visibleWidgets;

    return Column(
      children: [
        // Visible widgets (reorderable)
        Expanded(
          child: ReorderableListView.builder(
            padding: widget.padding as EdgeInsets?,
            itemCount: visibleWidgets.length,
            onReorder: _manager.reorderWidgets,
            itemBuilder: (context, index) {
              final widget = visibleWidgets[index];
              return Card(
                key: ValueKey(widget.id),
                child: ListTile(
                  leading: Icon(widget.icon),
                  title: Text(widget.title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drag_handle),
                      IconButton(
                        icon: const Icon(Icons.visibility_off),
                        onPressed: () =>
                            _manager.toggleWidgetVisibility(widget.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Hidden widgets
        if (_manager.widgets.any((w) => !w.isVisible)) ...[
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Hidden Widgets'),
          ),
          ...(_manager.widgets
              .where((w) => !w.isVisible)
              .map(
                (widget) => Card(
                  child: ListTile(
                    leading: Icon(widget.icon, color: Colors.grey),
                    title: Text(
                      widget.title,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () =>
                          _manager.toggleWidgetVisibility(widget.id),
                    ),
                  ),
                ),
              )),
        ],
      ],
    );
  }
}

/// Dashboard customization button
class DashboardCustomizeButton extends StatelessWidget {
  final DashboardManager manager;

  const DashboardCustomizeButton({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: manager,
      builder: (context, child) {
        return FloatingActionButton(
          onPressed: manager.toggleEditMode,
          child: Icon(manager.isEditMode ? Icons.check : Icons.edit),
        );
      },
    );
  }
}

