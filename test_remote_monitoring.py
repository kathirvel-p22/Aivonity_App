#!/usr/bin/env python3
"""
Simple test script for remote monitoring API
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000/api/vehicles"
VEHICLE_ID = "vehicle_001"

def test_location_update():
    """Test location update endpoint"""
    url = f"{BASE_URL}/{VEHICLE_ID}/location"
    data = {
        "vehicleId": VEHICLE_ID,
        "latitude": 37.7749,
        "longitude": -122.4194,
        "accuracy": 5.0,
        "speed": 25.5,
        "heading": 180.0,
        "timestamp": datetime.now().isoformat(),
        "distanceMoved": 150.0
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Location Update - Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Location Update Error: {e}")
        return False

def test_create_geofence():
    """Test geofence creation"""
    url = f"{BASE_URL}/{VEHICLE_ID}/geofences"
    data = {
        "name": "Home",
        "centerLatitude": 37.7749,
        "centerLongitude": -122.4194,
        "radius": 100.0,
        "type": "home"
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Create Geofence - Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Create Geofence Error: {e}")
        return False

def test_security_alert():
    """Test security alert creation"""
    url = f"{BASE_URL}/{VEHICLE_ID}/security-alerts"
    data = {
        "vehicleId": VEHICLE_ID,
        "alertType": "theft_detection",
        "severity": "high",
        "message": "Potential theft detected",
        "location": {"latitude": 37.7749, "longitude": -122.4194},
        "timestamp": datetime.now().isoformat(),
        "threats": ["Unauthorized movement", "Alarm triggered"]
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Security Alert - Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Security Alert Error: {e}")
        return False

def test_diagnostics_update():
    """Test diagnostics update"""
    url = f"{BASE_URL}/{VEHICLE_ID}/diagnostics"
    data = {
        "vehicleId": VEHICLE_ID,
        "timestamp": datetime.now().isoformat(),
        "batteryVoltage": 12.6,
        "engineTemperature": 95,
        "oilPressure": 35,
        "fuelLevel": 75,
        "diagnosticCodes": ["P0171"],
        "overallHealth": 85.5
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Diagnostics Update - Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Diagnostics Update Error: {e}")
        return False

def test_get_current_location():
    """Test get current location"""
    url = f"{BASE_URL}/{VEHICLE_ID}/location/current"
    
    try:
        response = requests.get(url)
        print(f"Get Current Location - Status: {response.status_code}")
        if response.status_code == 200:
            print(f"Response: {response.json()}")
        else:
            print(f"Error: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Get Current Location Error: {e}")
        return False

def test_get_health_status():
    """Test get vehicle health status"""
    url = f"{BASE_URL}/{VEHICLE_ID}/health-status"
    
    try:
        response = requests.get(url)
        print(f"Get Health Status - Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Get Health Status Error: {e}")
        return False

if __name__ == "__main__":
    print("Testing Remote Monitoring API...")
    print("=" * 50)
    
    # Note: These tests assume the backend server is running
    # Start the server with: uvicorn app.main:app --reload
    
    tests = [
        ("Location Update", test_location_update),
        ("Create Geofence", test_create_geofence),
        ("Security Alert", test_security_alert),
        ("Diagnostics Update", test_diagnostics_update),
        ("Get Current Location", test_get_current_location),
        ("Get Health Status", test_get_health_status),
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n--- {test_name} ---")
        success = test_func()
        results.append((test_name, success))
        print(f"Result: {'PASS' if success else 'FAIL'}")
    
    print("\n" + "=" * 50)
    print("Test Summary:")
    for test_name, success in results:
        status = "PASS" if success else "FAIL"
        print(f"  {test_name}: {status}")
    
    passed = sum(1 for _, success in results if success)
    total = len(results)
    print(f"\nOverall: {passed}/{total} tests passed")