import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GoogleDirectionsService {
  static const String _apiKey = 'AIzaSyDUMMY_API_KEY'; // Replace with actual API key
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  Future<Map<String, dynamic>?> getDirections(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey&mode=driving'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching directions: $e');
      return null;
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  double getRouteDistance(Map<String, dynamic> directionsData) {
    if (directionsData['routes'] != null && directionsData['routes'].isNotEmpty) {
      final route = directionsData['routes'][0];
      final legs = route['legs'];
      if (legs != null && legs.isNotEmpty) {
        final leg = legs[0];
        final distance = leg['distance'];
        if (distance != null && distance['value'] != null) {
          return distance['value'] / 1000.0; // Convert meters to kilometers
        }
      }
    }
    return 0.0;
  }

  Duration getRouteDuration(Map<String, dynamic> directionsData) {
    if (directionsData['routes'] != null && directionsData['routes'].isNotEmpty) {
      final route = directionsData['routes'][0];
      final legs = route['legs'];
      if (legs != null && legs.isNotEmpty) {
        final leg = legs[0];
        final duration = leg['duration'];
        if (duration != null && duration['value'] != null) {
          return Duration(seconds: duration['value']);
        }
      }
    }
    return Duration.zero;
  }
}