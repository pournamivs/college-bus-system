class ApiConstants {
  static const String _envBaseUrl = String.fromEnvironment(
    'TRACKMYBUS_BASE_URL',
    defaultValue: 'http://192.168.1.100:8000',
  );

  static String _resolvedApiBaseUrl = _envBaseUrl;

  static String get apiBaseUrl => _resolvedApiBaseUrl;

  static List<String> get candidateApiBaseUrls => [
    'https://trackmybus-backend.onrender.com', // Speculative Render (User provided)
    'https://college-bus-system.onrender.com', // Speculative Render (Repo name)
    _envBaseUrl, // Real device on same WiFi (default)
    'http://10.0.2.2:8000', // Android emulator host loopback
    'http://127.0.0.1:8000', // Desktop/web local backend
  ].toSet().toList();

  static void setApiBaseUrl(String baseUrl) {
    _resolvedApiBaseUrl = baseUrl;
  }

  static String get wsBaseUrl {
    if (apiBaseUrl.startsWith('https://')) {
      return apiBaseUrl.replaceFirst('https://', 'wss://');
    }
    return apiBaseUrl.replaceFirst('http://', 'ws://');
  }
}
