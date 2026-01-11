# WebSocket Real-time Telemetry Testing Guide

This guide explains how to test the real-time WebSocket telemetry system implemented for AIVONITY.

## Overview

The WebSocket-based real-time communication system includes:

1. **Backend WebSocket Server** - Handles real-time connections and message broadcasting
2. **Flutter WebSocket Client** - Manages connections with automatic reconnection
3. **Telemetry Service** - Processes and streams real-time vehicle data
4. **Test Simulator** - Generates realistic telemetry data for testing

## Architecture

```
Flutter App ←→ WebSocket Client ←→ Backend WebSocket Server ←→ Telemetry API
     ↑                                        ↑
     └── Real-time UI Updates                 └── Data Broadcasting
```

## Features Implemented

### ✅ WebSocket Server (Backend)

- Real-time message broadcasting
- Connection management with heartbeat
- Group-based messaging (vehicle-specific, user-specific)
- Automatic cleanup of stale connections
- Error handling and reconnection support

### ✅ WebSocket Client (Flutter)

- Automatic connection management
- Exponential backoff reconnection
- Message type routing
- Connection state monitoring
- Error handling and recovery

### ✅ Telemetry Service (Flutter)

- Real-time telemetry data streaming
- Vehicle status monitoring
- Alert management
- Connection state tracking

### ✅ Real-time Dashboard (Flutter)

- Live telemetry display
- Connection status indicator
- Real-time alerts with notifications
- Alert acknowledgment system

## Testing Instructions

### 1. Start the Backend Server

```bash
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The server will start with WebSocket endpoints:

- `ws://localhost:8000/ws/telemetry/{vehicle_id}` - Vehicle telemetry
- `ws://localhost:8000/ws/alerts/{user_id}` - User alerts
- `ws://localhost:8000/ws/chat/{user_id}` - AI chat (future use)

### 2. Run the Flutter App

```bash
flutter run
```

The app will show the Telemetry Dashboard with:

- Connection status indicator
- Real-time telemetry metrics
- Alert notifications
- Connect/Disconnect controls

### 3. Simulate Telemetry Data

Run the test simulator to generate realistic telemetry data:

```bash
cd backend
python test_websocket_telemetry.py
```

This will:

- Connect to the telemetry WebSocket
- Send realistic vehicle data every 5 seconds
- Occasionally generate anomalous data (alerts)
- Send test alerts to demonstrate the alert system

### 4. Observe Real-time Updates

In the Flutter app, you should see:

- ✅ Connection status changes to "Connected"
- 📊 Real-time telemetry data updates every 5 seconds
- 🚨 Alert notifications when anomalies are detected
- 📱 Snackbar notifications for new alerts

## WebSocket Message Types

### Telemetry Updates

```json
{
  "type": "telemetry_update",
  "data": {
    "vehicle_id": "test-vehicle-123",
    "timestamp": "2024-01-01T12:00:00Z",
    "speed": 65.5,
    "engine_metrics": {
      "temperature": 95.2,
      "rpm": 2500,
      "oil_pressure": 45.8
    },
    "battery_metrics": {
      "voltage": 13.8,
      "level": 85.0
    },
    "fuel_metrics": {
      "level": 67.5,
      "consumption": 8.2
    },
    "location": {
      "latitude": 40.7128,
      "longitude": -74.006
    }
  }
}
```

### Alert Messages

```json
{
  "type": "alert",
  "data": {
    "id": "alert-001",
    "type": "engine_overheat",
    "severity": "critical",
    "message": "Engine temperature critically high",
    "timestamp": "2024-01-01T12:00:00Z",
    "acknowledged": false
  }
}
```

### Heartbeat Messages

```json
{
  "type": "heartbeat",
  "data": {
    "timestamp": "2024-01-01T12:00:00Z",
    "server_status": "healthy"
  }
}
```

## Error Handling & Reconnection

The system includes robust error handling:

### Client-side (Flutter)

- **Automatic Reconnection**: Exponential backoff with max 5 attempts
- **Connection State Monitoring**: Real-time connection status updates
- **Message Queuing**: Messages are queued during disconnection
- **Error Recovery**: Graceful handling of network issues

### Server-side (Backend)

- **Heartbeat Monitoring**: Detects and cleans up stale connections
- **Connection Limits**: Prevents server overload
- **Error Logging**: Comprehensive error tracking
- **Graceful Shutdown**: Proper cleanup on server restart

## Performance Considerations

### Optimizations Implemented

- **Message Batching**: Efficient handling of high-frequency data
- **Connection Pooling**: Reuse of WebSocket connections
- **Memory Management**: Automatic cleanup of old data
- **Bandwidth Optimization**: Compressed message format

### Monitoring

- Connection statistics available via `/health` endpoint
- Real-time metrics for connection count and message throughput
- Performance logging for debugging

## Troubleshooting

### Common Issues

1. **Connection Failed**

   - Ensure backend server is running on port 8000
   - Check firewall settings
   - Verify WebSocket URL format

2. **No Data Updates**

   - Run the test simulator script
   - Check WebSocket connection status
   - Verify vehicle ID matches in simulator and app

3. **Frequent Disconnections**
   - Check network stability
   - Increase heartbeat interval if needed
   - Monitor server logs for errors

### Debug Commands

```bash
# Check WebSocket connections
curl http://localhost:8000/health

# Monitor server logs
tail -f backend/logs/app.log

# Test WebSocket manually
wscat -c ws://localhost:8000/ws/telemetry/test-vehicle-123
```

## Next Steps

This implementation provides the foundation for:

- Real-time vehicle monitoring dashboards
- Predictive maintenance alerts
- Fleet management systems
- Emergency response systems
- Performance analytics

The WebSocket infrastructure is ready for production use with proper scaling and security measures.
