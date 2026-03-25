import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class DiscoveryService {
  static Future<void> discoverApi() async {
    final candidates = ApiConstants.candidateApiBaseUrls;
    
    // Create a list of futures that probe each URL
    final probes = candidates.map((url) => _probe(url)).toList();
    
    try {
      // Return the first one that succeeds
      final winner = await Future.any(probes.map((p) => p.then((res) {
        if (res != null) return res;
        throw Exception('Failed');
      })));
      
      ApiConstants.setApiBaseUrl(winner);
      print('Discovered Backend at: $winner');
    } catch (e) {
      print('Discovery failed: No active backend found among candidates.');
    }
  }

  static Future<String?> _probe(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        return url;
      }
    } catch (_) {}
    return null;
  }
}
