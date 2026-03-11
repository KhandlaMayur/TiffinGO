import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';

class TomTomRoute {
  final double distance; // in meters
  final int duration; // in seconds
  final List<LatLng> routePoints; // polyline
  final String summary;

  TomTomRoute({
    required this.distance,
    required this.duration,
    required this.routePoints,
    this.summary = '',
  });

  /// Get distance in kilometers
  double get distanceInKm => distance / 1000;

  /// Get duration formatted as string (e.g., "15 mins", "1 hr 30 mins")
  String get durationFormatted {
    final minutes = (duration / 60).toInt();
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return '$mins mins';
    } else if (mins == 0) {
      return '$hours hr${hours > 1 ? 's' : ''}';
    } else {
      return '$hours hr${hours > 1 ? 's' : ''} $mins mins';
    }
  }

  /// Get distance formatted (e.g., "5.2 km")
  String get distanceFormatted => '${distanceInKm.toStringAsFixed(1)} km';
}

class TomTomRoutingService {
  static const String _baseUrl = 'https://api.tomtom.com/routing/1/calculateRoute';

  /// Calculate route between two coordinates using TomTom Routing API
  static Future<TomTomRoute?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final String url =
          '$_baseUrl/$startLat%2C$startLng%3A$endLat%2C$endLng/json'
          '?key=${ApiConfig.tomTomApiKey}'
          '&routeType=fastest'
          '&traffic=true';

      debugPrint(['TomTom Routing API Request', 'URL=$url'].join('\n'));

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
        onTimeout: () => http.Response('timeout', 408),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint(['TomTom API Response Success', 'Routes: ${data['routes']?.length ?? 0}'].join('\n'));

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0]; // Get first (fastest) route
          final legs = route['legs'] as List;

          // Parse route points from all legs
          List<LatLng> routePoints = [];
          double totalDistance = 0;
          int totalDuration = 0;

          for (var leg in legs) {
            totalDistance += (leg['summary']['lengthInMeters'] as num).toDouble();
            totalDuration += (leg['summary']['travelTimeInSeconds'] as num).toInt();

            // Decode polyline if available
            if (leg['points'] != null) {
              for (var point in leg['points']) {
                routePoints.add(LatLng(
                  (point['latitude'] as num).toDouble(),
                  (point['longitude'] as num).toDouble(),
                ));
              }
            }
          }

          debugPrint(
            ['Route Calculated',
              'Distance: ${totalDistance / 1000} km',
              'Duration: ${totalDuration / 60} mins',
              'Points: ${routePoints.length}'].join('\n')
          );

          return TomTomRoute(
            distance: totalDistance,
            duration: totalDuration,
            routePoints: routePoints,
            summary: '${(totalDistance / 1000).toStringAsFixed(1)} km • ${((totalDuration / 60).toInt())} mins',
          );
        }
      } else {
        debugPrint('TomTom API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('TomTom Routing Error: $e');
    }
    return null;
  }
}
