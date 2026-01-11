#!/usr/bin/env python3
"""
Test script to simulate real-time telemetry data via WebSocket
"""

import asyncio
import websockets
import json
import random
from datetime import datetime
import time

async def simulate_telemetry_client():
    """Simulate a vehicle sending telemetry data"""
    uri = "ws://localhost:8000/ws/telemetry/test-vehicle-123"
    
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ Connected to telemetry WebSocket")
            
            # Send initial connection message
            await websocket.send(json.dumps({
                "type": "client_info",
                "data": {
                    "vehicle_id": "test-vehicle-123",
                    "client_type": "vehicle_simulator"
                }
            }))
            
            # Simulate telemetry data every 5 seconds
            for i in range(20):  # Send 20 data points
                telemetry_data = {
                    "vehicle_id": "test-vehicle-123",
                    "timestamp": datetime.now().isoformat(),
                    "location": {
                        "latitude": 40.7128 + random.uniform(-0.01, 0.01),
                        "longitude": -74.0060 + random.uniform(-0.01, 0.01),
                        "altitude": random.uniform(0, 100)
                    },
                    "speed": random.uniform(0, 120),
                    "engine_metrics": {
                        "temperature": random.uniform(80, 110),
                        "rpm": random.uniform(800, 6000),
                        "oil_pressure": random.uniform(20, 60)
                    },
                    "battery_metrics": {
                        "voltage": random.uniform(11.5, 14.5),
                        "level": random.uniform(20, 100)
                    },
                    "fuel_metrics": {
                        "level": random.uniform(10, 100),
                        "consumption": random.uniform(5, 15)
                    },
                    "diagnostic_codes": [] if random.random() > 0.1 else ["P0301", "P0420"],
                    "environmental_data": {
                        "ambient_temp": random.uniform(-10, 40),
                        "humidity": random.uniform(30, 90)
                    }
                }
                
                # Occasionally generate anomalous data
                if random.random() < 0.2:  # 20% chance of anomaly
                    telemetry_data["engine_metrics"]["temperature"] = random.uniform(115, 130)
                    telemetry_data["engine_metrics"]["oil_pressure"] = random.uniform(5, 15)
                    print(f"🚨 Generating anomalous data (iteration {i+1})")
                
                message = {
                    "type": "telemetry_data",
                    "data": telemetry_data,
                    "timestamp": datetime.now().isoformat()
                }
                
                await websocket.send(json.dumps(message))
                print(f"📤 Sent telemetry data {i+1}/20")
                
                # Wait for 5 seconds before next data point
                await asyncio.sleep(5)
            
            print("✅ Finished sending telemetry data")
            
    except websockets.exceptions.ConnectionClosed:
        print("❌ WebSocket connection closed")
    except Exception as e:
        print(f"❌ Error: {e}")

async def simulate_alert_client():
    """Simulate sending alerts"""
    uri = "ws://localhost:8000/ws/alerts/test-user-456"
    
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ Connected to alerts WebSocket")
            
            # Wait a bit then send some test alerts
            await asyncio.sleep(10)
            
            alerts = [
                {
                    "id": "alert-001",
                    "type": "engine_overheat",
                    "severity": "critical",
                    "message": "Engine temperature critically high",
                    "timestamp": datetime.now().isoformat(),
                    "data": {"temperature": 125, "threshold": 110},
                    "acknowledged": False
                },
                {
                    "id": "alert-002", 
                    "type": "low_oil_pressure",
                    "severity": "high",
                    "message": "Oil pressure below safe levels",
                    "timestamp": datetime.now().isoformat(),
                    "data": {"pressure": 12, "threshold": 20},
                    "acknowledged": False
                }
            ]
            
            for alert in alerts:
                message = {
                    "type": "alert",
                    "data": alert,
                    "timestamp": datetime.now().isoformat()
                }
                
                await websocket.send(json.dumps(message))
                print(f"🚨 Sent alert: {alert['type']}")
                await asyncio.sleep(15)  # Wait 15 seconds between alerts
                
    except websockets.exceptions.ConnectionClosed:
        print("❌ Alerts WebSocket connection closed")
    except Exception as e:
        print(f"❌ Alerts error: {e}")

async def main():
    """Run both simulators concurrently"""
    print("🚀 Starting WebSocket telemetry simulation")
    print("📡 Make sure the AIVONITY backend is running on localhost:8000")
    print("📱 Connect your Flutter app to see real-time updates")
    print("-" * 60)
    
    # Run both simulators concurrently
    await asyncio.gather(
        simulate_telemetry_client(),
        simulate_alert_client()
    )

if __name__ == "__main__":
    asyncio.run(main())