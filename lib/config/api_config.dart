class ApiConfig {
  // Base API URL for the backend service
  static const String baseUrl = 'https://api.aivonity.com/v1';

  // Google Maps API configuration
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // In production, these should be loaded from:
  // - Environment variables
  // - Secure storage
  // - Remote configuration service

  static const Map<String, String> apiEndpoints = {
    'places': 'https://maps.googleapis.com/maps/api/place',
    'geocoding': 'https://maps.googleapis.com/maps/api/geocode',
    'directions': 'https://maps.googleapis.com/maps/api/directions',
  };

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

