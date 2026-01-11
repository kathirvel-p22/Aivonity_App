# Google Maps Integration Setup

This document provides instructions for setting up Google Maps integration for the service center discovery feature.

## Prerequisites

1. Google Cloud Platform account
2. Google Maps Platform API access
3. Flutter development environment

## Setup Steps

### 1. Enable Google Maps APIs

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
   - Directions API

### 2. Create API Key

1. In the Google Cloud Console, go to "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy the generated API key
4. Restrict the API key to your specific APIs and applications for security

### 3. Configure the Application

#### Option 1: Update Configuration File

1. Open `lib/config/api_config.dart`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key

#### Option 2: Use Environment Variables (Recommended for Production)

1. Create a `.env` file in the project root
2. Add your API key: `GOOGLE_MAPS_API_KEY=your_actual_api_key`
3. Update the configuration to load from environment variables

### 4. Platform-Specific Setup

#### Android Setup

1. Open `android/app/src/main/AndroidManifest.xml`
2. Add the following inside the `<application>` tag:

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

#### iOS Setup

1. Open `ios/Runner/AppDelegate.swift`
2. Add the following import: `import GoogleMaps`
3. In the `application` method, add:

```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

### 5. Permissions

#### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS Permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to find nearby service centers.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to find nearby service centers.</string>
```

## Features Implemented

### Service Center Discovery

- **Location-based search**: Find service centers within a specified radius
- **Filtering**: Filter by distance, rating, services, and availability
- **Sorting**: Sort by distance, rating, or estimated wait time
- **Real-time data**: Get current status and working hours

### Interactive Maps

- **Custom markers**: Different colors based on rating and availability
- **Info windows**: Quick service center information
- **User location**: Show current position on the map
- **Zoom controls**: Navigate and explore the map

### Service Center Details

- **Comprehensive information**: Name, address, rating, services
- **Contact options**: Phone number and navigation buttons
- **Service listings**: Available services and specializations
- **Wait time estimates**: Estimated service wait times

## API Usage and Limits

- **Places API**: Used for searching service centers
- **Geocoding API**: Used for address resolution
- **Maps SDK**: Used for map display and interaction

Monitor your API usage in the Google Cloud Console to avoid unexpected charges.

## Security Best Practices

1. **Restrict API keys**: Limit usage to specific APIs and applications
2. **Use environment variables**: Don't commit API keys to version control
3. **Implement rate limiting**: Prevent excessive API calls
4. **Monitor usage**: Set up billing alerts and usage quotas

## Troubleshooting

### Common Issues

1. **Map not loading**: Check API key configuration and network connectivity
2. **No service centers found**: Verify Places API is enabled and location permissions are granted
3. **Location access denied**: Ensure location permissions are properly configured

### Debug Mode

Enable debug logging by setting the log level in the MapsService configuration.

## Testing

Test the integration with:

1. Different locations and search radii
2. Various filter combinations
3. Network connectivity issues
4. Location permission scenarios

## Production Deployment

Before deploying to production:

1. Use secure API key storage
2. Implement proper error handling
3. Add analytics and monitoring
4. Test with real device locations
5. Optimize API call frequency
