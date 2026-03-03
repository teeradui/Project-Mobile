/// API Configuration
/// IMPORTANT: Keep this file secure and never commit it with a real API key
class ApiConfig {
  /// Gemini API Key for grocery item extraction
  static const String geminiApiKey = 'AIzaSyDprCE-kPO4kOsYzYBfD3v2llaqeYEUeUk';

  /// API Configuration
  static const String geminiModel = 'gemini-1.5-flash';
  static const double temperature = 0.3;
  static const int maxOutputTokens = 1024;

  /// Check if API is configured
  static bool get isConfigured =>
      geminiApiKey.isNotEmpty &&
      geminiApiKey != 'AIzaSyDprCE-kPO4kOsYzYBfD3v2llaqeYEUeUk';
}
