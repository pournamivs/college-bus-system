class ApiConstants {
  // ✅ PRODUCTION BACKEND
  static const String apiBaseUrl = "https://trackmybus-backend.onrender.com";

  // ✅ WebSocket URL (auto-derived from apiBaseUrl)
  static String get wsBaseUrl {
    if (apiBaseUrl.startsWith('https://')) {
      return apiBaseUrl.replaceFirst('https://', 'wss://');
    }
    return apiBaseUrl.replaceFirst('http://', 'ws://');
  }

  // Obsolete candidates (removed for performance)
  static const List<String> candidateApiBaseUrls = [apiBaseUrl];
  
  // Obsolete setter (removed for security)
  static void setApiBaseUrl(String url) {}
}