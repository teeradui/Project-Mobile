/// API Configuration
/// IMPORTANT: Keep this file secure and never commit it with a real API key
class ApiConfig {
  /// Gemini API Key for grocery item extraction
  static const String geminiApiKey = 'AIzaSyBr3ykbQIPgcWQGMw5bRDdaVAjsizYr-Yc';

  /// Spoonacular API Key for ingredient parsing and nutrition
  static const String spoonacularApiKey = '27bebe2baaf149449c2c707d07694fc1';

  /// API Configuration
  static const String geminiModel = 'gemini-pro';
  static const double temperature = 0.3;
  static const int maxOutputTokens = 1024;

  /// Check if Gemini API is configured
  static bool get isGeminiConfigured =>
      geminiApiKey.isNotEmpty &&
      geminiApiKey != 'AIzaSyBr3ykbQIPgcWQGMw5bRDdaVAjsizYr-Yc';

  /// Check if Spoonacular API is configured
  static bool get isSpoonacularConfigured =>
      spoonacularApiKey.isNotEmpty &&
      spoonacularApiKey != '27bebe2baaf149449c2c707d07694fc1';

  /// Check if any API is configured
  static bool get isConfigured => isGeminiConfigured || isSpoonacularConfigured;
}
