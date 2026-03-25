class ApiConstants {
  // ✅ HARDCODED PRODUCTION BACKEND (Final Lockdown)
  static const String apiBaseUrl = "https://trackmybus-backend.onrender.com";

  // ✅ WebSocket URL (wss:// for Render)
  static String get wsBaseUrl {
    return "wss://trackmybus-backend.onrender.com";
  }

  // Obsolete candidates (removed for extreme performance)
  static const List<String> candidateApiBaseUrls = [apiBaseUrl];
  
  // Obsolete setter (removed for demo stability)
  static void setApiBaseUrl(String url) {}
}