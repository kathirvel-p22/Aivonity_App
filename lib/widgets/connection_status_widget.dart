import 'package:flutter/material.dart';
import '../services/websocket_service.dart';

class ConnectionStatusWidget extends StatefulWidget {
  final WebSocketState connectionState;
  final DateTime? lastUpdate;
  final String? vehicleId;
  final VoidCallback? onReconnect;
  final VoidCallback? onDisconnect;

  const ConnectionStatusWidget({
    super.key,
    required this.connectionState,
    this.lastUpdate,
    this.vehicleId,
    this.onReconnect,
    this.onDisconnect,
  });

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for connected state
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation animation for connecting state
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(ConnectionStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connectionState != oldWidget.connectionState) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    switch (widget.connectionState) {
      case WebSocketState.connected:
        _rotationController.stop();
        _pulseController.repeat(reverse: true);
        break;
      case WebSocketState.connecting:
      case WebSocketState.reconnecting:
        _pulseController.stop();
        _rotationController.repeat();
        break;
      default:
        _pulseController.stop();
        _rotationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                _buildStatusIndicator(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connection Status',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButton(),
              ],
            ),

            const SizedBox(height: 16),

            // Connection details
            _buildConnectionDetails(),

            // Signal strength indicator
            if (widget.connectionState == WebSocketState.connected)
              _buildSignalStrength(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Widget indicator;

    switch (widget.connectionState) {
      case WebSocketState.connected:
        indicator = AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
        break;
      case WebSocketState.connecting:
      case WebSocketState.reconnecting:
        indicator = AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: const Icon(Icons.sync, color: Colors.orange, size: 20),
            );
          },
        );
        break;
      case WebSocketState.error:
        indicator = const Icon(Icons.error, color: Colors.red, size: 20);
        break;
      default:
        indicator = Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        );
    }

    return SizedBox(width: 24, height: 24, child: Center(child: indicator));
  }

  Widget _buildActionButton() {
    switch (widget.connectionState) {
      case WebSocketState.connected:
        return IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onDisconnect,
          tooltip: 'Disconnect',
          color: Colors.red,
        );
      case WebSocketState.connecting:
      case WebSocketState.reconnecting:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      default:
        return IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: widget.onReconnect,
          tooltip: 'Reconnect',
          color: Colors.blue,
        );
    }
  }

  Widget _buildConnectionDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Vehicle ID
          if (widget.vehicleId != null)
            _buildDetailRow(
              'Vehicle ID',
              widget.vehicleId!,
              Icons.directions_car,
            ),

          // Last update
          if (widget.lastUpdate != null)
            _buildDetailRow(
              'Last Update',
              _formatLastUpdate(widget.lastUpdate!),
              Icons.access_time,
            ),

          // Connection type
          _buildDetailRow('Protocol', 'WebSocket', Icons.wifi),

          // Server endpoint
          _buildDetailRow('Endpoint', 'localhost:8000', Icons.dns),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalStrength() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Signal Strength',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Signal bars
              ...List.generate(5, (index) {
                final isActive = index < 4; // Simulate good signal
                return Container(
                  margin: const EdgeInsets.only(right: 2),
                  width: 4,
                  height: 8 + (index * 3).toDouble(),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text(
                'Excellent',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.connectionState) {
      case WebSocketState.connected:
        return Colors.green;
      case WebSocketState.connecting:
      case WebSocketState.reconnecting:
        return Colors.orange;
      case WebSocketState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (widget.connectionState) {
      case WebSocketState.connected:
        return 'Connected';
      case WebSocketState.connecting:
        return 'Connecting...';
      case WebSocketState.reconnecting:
        return 'Reconnecting...';
      case WebSocketState.error:
        return 'Connection Error';
      default:
        return 'Disconnected';
    }
  }

  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}

