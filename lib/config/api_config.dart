/// API Configuration
/// IMPORTANT: Keep this file secure and never commit it with a real API key
class ApiConfig {
  /// Gemini API Key for grocery item extraction
  static const String geminiApiKey = 'AIzaSyDm82-gONGji37YPSafRDVDI2rwnAmxWlE';

  /// API Configuration
  static const String geminiModel = 'gemini-pro';
  static const double temperature = 0.3;
  static const int maxOutputTokens = 1024;

  /// Check if API is configured
  static bool get isConfigured => geminiApiKey.isNotEmpty && geminiApiKey != 'YOUR_API_KEY_HERE';
}
