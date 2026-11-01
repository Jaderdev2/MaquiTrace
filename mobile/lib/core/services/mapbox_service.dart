import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import '../constants/mapbox_constants.dart';

class MapboxRouteResult {
  final List<ll.LatLng> points;
  final double distanceKm;
  final double durationMinutes;
  final String summary;
  final List<String> steps;

  const MapboxRouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.summary,
    this.steps = const [],
  });

  String get formattedDuration {
    final totalMin = durationMinutes.round();
    if (totalMin < 60) {
      return '$totalMin min';
    }
    final hours = totalMin ~/ 60;
    final mins = totalMin % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
}

class MapboxSearchResult {
  final String id;
  final String text;
  final String placeName;
  final ll.LatLng center;

  const MapboxSearchResult({
    required this.id,
    required this.text,
    required this.placeName,
    required this.center,
  });

  factory MapboxSearchResult.fromJson(Map<String, dynamic> json) {
    final centerList = json['center'] as List<dynamic>? ?? [0.0, 0.0];
    final lng = (centerList[0] as num).toDouble();
    final lat = (centerList[1] as num).toDouble();

    return MapboxSearchResult(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      placeName: json['place_name']?.toString() ?? '',
      center: ll.LatLng(lat, lng),
    );
  }
}

class MapboxService {
  final http.Client _client = http.Client();

  /// Consulta la ruta de conducción real por carretera entre dos puntos
  Future<MapboxRouteResult?> getDrivingRoute({
    required ll.LatLng origin,
    required ll.LatLng destination,
  }) async {
    try {
      final originStr = '${origin.longitude},${origin.latitude}';
      final destStr = '${destination.longitude},${destination.latitude}';
      final url = Uri.parse(
        '${MapboxConstants.directionsBaseUrl}/$originStr;$destStr'
        '?geometries=geojson&overview=full&steps=true&language=es'
        '&access_token=${MapboxConstants.accessToken}',
      );

      final response = await _client.get(url).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List<dynamic>? ?? [];

          final points = coords.map<ll.LatLng>((coord) {
            final list = coord as List<dynamic>;
            return ll.LatLng(
              (list[1] as num).toDouble(),
              (list[0] as num).toDouble(),
            );
          }).toList();

          final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSecs = (route['duration'] as num?)?.toDouble() ?? 0.0;
          final summary = (route['legs'] as List<dynamic>?)?.firstOrNull?['summary']?.toString() ?? 'Vía terrestre';

          final stepsList = <String>[];
          final legs = route['legs'] as List<dynamic>?;
          if (legs != null && legs.isNotEmpty) {
            final steps = legs.first['steps'] as List<dynamic>? ?? [];
            for (final s in steps) {
              final instruction = s['maneuver']?['instruction']?.toString();
              if (instruction != null && instruction.isNotEmpty) {
                stepsList.add(instruction);
              }
            }
          }

          return MapboxRouteResult(
            points: points,
            distanceKm: distanceMeters / 1000.0,
            durationMinutes: durationSecs / 60.0,
            summary: summary,
            steps: stepsList,
          );
        }
      }
    } catch (_) {
      // Fallback silencioso si la red falla
    }
    return null;
  }

  /// Busca lugares, direcciones y puntos de interés mediante Mapbox Places
  Future<List<MapboxSearchResult>> searchPlaces(
    String query, {
    ll.LatLng? proximity,
  }) async {
    final clean = query.trim();
    if (clean.length < 2) return [];

    try {
      final encoded = Uri.encodeComponent(clean);
      var urlStr = '${MapboxConstants.geocodingBaseUrl}/$encoded.json'
          '?access_token=${MapboxConstants.accessToken}&country=CO&language=es&limit=6';

      if (proximity != null) {
        urlStr += '&proximity=${proximity.longitude},${proximity.latitude}';
      }

      final response = await _client.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];
        return features
            .map((f) => MapboxSearchResult.fromJson(f as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  /// Geocodificación inversa: Convierte coordenadas a dirección o nombre de lugar
  Future<String?> reverseGeocode(ll.LatLng coords) async {
    try {
      final url = Uri.parse(
        '${MapboxConstants.geocodingBaseUrl}/${coords.longitude},${coords.latitude}.json'
        '?access_token=${MapboxConstants.accessToken}&language=es&limit=1',
      );

      final response = await _client.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          return features.first['place_name']?.toString();
        }
      }
    } catch (_) {}

    return null;
  }
}

