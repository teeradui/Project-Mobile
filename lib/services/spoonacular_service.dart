import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Spoonacular API Service
/// Handles recipe search and nutrition data from Spoonacular API
class SpoonacularService extends ChangeNotifier {
  // API Configuration
  static const String _baseUrl = 'api.spoonacular.com';
  static const String _apiKey = '6640bb7876804f569a369e48949e0fc1';

  // API Endpoints
  static const String _findByIngredientsPath = '/recipes/findByIngredients';
  static const String _getRecipeInfoPath = '/recipes/{id}/information';
  static const String _getRecipeNutritionPath = '/recipes/{id}/nutritionWidget.json';

  // State
  bool _isLoading = false;
  String _errorMessage = '';
  int _remainingPoints = 150; // Daily limit for free tier

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get remainingPoints => _remainingPoints;
  bool get hasPointsLeft => _remainingPoints > 0;

  /// Find recipes by ingredients
  /// Uses ranking=1 to minimize missing ingredients
  Future<List<SpoonacularRecipe>> findByIngredients(
    List<String> ingredients, {
    int number = 10,
    bool ranking = true,
  }) async {
    if (!hasPointsLeft) {
      _errorMessage = 'Daily API quota exceeded. Please try again tomorrow.';
      notifyListeners();
      return [];
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final ingredientsString = ingredients.join(',');
      final uri = Uri.https(_baseUrl, _findByIngredientsPath, {
        'ingredients': ingredientsString,
        'number': number.toString(),
        'ranking': ranking ? '1' : '0',
        'apiKey': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final recipes = data.map((json) => SpoonacularRecipe.fromJson(json)).toList();

        _remainingPoints -= recipes.length; // Estimate point usage
        _isLoading = false;
        notifyListeners();

        return recipes;
      } else if (response.statusCode == 402) {
        _errorMessage = 'Daily API quota exceeded. Please try again tomorrow.';
        _remainingPoints = 0;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Invalid API key. Please check your configuration.';
      } else {
        _errorMessage = 'API Error: ${response.statusCode} - ${response.reasonPhrase}';
      }

      _isLoading = false;
      notifyListeners();
      return [];
    } catch (e) {
      _errorMessage = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Get detailed recipe information with nutrition
  Future<SpoonacularRecipeDetail?> getRecipeInfo(int recipeId) async {
    if (!hasPointsLeft) {
      _errorMessage = 'Daily API quota exceeded. Please try again tomorrow.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.https(_baseUrl, _getRecipeInfoPath.replaceAll('{id}', recipeId.toString()), {
        'includeNutrition': 'true',
        'apiKey': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _remainingPoints--;
        _isLoading = false;
        notifyListeners();
        return SpoonacularRecipeDetail.fromJson(data);
      } else if (response.statusCode == 402) {
        _errorMessage = 'Daily API quota exceeded. Please try again tomorrow.';
        _remainingPoints = 0;
      } else {
        _errorMessage = 'API Error: ${response.statusCode}';
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get nutrition widget data for a recipe
  Future<Map<String, dynamic>?> getRecipeNutrition(int recipeId) async {
    if (!hasPointsLeft) {
      return null;
    }

    try {
      final uri = Uri.https(_baseUrl, _getRecipeNutritionPath.replaceAll('{id}', recipeId.toString()), {
        'apiKey': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        _remainingPoints--;
        notifyListeners();
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching nutrition: $e');
    }

    return null;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}

/// Spoonacular Recipe from findByIngredients
class SpoonacularRecipe {
  final int id;
  final String title;
  final String image;
  final String imageType;
  final int usedIngredientCount;
  final int missedIngredientCount;
  final int missedIngredientsCount; // Alias for missedIngredientCount
  final List<SpoonacularIngredient> usedIngredients;
  final List<SpoonacularIngredient> missedIngredients;
  final List<SpoonacularIngredient> unusedIngredients;

  SpoonacularRecipe({
    required this.id,
    required this.title,
    required this.image,
    required this.imageType,
    required this.usedIngredientCount,
    required this.missedIngredientCount,
    required this.missedIngredientsCount,
    required this.usedIngredients,
    required this.missedIngredients,
    required this.unusedIngredients,
  });

  factory SpoonacularRecipe.fromJson(Map<String, dynamic> json) {
    return SpoonacularRecipe(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown Recipe',
      image: json['image'] ?? '',
      imageType: json['imageType'] ?? 'jpg',
      usedIngredientCount: json['usedIngredientCount'] ?? 0,
      missedIngredientCount: json['missedIngredientCount'] ?? 0,
      missedIngredientsCount: json['missedIngredientsCount'] ?? json['missedIngredientCount'] ?? 0,
      usedIngredients: (json['usedIngredients'] as List<dynamic>?)
              ?.map((e) => SpoonacularIngredient.fromJson(e))
              .toList() ??
          [],
      missedIngredients: (json['missedIngredients'] as List<dynamic>?)
              ?.map((e) => SpoonacularIngredient.fromJson(e))
              .toList() ??
          [],
      unusedIngredients: (json['unusedIngredients'] as List<dynamic>?)
              ?.map((e) => SpoonacularIngredient.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Calculate match percentage based on used vs total ingredients
  double get matchPercentage {
    final total = usedIngredientCount + missedIngredientCount;
    if (total == 0) return 0.0;
    return (usedIngredientCount / total) * 100;
  }

  /// Get list of missing ingredient names
  List<String> get missingIngredientNames {
    return missedIngredients.map((e) => e.name).toList();
  }

  /// Get list of available ingredient names
  List<String> get availableIngredientNames {
    return usedIngredients.map((e) => e.name).toList();
  }
}

/// Spoonacular Ingredient
class SpoonacularIngredient {
  final int? id;
  final String name;
  final double? amount;
  final String? unit;
  final String? image;

  SpoonacularIngredient({
    this.id,
    required this.name,
    this.amount,
    this.unit,
    this.image,
  });

  factory SpoonacularIngredient.fromJson(Map<String, dynamic> json) {
    return SpoonacularIngredient(
      id: json['id'],
      name: json['name'] ?? json['original'] ?? 'Unknown',
      amount: json['amount']?.toDouble(),
      unit: json['unit'],
      image: json['image'],
    );
  }

  String get formattedAmount {
    if (amount == null) return name;
    if (unit == null || unit!.isEmpty) return '$amount $name';
    return '$amount $unit $name';
  }
}

/// Detailed Spoonacular Recipe with Nutrition
class SpoonacularRecipeDetail {
  final int id;
  final String title;
  final String image;
  final String instructions;
  final int readyInMinutes;
  final String difficulty;
  final SpoonacularNutrition? nutrition;
  final List<SpoonacularIngredient> extendedIngredients;

  SpoonacularRecipeDetail({
    required this.id,
    required this.title,
    required this.image,
    required this.instructions,
    required this.readyInMinutes,
    required this.difficulty,
    this.nutrition,
    required this.extendedIngredients,
  });

  factory SpoonacularRecipeDetail.fromJson(Map<String, dynamic> json) {
    return SpoonacularRecipeDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown Recipe',
      image: json['image'] ?? '',
      instructions: json['instructions'] ?? 'No instructions available.',
      readyInMinutes: json['readyInMinutes'] ?? 30,
      difficulty: _calculateDifficulty(json['readyInMinutes'] ?? 30, json['analyzedInstructions']?.length ?? 0),
      nutrition: json['nutrition'] != null
          ? SpoonacularNutrition.fromJson(json['nutrition'])
          : null,
      extendedIngredients: (json['extendedIngredients'] as List<dynamic>?)
              ?.map((e) => SpoonacularIngredient.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Calculate difficulty based on time and steps
  static String _calculateDifficulty(int minutes, int steps) {
    if (minutes < 20 && steps <= 3) return 'Easy';
    if (minutes < 45 && steps <= 6) return 'Medium';
    return 'Hard';
  }

  /// Get total calories from nutrition
  int get totalCalories => nutrition?.calories ?? 0;

  /// Get calorie breakdown by category (Protein, Carbs, Vegetables, Dairy, Others)
  Map<String, int> getCalorieBreakdown() {
    if (nutrition?.ingredientBreakdown == null) return {};

    final categoryBreakdown = <String, int>{
      'Protein': 0,
      'Carbs': 0,
      'Vegetables': 0,
      'Dairy': 0,
      'Others': 0,
    };

    // Convert ingredient breakdown to category breakdown
    nutrition!.ingredientBreakdown.forEach((ingredient, calories) {
      final category = _getIngredientCategory(ingredient);
      categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + calories;
    });

    // Remove categories with zero calories
    categoryBreakdown.removeWhere((key, value) => value == 0);

    return categoryBreakdown;
  }

  /// Map ingredient name to category
  String _getIngredientCategory(String ingredientName) {
    final lower = ingredientName.toLowerCase();

    // Protein sources
    if (lower.contains('chicken') || lower.contains('pork') || lower.contains('beef') ||
        lower.contains('fish') || lower.contains('shrimp') || lower.contains('crab') ||
        lower.contains('salmon') || lower.contains('tuna') || lower.contains('cod') ||
        lower.contains('bacon') || lower.contains('ham') || lower.contains('sausage') ||
        lower.contains('meatball') || lower.contains('turkey') || lower.contains('lamb') ||
        lower.contains('egg') || lower.contains('steak') || lower.contains('veal')) {
      return 'Protein';
    }

    // Carbs sources
    if (lower.contains('rice') || lower.contains('pasta') || lower.contains('noodle') ||
        lower.contains('bread') || lower.contains('flour') || lower.contains('oat') ||
        lower.contains('cereal') || lower.contains('quinoa') || lower.contains('barley') ||
        lower.contains('couscous') || lower.contains('lentil') || lower.contains('chickpea') ||
        lower.contains('cracker') || lower.contains('bagel') || lower.contains('muffin') ||
        lower.contains('pancake') || lower.contains('waffle') || lower.contains('tortilla') ||
        lower.contains('croissant') || lower.contains('potato') || lower.contains('corn')) {
      return 'Carbs';
    }

    // Vegetables
    if (lower.contains('tomato') || lower.contains('onion') || lower.contains('garlic') ||
        lower.contains('carrot') || lower.contains('broccoli') || lower.contains('cabbage') ||
        lower.contains('lettuce') || lower.contains('spinach') || lower.contains('mushroom') ||
        lower.contains('pepper') || lower.contains('cucumber') || lower.contains('celery') ||
        lower.contains('beans') || lower.contains('peas') || lower.contains('asparagus') ||
        lower.contains('zucchini') || lower.contains('eggplant') || lower.contains('cauliflower') ||
        lower.contains('kale') || lower.contains('artichoke') || lower.contains('brussels') ||
        lower.contains('herb') || lower.contains('basil') || lower.contains('parsley') ||
        lower.contains('cilantro') || lower.contains('dill') || lower.contains('mint')) {
      return 'Vegetables';
    }

    // Dairy
    if (lower.contains('milk') || lower.contains('cheese') || lower.contains('butter') ||
        lower.contains('cream') || lower.contains('yogurt') || lower.contains('parmesan') ||
        lower.contains('mozzarella') || lower.contains('cheddar') || lower.contains('swiss') ||
        lower.contains('gouda') || lower.contains('ricotta') || lower.contains('feta') ||
        lower.contains('goat cheese')) {
      return 'Dairy';
    }

    // Everything else
    return 'Others';
  }
}

/// Spoonacular Nutrition Information
class SpoonacularNutrition {
  final int calories;
  final List<String> nutrients;
  final List<SpoonacularIngredientNutrition> ingredients;
  final Map<String, int> ingredientBreakdown;

  SpoonacularNutrition({
    required this.calories,
    required this.nutrients,
    required this.ingredients,
    required this.ingredientBreakdown,
  });

  factory SpoonacularNutrition.fromJson(Map<String, dynamic> json) {
    // Extract calories from nutrients
    final nutrients = json['nutrients'] as List<dynamic>? ?? [];
    final caloriesInfo = nutrients.firstWhere(
      (n) => n['name'] == 'Calories',
      orElse: () => {'amount': 0},
    );
    final calories = (caloriesInfo['amount'] as num?)?.toInt() ?? 0;

    // Extract ingredient breakdown
    final ingredientList = (json['ingredients'] as List<dynamic>?)
            ?.map((e) => SpoonacularIngredientNutrition.fromJson(e))
            .toList() ??
        [];

    // Build simple breakdown by ingredient
    final breakdown = <String, int>{};
    for (var ing in ingredientList) {
      final ingCalories = (ing.calories ?? 0).toInt();
      if (ingCalories > 0) {
        breakdown[ing.name] = ingCalories;
      }
    }

    return SpoonacularNutrition(
      calories: calories,
      nutrients: nutrients.map((n) => n['name']?.toString() ?? '').toList(),
      ingredients: ingredientList,
      ingredientBreakdown: breakdown,
    );
  }
}

/// Nutrition info for a single ingredient
class SpoonacularIngredientNutrition {
  final String name;
  final double? calories;
  final String? image;

  SpoonacularIngredientNutrition({
    required this.name,
    this.calories,
    this.image,
  });

  factory SpoonacularIngredientNutrition.fromJson(Map<String, dynamic> json) {
    // Extract calories from nutrients array
    final nutrients = json['nutrients'] as List<dynamic>? ?? [];
    final caloriesInfo = nutrients.firstWhere(
      (n) => n['name'] == 'Calories',
      orElse: () => {'amount': 0},
    );

    return SpoonacularIngredientNutrition(
      name: json['name'] ?? 'Unknown',
      calories: caloriesInfo['amount']?.toDouble(),
      image: json['image'],
    );
  }
}
