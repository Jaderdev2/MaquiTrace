class MapboxConstants {
  static const String accessToken =
      String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

  // Mapbox Style Tile URLs (256px Retina @2x for crisp rendering on high-density screens)
  static String tileUrl(String styleId) =>
      'https://api.mapbox.com/styles/v1/$styleId/tiles/256/{z}/{x}/{y}@2x?access_token=$accessToken';

  // Predefined Mapbox Styles
  static final String navigationDay = tileUrl('mapbox/navigation-day-v1');
  static final String navigationNight = tileUrl('mapbox/navigation-night-v1');
  static final String satelliteStreets = tileUrl('mapbox/satellite-streets-v12');
  static final String streets = tileUrl('mapbox/streets-v12');

  // Base API URLs
  static const String directionsBaseUrl =
      'https://api.mapbox.com/directions/v5/mapbox/driving';
  static const String geocodingBaseUrl =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';
}
