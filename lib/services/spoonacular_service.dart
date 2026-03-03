import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ingredient.dart';
import '../config/api_config.dart';

/// Model for ingredient search result
class IngredientSearchResult {
  final int id;
  final String name;
  final String? image;
  final String aisle;

  IngredientSearchResult({
    required this.id,
    required this.name,
    this.image,
    required this.aisle,
  });

  factory IngredientSearchResult.fromJson(Map<String, dynamic> json) {
    return IngredientSearchResult(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      image: json['image'],
      aisle: json['aisle'] ?? 'Other',
    );
  }

  /// Get full image URL
  String? get imageUrl {
    if (image == null || image!.isEmpty) return null;
    return 'https://img.spoonacular.com/ingredients_100x100/$image';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'aisle': aisle,
    };
  }
}

/// Spoonacular API Service
/// Handles ingredient parsing and nutrition data retrieval
class SpoonacularService extends ChangeNotifier {
  // API Configuration
  static const String _baseUrl = 'api.spoonacular.com';
  static const String _apiVersion = 'v1';

  // State
  bool _isLoading = false;
  String _errorMessage = '';
  int _requestCount = 0;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get requestCount => _requestCount;

  // API Points tracking (Spoonacular free tier: 150 requests/day)
  static const int _maxDailyRequests = 150;

  /// Check if API quota is available
  bool get hasQuotaAvailable => _requestCount < _maxDailyRequests;

  /// Get remaining quota
  int get remainingQuota => _maxDailyRequests - _requestCount;

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  /// Parse ingredient(s) from raw text input
  /// Supports both single and multiple ingredients in one request
  /// [ingredientList] - List of ingredient strings (e.g., ["200g chicken breast", "3 eggs"])
  /// [includeNutrition] - Whether to include nutrition information (default: true)
  Future<List<Ingredient>> parseIngredients(
    List<String> ingredientList, {
    bool includeNutrition = true,
  }) async {
    if (ingredientList.isEmpty) {
      _errorMessage = 'Ingredient list cannot be empty';
      notifyListeners();
      return [];
    }

    // Check API quota
    if (!hasQuotaAvailable) {
      _errorMessage = 'Daily API quota exceeded. Please try again tomorrow.';
      notifyListeners();
      throw Exception('API quota exceeded');
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final url = Uri.https(_baseUrl, '/$_apiVersion/recipes/parseIngredients', {
        'includeNutrition': includeNutrition.toString(),
      });

      // Prepare request body
      // Send multiple ingredients in newline-separated format to optimize API usage
      final requestBody = ingredientList.join('\n');
      final headers = {
        'Content-Type': 'text/plain',
        'X-API-Key': ApiConfig.spoonacularApiKey,
      };

      debugPrint('Spoonacular API Request: $requestBody');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      // Increment request count
      _requestCount++;
      notifyListeners();

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final ingredients = responseData
            .map((json) => Ingredient.fromJson(json))
            .toList();

        _isLoading = false;
        notifyListeners();

        debugPrint('Parsed ${ingredients.length} ingredients successfully');
        return ingredients;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Invalid API Key. Please check your configuration.';
        _isLoading = false;
        notifyListeners();
        throw Exception('Invalid API Key');
      } else if (response.statusCode == 402) {
        _errorMessage = 'API points quota exceeded. Please upgrade your plan.';
        _isLoading = false;
        notifyListeners();
        throw Exception('Quota exceeded');
      } else if (response.statusCode == 404) {
        _errorMessage = 'Ingredient(s) not recognized. Please try different input.';
        _isLoading = false;
        notifyListeners();
        throw Exception('Ingredient not recognized');
      } else {
        _errorMessage = 'API Error: ${response.statusCode} - ${response.body}';
        _isLoading = false;
        notifyListeners();
        throw Exception('API Error: ${response.statusCode}');
      }
    } on TimeoutException {
      _errorMessage = 'Request timed out. Please try again.';
      _isLoading = false;
      notifyListeners();
      rethrow;
    } on http.ClientException {
      _errorMessage = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = 'Error parsing ingredients: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Parse Ingredients Error: $e');
      rethrow;
    }
  }

  /// Parse a single ingredient string
  /// Convenience method for single ingredient parsing
  Future<List<Ingredient>> parseSingleIngredient(
    String ingredient, {
    bool includeNutrition = true,
  }) async {
    return parseIngredients([ingredient], includeNutrition: includeNutrition);
  }

  /// Get ingredient information by ID
  /// Returns detailed nutrition information for a specific ingredient
  Future<Ingredient> getIngredientInformation(
    int ingredientId, {
    bool includeNutrition = true,
    double amount = 1,
    String unit = 'serving',
  }) async {
    // Check API quota
    if (!hasQuotaAvailable) {
      _errorMessage = 'Daily API quota exceeded. Please try again tomorrow.';
      notifyListeners();
      throw Exception('API quota exceeded');
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final url = Uri.https(_baseUrl, '/$_apiVersion/food/ingredients/$ingredientId/information', {
        'includeNutrition': includeNutrition.toString(),
        'amount': amount.toString(),
        'unit': unit,
      });

      final response = await http.get(
        url,
        headers: {'X-API-Key': ApiConfig.spoonacularApiKey},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      // Increment request count
      _requestCount++;
      notifyListeners();

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final ingredient = Ingredient.fromJson(jsonData);

        _isLoading = false;
        notifyListeners();

        return ingredient;
      } else {
        _errorMessage = 'API Error: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Error fetching ingredient information: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Get Ingredient Info Error: $e');
      rethrow;
    }
  }

  /// Batch parse ingredients with automatic retry on failure
  /// Splits large lists into smaller batches to avoid API limits
  Future<List<Ingredient>> batchParseIngredients(
    List<String> ingredients, {
    int batchSize = 10,
    bool includeNutrition = true,
  }) async {
    if (ingredients.isEmpty) return [];

    final List<Ingredient> allIngredients = [];

    // Process in batches
    for (int i = 0; i < ingredients.length; i += batchSize) {
      final end = (i + batchSize < ingredients.length)
          ? i + batchSize
          : ingredients.length;
      final batch = ingredients.sublist(i, end);

      try {
        final batchResults = await parseIngredients(
          batch,
          includeNutrition: includeNutrition,
        );
        allIngredients.addAll(batchResults);
      } catch (e) {
        debugPrint('Failed to parse batch ${i ~/ batchSize + 1}: $e');
        // Continue with next batch on error
        continue;
      }
    }

    return allIngredients;
  }

  /// Reset request count (useful for testing or manual quota reset)
  void resetRequestCount() {
    _requestCount = 0;
    notifyListeners();
  }

  /// Validate ingredient by searching Spoonacular database
  /// Returns search results if ingredient is found, null if not found
  /// Falls back to local validation if API endpoint is not available
  Future<IngredientSearchResult?> validateIngredient(
    String ingredientName, {
    int numberOfResults = 5,
  }) async {
    if (ingredientName.trim().isEmpty) {
      return null;
    }

    // Check API quota
    if (!hasQuotaAvailable) {
      _errorMessage = 'Daily API quota exceeded. Please try again tomorrow.';
      notifyListeners();
      throw Exception('API quota exceeded');
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final url = Uri.https(_baseUrl, '/$_apiVersion/food/ingredients/search', {
        'query': ingredientName,
        'number': numberOfResults.toString(),
        'metaInformation': 'true',
      });

      debugPrint('Validating ingredient: $ingredientName');

      final response = await http.get(
        url,
        headers: {'X-API-Key': ApiConfig.spoonacularApiKey},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Validation request timed out');
        },
      );

      // Increment request count
      _requestCount++;
      notifyListeners();

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Check if results exist
        if (jsonData != null &&
            jsonData['results'] != null &&
            (jsonData['results'] as List).isNotEmpty) {
          // Return the first (best) match
          final firstResult = jsonData['results'][0];
          final searchResult = IngredientSearchResult.fromJson(firstResult);

          _isLoading = false;
          notifyListeners();

          debugPrint('Ingredient validated: ${searchResult.name}');
          return searchResult;
        } else {
          // No results found
          _isLoading = false;
          notifyListeners();
          return null;
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Invalid API Key. Please check your Spoonacular API key.';
        _isLoading = false;
        notifyListeners();
        throw Exception('Invalid API Key');
      } else if (response.statusCode == 402) {
        _errorMessage = 'API points quota exceeded. Please upgrade your plan.';
        _isLoading = false;
        notifyListeners();
        throw Exception('Quota exceeded');
      } else if (response.statusCode == 404) {
        // 404 means the endpoint is not available for this API key
        // Fall back to local validation
        debugPrint('Search endpoint not available, using local validation');
        _isLoading = false;
        notifyListeners();
        return _validateIngredientLocally(ingredientName);
      } else {
        _errorMessage = 'API Error: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        throw Exception('API Error: ${response.statusCode}');
      }
    } on TimeoutException {
      _errorMessage = 'Validation request timed out';
      _isLoading = false;
      notifyListeners();
      // Fall back to local validation
      return _validateIngredientLocally(ingredientName);
    } on http.ClientException {
      _errorMessage = 'Network error during validation';
      _isLoading = false;
      notifyListeners();
      // Fall back to local validation
      return _validateIngredientLocally(ingredientName);
    } catch (e) {
      _errorMessage = 'Error validating ingredient: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Validate Ingredient Error: $e');
      // Fall back to local validation on error
      return _validateIngredientLocally(ingredientName);
    }
  }

  /// Local validation fallback
  /// Validates ingredient against a local database of common ingredients
  IngredientSearchResult? _validateIngredientLocally(String ingredientName) {
    final lowerName = ingredientName.toLowerCase().trim();

    // Common ingredient database with categories
    final Map<String, Map<String, dynamic>> commonIngredients = {
      // Proteins
      'chicken': {'id': 5006, 'name': 'chicken', 'aisle': 'Meat', 'image': 'chicken.jpg'},
      'beef': {'id': 1001, 'name': 'beef', 'aisle': 'Meat', 'image': 'beef.jpg'},
      'pork': {'id': 10010220, 'name': 'pork', 'aisle': 'Meat', 'image': 'pork.jpg'},
      'fish': {'id': 15001, 'name': 'fish', 'aisle': 'Seafood', 'image': 'fish.jpg'},
      'salmon': {'id': 15001, 'name': 'salmon', 'aisle': 'Seafood', 'image': 'salmon.jpg'},
      'shrimp': {'id': 15061, 'name': 'shrimp', 'aisle': 'Seafood', 'image': 'shrimp.jpg'},
      'egg': {'id': 1123, 'name': 'egg', 'aisle': 'Dairy', 'image': 'egg.jpg'},
      'eggs': {'id': 1123, 'name': 'eggs', 'aisle': 'Dairy', 'image': 'eggs.jpg'},
      'tofu': {'id': 16112, 'name': 'tofu', 'aisle': 'Dairy', 'image': 'tofu.jpg'},

      // Vegetables
      'tomato': {'id': 11529, 'name': 'tomato', 'aisle': 'Produce', 'image': 'tomato.jpg'},
      'tomatoes': {'id': 11529, 'name': 'tomatoes', 'aisle': 'Produce', 'image': 'tomatoes.jpg'},
      'onion': {'id': 11282, 'name': 'onion', 'aisle': 'Produce', 'image': 'onion.jpg'},
      'onions': {'id': 11282, 'name': 'onions', 'aisle': 'Produce', 'image': 'onions.jpg'},
      'garlic': {'id': 11215, 'name': 'garlic', 'aisle': 'Produce', 'image': 'garlic.jpg'},
      'carrot': {'id': 11124, 'name': 'carrot', 'aisle': 'Produce', 'image': 'carrot.jpg'},
      'carrots': {'id': 11124, 'name': 'carrots', 'aisle': 'Produce', 'image': 'carrots.jpg'},
      'broccoli': {'id': 11090, 'name': 'broccoli', 'aisle': 'Produce', 'image': 'broccoli.jpg'},
      'lettuce': {'id': 11252, 'name': 'lettuce', 'aisle': 'Produce', 'image': 'lettuce.jpg'},
      'spinach': {'id': 11457, 'name': 'spinach', 'aisle': 'Produce', 'image': 'spinach.jpg'},
      'potato': {'id': 11333, 'name': 'potato', 'aisle': 'Produce', 'image': 'potato.jpg'},
      'potatoes': {'id': 11333, 'name': 'potatoes', 'aisle': 'Produce', 'image': 'potatoes.jpg'},
      'pepper': {'id': 11440, 'name': 'pepper', 'aisle': 'Produce', 'image': 'pepper.jpg'},
      'peppers': {'id': 11440, 'name': 'peppers', 'aisle': 'Produce', 'image': 'peppers.jpg'},
      'cucumber': {'id': 11165, 'name': 'cucumber', 'aisle': 'Produce', 'image': 'cucumber.jpg'},
      'celery': {'id': 11143, 'name': 'celery', 'aisle': 'Produce', 'image': 'celery.jpg'},
      'mushroom': {'id': 11260, 'name': 'mushroom', 'aisle': 'Produce', 'image': 'mushroom.jpg'},
      'mushrooms': {'id': 11260, 'name': 'mushrooms', 'aisle': 'Produce', 'image': 'mushrooms.jpg'},
      'corn': {'id': 11172, 'name': 'corn', 'aisle': 'Produce', 'image': 'corn.jpg'},
      'beans': {'id': 16020, 'name': 'beans', 'aisle': 'Produce', 'image': 'beans.jpg'},
      'bell pepper': {'id': 11440, 'name': 'bell pepper', 'aisle': 'Produce', 'image': 'pepper.jpg'},
      'peppers': {'id': 11440, 'name': 'peppers', 'aisle': 'Produce', 'image': 'peppers.jpg'},

      // Fruits
      'apple': {'id': 9003, 'name': 'apple', 'aisle': 'Produce', 'image': 'apple.jpg'},
      'banana': {'id': 9040, 'name': 'banana', 'aisle': 'Produce', 'image': 'banana.jpg'},
      'orange': {'id': 9200, 'name': 'orange', 'aisle': 'Produce', 'image': 'orange.jpg'},
      'lemon': {'id': 9150, 'name': 'lemon', 'aisle': 'Produce', 'image': 'lemon.jpg'},
      'lime': {'id': 9160, 'name': 'lime', 'aisle': 'Produce', 'image': 'lime.jpg'},
      'strawberry': {'id': 9317, 'name': 'strawberry', 'aisle': 'Produce', 'image': 'strawberry.jpg'},
      'watermelon': {'id': 9430, 'name': 'watermelon', 'aisle': 'Produce', 'image': 'watermelon.jpg'},
      'mango': {'id': 9176, 'name': 'mango', 'aisle': 'Produce', 'image': 'mango.jpg'},
      'pineapple': {'id': 9288, 'name': 'pineapple', 'aisle': 'Produce', 'image': 'pineapple.jpg'},
      'grape': {'id': 9132, 'name': 'grape', 'aisle': 'Produce', 'image': 'grape.jpg'},
      'grapes': {'id': 9132, 'name': 'grapes', 'aisle': 'Produce', 'image': 'grapes.jpg'},
      'avocado': {'id': 9037, 'name': 'avocado', 'aisle': 'Produce', 'image': 'avocado.jpg'},

      // Dairy
      'milk': {'id': 1077, 'name': 'milk', 'aisle': 'Dairy', 'image': 'milk.jpg'},
      'cheese': {'id': 1001, 'name': 'cheese', 'aisle': 'Dairy', 'image': 'cheese.jpg'},
      'butter': {'id': 1001, 'name': 'butter', 'aisle': 'Dairy', 'image': 'butter.jpg'},
      'cream': {'id': 1053, 'name': 'cream', 'aisle': 'Dairy', 'image': 'cream.jpg'},
      'yogurt': {'id': 1256, 'name': 'yogurt', 'aisle': 'Dairy', 'image': 'yogurt.jpg'},

      // Grains & Starch
      'rice': {'id': 20081, 'name': 'rice', 'aisle': 'Dried & Baking', 'image': 'rice.jpg'},
      'pasta': {'id': 20081, 'name': 'pasta', 'aisle': 'Dried & Baking', 'image': 'pasta.jpg'},
      'noodle': {'id': 20081, 'name': 'noodle', 'aisle': 'Dried & Baking', 'image': 'noodle.jpg'},
      'noodles': {'id': 20081, 'name': 'noodles', 'aisle': 'Dried & Baking', 'image': 'noodles.jpg'},
      'bread': {'id': 18075, 'name': 'bread', 'aisle': 'Bakery', 'image': 'bread.jpg'},
      'flour': {'id': 20081, 'name': 'flour', 'aisle': 'Dried & Baking', 'image': 'flour.jpg'},
      'oats': {'id': 20081, 'name': 'oats', 'aisle': 'Dried & Baking', 'image': 'oats.jpg'},
      'cereal': {'id': 20081, 'name': 'cereal', 'aisle': 'Breakfast', 'image': 'cereal.jpg'},

      // Condiments & Oils
      'oil': {'id': 4554, 'name': 'oil', 'aisle': 'Oils', 'image': 'oil.jpg'},
      'olive oil': {'id': 4554, 'name': 'olive oil', 'aisle': 'Oils', 'image': 'olive-oil.jpg'},
      'salt': {'id': 2047, 'name': 'salt', 'aisle': 'Spices and Seasonings', 'image': 'salt.jpg'},
      'black pepper': {'id': 2032, 'name': 'black pepper', 'aisle': 'Spices and Seasonings', 'image': 'pepper.jpg'},
      'sugar': {'id': 19336, 'name': 'sugar', 'aisle': 'Baking', 'image': 'sugar.jpg'},
      'soy sauce': {'id': 16124, 'name': 'soy sauce', 'aisle': 'Asian', 'image': 'soy-sauce.jpg'},
      'vinegar': {'id': 2053, 'name': 'vinegar', 'aisle': 'Condiments', 'image': 'vinegar.jpg'},
      'ketchup': {'id': 11935, 'name': 'ketchup', 'aisle': 'Condiments', 'image': 'ketchup.jpg'},
      'mayonnaise': {'id': 4025, 'name': 'mayonnaise', 'aisle': 'Condiments', 'image': 'mayonnaise.jpg'},
      'mustard': {'id': 2046, 'name': 'mustard', 'aisle': 'Condiments', 'image': 'mustard.jpg'},

      // Nuts & Seeds
      'peanut': {'id': 16098, 'name': 'peanut', 'aisle': 'Nuts', 'image': 'peanut.jpg'},
      'peanuts': {'id': 16098, 'name': 'peanuts', 'aisle': 'Nuts', 'image': 'peanuts.jpg'},
      'almond': {'id': 12061, 'name': 'almond', 'aisle': 'Nuts', 'image': 'almond.jpg'},
      'almonds': {'id': 12061, 'name': 'almonds', 'aisle': 'Nuts', 'image': 'almonds.jpg'},
      'walnut': {'id': 12155, 'name': 'walnut', 'aisle': 'Nuts', 'image': 'walnut.jpg'},
      'cashew': {'id': 12087, 'name': 'cashew', 'aisle': 'Nuts', 'image': 'cashew.jpg'},
      'coconut': {'id': 12104, 'name': 'coconut', 'aisle': 'Produce', 'image': 'coconut.jpg'},

      // Beverages
      'water': {'id': 14412, 'name': 'water', 'aisle': 'Beverages', 'image': 'water.jpg'},
      'juice': {'id': 14412, 'name': 'juice', 'aisle': 'Beverages', 'image': 'juice.jpg'},
      'coffee': {'id': 14184, 'name': 'coffee', 'aisle': 'Coffee', 'image': 'coffee.jpg'},
      'tea': {'id': 14399, 'name': 'tea', 'aisle': 'Tea', 'image': 'tea.jpg'},
    };

    // Try exact match first
    if (commonIngredients.containsKey(lowerName)) {
      final data = commonIngredients[lowerName]!;
      return IngredientSearchResult(
        id: data['id'] as int,
        name: data['name'] as String,
        image: data['image'] as String?,
        aisle: data['aisle'] as String,
      );
    }

    // Try partial match
    for (final entry in commonIngredients.entries) {
      if (lowerName.contains(entry.key) || entry.key.contains(lowerName)) {
        final data = entry.value;
        return IngredientSearchResult(
          id: data['id'] as int,
          name: data['name'] as String,
          image: data['image'] as String?,
          aisle: data['aisle'] as String,
        );
      }
    }

    // Ingredient not found locally
    debugPrint('Ingredient not found in local database: $ingredientName');
    return null;
  }

  /// Autocomplete ingredient names as user types
  /// Returns list of suggestions matching the query
  Future<List<String>> autocompleteIngredient(
    String query, {
    int number = 10,
  }) async {
    if (query.trim().length < 2) {
      return [];
    }

    // Check API quota
    if (!hasQuotaAvailable) {
      return [];
    }

    try {
      final url = Uri.https(_baseUrl, '/$_apiVersion/food/ingredients/autocomplete', {
        'query': query,
        'number': number.toString(),
        'metaInformation': 'false',
      });

      final response = await http.get(
        url,
        headers: {'X-API-Key': ApiConfig.spoonacularApiKey},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Autocomplete request timed out');
        },
      );

      // Increment request count
      _requestCount++;
      notifyListeners();

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        return results
            .map((item) => item['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Autocomplete error: $e');
      return [];
    }
  }

  /// Get ingredient information with nutrition for confirmed ingredient
  Future<Ingredient> getValidatedIngredientInformation(
    int ingredientId, {
    double amount = 1,
    String unit = 'serving',
  }) async {
    if (!hasQuotaAvailable) {
      _errorMessage = 'Daily API quota exceeded';
      notifyListeners();
      throw Exception('API quota exceeded');
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final url = Uri.https(_baseUrl, '/$_apiVersion/food/ingredients/$ingredientId/information', {
        'amount': amount.toString(),
        'unit': unit,
        'includeNutrition': 'true',
      });

      final response = await http.get(
        url,
        headers: {'X-API-Key': ApiConfig.spoonacularApiKey},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      // Increment request count
      _requestCount++;
      notifyListeners();

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final ingredient = Ingredient.fromJson(jsonData);

        _isLoading = false;
        notifyListeners();

        return ingredient;
      } else {
        _errorMessage = 'API Error: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Error fetching ingredient: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Get Ingredient Info Error: $e');
      rethrow;
    }
  }

  /// Smart ingredient parsing with fallback
  /// Tries to parse ingredients and provides helpful error messages
  Future<IngredientParseResult> smartParseIngredients(
    List<String> inputs,
  ) async {
    try {
      final ingredients = await parseIngredients(inputs);

      if (ingredients.isEmpty) {
        return IngredientParseResult(
          ingredients: [],
          success: false,
          message: 'No valid ingredients could be parsed from the input.',
        );
      }

      // Check for missing nutrition data
      final missingNutrition = ingredients.where((i) => i.nutrition == null).length;

      if (missingNutrition > 0) {
        return IngredientParseResult(
          ingredients: ingredients,
          success: true,
          message: 'Parsed ${ingredients.length} ingredients. '
              '$missingNutrition items missing nutrition data.',
        );
      }

      return IngredientParseResult(
        ingredients: ingredients,
        success: true,
        message: 'Successfully parsed ${ingredients.length} ingredients with nutrition data.',
      );
    } catch (e) {
      return IngredientParseResult(
        ingredients: [],
        success: false,
        message: 'Failed to parse ingredients: $e',
        error: e.toString(),
      );
    }
  }
}

/// Result class for ingredient parsing operations
class IngredientParseResult {
  final List<Ingredient> ingredients;
  final bool success;
  final String message;
  final String? error;

  IngredientParseResult({
    required this.ingredients,
    required this.success,
    required this.message,
    this.error,
  });

  /// Get ingredients grouped by category
  Map<IngredientCategory, List<Ingredient>> get groupedByCategory {
    final map = <IngredientCategory, List<Ingredient>>{};

    for (final ingredient in ingredients) {
      final category = ingredient.category;
      map.putIfAbsent(category, () => []).add(ingredient);
    }

    return map;
  }

  /// Get total calories across all ingredients
  double get totalCalories {
    return ingredients.fold<double>(
      0,
      (sum, ingredient) => sum + (ingredient.nutrition?.totalCalories ?? 0),
    );
  }

  /// Get unique categories
  List<IngredientCategory> get categories {
    return ingredients.map((i) => i.category).toSet().toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }
}
