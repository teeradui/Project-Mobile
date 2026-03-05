import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grocery_item.dart';
import '../models/recipe.dart';
import '../services/ai_service.dart';
import '../services/voice_service.dart';
import '../services/spoonacular_service.dart';
import '../config/api_config.dart';

/// Ingredient & Recipe Provider
/// Manages ingredients and recipe suggestions
class GroceryProvider extends ChangeNotifier {
  // State
  final List<GroceryItem> _items = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isLoadingRecipes = false;

  // Services
  final AIService _aiService = AIService();
  final VoiceService _voiceService = VoiceService();
  final SpoonacularService _spoonacularService = SpoonacularService();

  // Recipe state - can be local Recipe or SpoonacularRecipe
  final List<dynamic> _fetchedRecipes = [];

  // Getters
  List<GroceryItem> get items => List.unmodifiable(_items);
  List<GroceryItem> get unpurchasedItems =>
      _items.where((item) => !item.isPurchased).toList();
  List<GroceryItem> get purchasedItems =>
      _items.where((item) => item.isPurchased).toList();
  int get totalItems => _items.length;
  int get purchasedCount => _items.where((item) => item.isPurchased).length;
  bool get isLoading => _isLoading;
  bool get isLoadingRecipes => _isLoadingRecipes;
  String get errorMessage => _errorMessage;
  bool get hasItems => _items.isNotEmpty;

  // Voice Service getter for UI access
  VoiceService get voiceService => _voiceService;

  // Spoonacular Service getter
  SpoonacularService get spoonacularService => _spoonacularService;

  // Recipe suggestions (hybrid: API first, fallback to local)
  List<dynamic> get matchingRecipes => _fetchedRecipes.isNotEmpty
      ? _fetchedRecipes
      : RecipeDatabase.getMatchingRecipes(
          unpurchasedItems.map((e) => e.name).toList(),
        );

  int get recipeCount => matchingRecipes.length;
  String? get apiError => _spoonacularService.errorMessage.isNotEmpty
      ? _spoonacularService.errorMessage
      : null;

  // Category breakdown
  Map<GroceryCategory, List<GroceryItem>> get itemsByCategory {
    final map = <GroceryCategory, List<GroceryItem>>{};
    for (final category in GroceryCategory.values) {
      map[category] = _items
          .where(
            (item) => GroceryCategory.getCategoryForItem(item.name) == category,
          )
          .toList();
    }
    return map;
  }

  /// Initialize provider
  Future<void> initialize() async {
    // Set API key from config
    if (ApiConfig.isConfigured) {
      _aiService.setApiKey(ApiConfig.geminiApiKey);
    }

    await _loadFromPreferences();
    await _voiceService.initialize();
    await _voiceService.checkMicrophonePermission();
  }

  /// Set API Key for AI Service
  void setApiKey(String key) {
    _aiService.setApiKey(key);
  }

  /// Unified input processor - handles both voice and text input
  /// Enhanced to extract only valid food ingredients
  Future<void> processInput(String input, {bool isVoice = false}) async {
    if (input.trim().isEmpty) {
      _errorMessage = 'กรุณาพิมพ์หรือพูดวัตถุดิบ';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Process through AI Service
      final normalizedInput = _normalizeSentence(input);
      final newItems = await _aiService.processInput(normalizedInput);  

      if (newItems.isEmpty) {
        _errorMessage = 'ไม่พบวัตถุดิบที่ถูกต้อง กรุณาลองใหม่';
      } else {
        // Add all extracted items
        for (final item in newItems) {
          _addItem(item);
        }
        _errorMessage = '';
      }

      _isLoading = false;
      notifyListeners();
      await _saveToPreferences();
    } catch (e) {
      _errorMessage = 'เกิดข้อผิดพลาด: $e';
      _isLoading = false;
      notifyListeners();
    }
  }


String _normalizeName(String word) {
  word = word.toLowerCase().trim();

  if (word.endsWith('ies')) {
    return word.substring(0, word.length - 3) + 'y';
  } else if (word.endsWith('es')) {
    return word.substring(0, word.length - 2);
  } else if (word.endsWith('s') && !word.endsWith('ss')) {
    return word.substring(0, word.length - 1);
  }

  return word;
}

  String _normalizeSentence(String sentence) {
  final words = sentence.toLowerCase().trim().split(' ');

  final normalizedWords = words.map((word) {
    if (word.endsWith('ies')) {
      return word.substring(0, word.length - 3) + 'y';
    } else if (word.endsWith('es')) {
      return word.substring(0, word.length - 2);
    } else if (word.endsWith('s') && !word.endsWith('ss')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  });

  return normalizedWords.join(' ');
}
  /// Add a single ingredient
void _addItem(GroceryItem item) {
  final normalizedName = _normalizeName(item.name);

  final existingIndex = _items.indexWhere(
    (existing) =>
        _normalizeName(existing.name) == normalizedName &&
        existing.unit == item.unit &&
        !existing.isPurchased,
  );

  if (existingIndex != -1) {
    final existing = _items[existingIndex];
    _items[existingIndex] = existing.copyWith(
      amount: existing.amount + item.amount,
    );
  } else {
    _items.add(
      item.copyWith(name: normalizedName),
    );
  }

  notifyListeners();
}

  /// Add ingredient manually
  void addItemManually(GroceryItem item) {
    _addItem(item);
    _saveToPreferences();
  }

  void deleteItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Update ingredient
  void updateItem(GroceryItem updatedItem) {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
      _saveToPreferences();
    }
  }

  /// Toggle purchased status
  void togglePurchased(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        isPurchased: !_items[index].isPurchased,
      );
      notifyListeners();
      _saveToPreferences();
    }
  }

  /// Delete ingredient
  void clearAllItems() {
    _items.clear();
    notifyListeners();
    _saveToPreferences();
  }

  /// Delete all ingredients
  void deleteAll() {
    _items.clear();
    notifyListeners();
    _saveToPreferences();
  }

  /// Delete all purchased ingredients
  void deletePurchased() {
    _items.removeWhere((item) => item.isPurchased);
    notifyListeners();
    _saveToPreferences();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  /// Sort ingredients
  void sortItems(GrocerySortType sortType) {
    switch (sortType) {
      case GrocerySortType.nameAsc:
        _items.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case GrocerySortType.nameDesc:
        _items.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case GrocerySortType.category:
        _items.sort((a, b) {
          final catA = GroceryCategory.getCategoryForItem(a.name);
          final catB = GroceryCategory.getCategoryForItem(b.name);
          return catA.index.compareTo(catB.index);
        });
        break;
      case GrocerySortType.dateAdded:
        _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case GrocerySortType.priceAsc:
      case GrocerySortType.priceDesc:
        // Not needed for recipe-focused app
        break;
    }
    notifyListeners();
  }

  /// Filter ingredients by category
  List<GroceryItem> filterByCategory(GroceryCategory? category) {
    if (category == null) return _items;
    return _items
        .where(
          (item) => GroceryCategory.getCategoryForItem(item.name) == category,
        )
        .toList();
  }

  /// Get ingredient by ID
  GroceryItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Save to local storage
  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'ingredients',
        jsonEncode(_items.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving to preferences: $e');
    }
  }

  /// Load from local storage
  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getString('ingredients');

      if (itemsJson != null) {
        final List<dynamic> decoded = jsonDecode(itemsJson);
        _items.clear();
        _items.addAll(
          decoded.map(
            (json) => GroceryItem(
              id:
                  json['id'] ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              name: json['name'] ?? '',
              amount: (json['amount'] as num).toDouble(),
              unit: json['unit'] ?? 'pcs',
              price: (json['price'] as num?)?.toDouble() ?? 0.0,
              createdAt: json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'])
                  : DateTime.now(),
              isPurchased: json['isPurchased'] ?? false,
            ),
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from preferences: $e');
    }
  }

  /// Export data as JSON string
  String exportToJson() {
    return jsonEncode({
      'items': _items.map((e) => e.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    });
  }

  /// Import data from JSON string
  Future<bool> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);

      if (data['items'] != null) {
        _items.clear();
        for (var itemJson in data['items']) {
          _items.add(
            GroceryItem(
              id:
                  itemJson['id'] ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              name: itemJson['name'] ?? '',
              amount: (itemJson['amount'] as num).toDouble(),
              unit: itemJson['unit'] ?? 'pcs',
              price: (itemJson['price'] as num?)?.toDouble() ?? 0.0,
              createdAt: itemJson['createdAt'] != null
                  ? DateTime.parse(itemJson['createdAt'])
                  : DateTime.now(),
              isPurchased: itemJson['isPurchased'] ?? false,
            ),
          );
        }
      }

      await _saveToPreferences();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Import failed: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _aiService.dispose();
    super.dispose();
  }

  /// Fetch recipes from Spoonacular API (Hybrid approach)
  /// Falls back to local database if API fails or quota exceeded
  Future<void> fetchRecipesFromAPI() async {
    if (unpurchasedItems.isEmpty) {
      _errorMessage = 'กรุณาเพิ่มวัตถุดิบก่อน / Please add ingredients first';
      notifyListeners();
      return;
    }

    _isLoadingRecipes = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final ingredientNames = unpurchasedItems.map((e) => e.name).toList();

      debugPrint('📝 Fetching recipes for ingredients: $ingredientNames');

      // Try to fetch from API
      final apiRecipes = await _spoonacularService.findByIngredients(
        ingredientNames,
        number: 10,
        ranking: true,
      );

      debugPrint('📊 API returned ${apiRecipes.length} recipes');
      debugPrint('📊 API Error message: "${_spoonacularService.errorMessage}"');

      // Check if API call was successful (no error message)
      final apiCallSuccessful = _spoonacularService.errorMessage.isEmpty;

      if (apiCallSuccessful) {
        // API successful - use API recipes (even if empty)
        _fetchedRecipes.clear();
        _fetchedRecipes.addAll(apiRecipes);
        _errorMessage = ''; // Clear error - API worked

        debugPrint(
          '✅ API call successful - stored ${apiRecipes.length} recipes',
        );
        if (apiRecipes.isNotEmpty) {
          debugPrint('✅ First recipe: ${apiRecipes[0].title}');
        }
      } else {
        // API failed or quota exceeded - fallback to local database
        _fetchedRecipes.clear();
        _errorMessage =
            'ใช้สูตรอาหารแบบออฟไลน์ ${_spoonacularService.errorMessage}';
        debugPrint('❌ API call failed: $_errorMessage');
      }

      _isLoadingRecipes = false;
      notifyListeners();
    } catch (e) {
      // Fallback to local database on any error
      debugPrint('💥 Exception in fetchRecipesFromAPI: $e');
      _fetchedRecipes.clear();
      _errorMessage = 'ใช้สูตรอาหารแบบออฟไลน์ ข้อผิดพลาด: $e';
      _isLoadingRecipes = false;
      notifyListeners();
    }
  }

  /// Clear API error and fallback message
  void clearApiError() {
    _spoonacularService.clearError();
    if (_errorMessage.contains('ใช้สูตรอาหารแบบออฟไลน์') ||
        _errorMessage.contains('Using offline recipes')) {
      _errorMessage = '';
    }
    notifyListeners();
  }

  /// Get recipe detail (handles both Recipe and SpoonacularRecipe types)
  Future<Map<String, dynamic>?> getRecipeDetail(dynamic recipe) async {
    if (recipe is SpoonacularRecipe) {
      // Fetch detailed info from API
      final detail = await _spoonacularService.getRecipeInfo(recipe.id);
      if (detail != null) {
        return {
          'title': detail.title,
          'image': detail.image,
          'instructions': detail.instructions,
          'cookingTime': detail.readyInMinutes,
          'difficulty': detail.difficulty,
          'calories': detail.totalCalories,
          'calorieBreakdown': detail.getCalorieBreakdown(),
          'ingredients': detail.extendedIngredients.map((e) => e.name).toList(),
          'usedIngredients': recipe.usedIngredients.map((e) => e.name).toList(),
          'missedIngredients': recipe.missedIngredients
              .map((e) => e.name)
              .toList(),
          'isFromAPI': true,
        };
      } else {
        // Fallback: Use estimated calories if API fails
        final estimatedCalories = _estimateCaloriesFromIngredients(
          recipe.usedIngredients,
          recipe.missedIngredients,
        );
        return {
          'title': recipe.title,
          'image': recipe.image,
          'instructions': 'Recipe instructions available on Spoonacular.',
          'cookingTime': 30,
          'difficulty': 'Medium',
          'calories': estimatedCalories,
          'calorieBreakdown': _estimateCategoryBreakdown(
            recipe.usedIngredients,
            recipe.missedIngredients,
          ),
          'ingredients':
              recipe.usedIngredients.map((e) => e.name).toList() +
              recipe.missedIngredients.map((e) => e.name).toList(),
          'usedIngredients': recipe.usedIngredients.map((e) => e.name).toList(),
          'missedIngredients': recipe.missedIngredients
              .map((e) => e.name)
              .toList(),
          'isFromAPI': true,
        };
      }
    }

    // Return local recipe data
    if (recipe is Recipe) {
      return {
        'title': recipe.name,
        'titleThai': recipe.nameThai,
        'image': recipe.imageUrl,
        'instructions': recipe.instructions,
        'instructionsThai': recipe.instructionsThai,
        'cookingTime': recipe.cookingTime,
        'difficulty': recipe.difficulty,
        'calories': recipe.getTotalCalories(),
        'calorieBreakdown': recipe.getCalorieBreakdown(),
        'ingredients': recipe.ingredients,
        'isFromAPI': false,
      };
    }

    return null;
  }

  /// Estimate total calories from ingredients
  int _estimateCaloriesFromIngredients(
    List<SpoonacularIngredient> usedIngredients,
    List<SpoonacularIngredient> missedIngredients,
  ) {
    int total = 0;

    // Estimate for used ingredients (assume standard serving)
    for (var ing in usedIngredients) {
      total += _getIngredientCalories(
        ing.name,
        ing.amount ?? 100,
        ing.unit ?? 'g',
      );
    }

    // Add estimate for missed ingredients
    for (var ing in missedIngredients) {
      total += _getIngredientCalories(
        ing.name,
        ing.amount ?? 100,
        ing.unit ?? 'g',
      );
    }

    return total;
  }

  /// Estimate category breakdown
  Map<String, int> _estimateCategoryBreakdown(
    List<SpoonacularIngredient> usedIngredients,
    List<SpoonacularIngredient> missedIngredients,
  ) {
    final breakdown = <String, int>{
      'Protein': 0,
      'Carbs': 0,
      'Vegetables': 0,
      'Dairy': 0,
      'Others': 0,
    };

    // Process all ingredients
    final allIngredients = [...usedIngredients, ...missedIngredients];
    for (var ing in allIngredients) {
      final calories = _getIngredientCalories(
        ing.name,
        ing.amount ?? 100,
        ing.unit ?? 'g',
      );
      final category = _getIngredientCategory(ing.name);
      breakdown[category] = (breakdown[category] ?? 0) + calories;
    }

    // Remove categories with zero calories
    breakdown.removeWhere((key, value) => value == 0);

    return breakdown;
  }

  /// Get estimated calories for an ingredient
  int _getIngredientCalories(String name, double amount, String unit) {
    // Simple calorie database (per 100g)
    final calorieMap = {
      // Protein
      'chicken': 165, 'beef': 250, 'pork': 242, 'fish': 140, 'shrimp': 99,
      'salmon': 208,
      'tuna': 130,
      'crab': 97,
      'prawn': 99,
      'bacon': 541,
      'ham': 145,
      'egg': 155, 'tofu': 76,

      // Dairy
      'milk': 42, 'cheese': 402, 'butter': 717, 'cream': 340, 'yogurt': 59,
      'coconut milk': 197,

      // Vegetables
      'tomato': 18, 'onion': 40, 'garlic': 149, 'carrot': 41, 'potato': 77,
      'broccoli': 34, 'lettuce': 15, 'spinach': 23, 'mushroom': 22,
      'cabbage': 25, 'beans': 347, 'pepper': 31,

      // Carbs
      'rice': 130, 'pasta': 131, 'bread': 265, 'flour': 364,
      'noodle': 138, 'oats': 389,

      // Fruits
      'apple': 52, 'banana': 89, 'orange': 47, 'lime': 30, 'lemon': 29,

      // Condiments
      'oil': 884, 'sugar': 387, 'soy sauce': 60, 'fish sauce': 50,
      'tamarind': 239, 'peanut': 567,
    };

    final lower = name.toLowerCase();
    int kcalPer100g = 100; // Default

    for (var entry in calorieMap.entries) {
      if (lower.contains(entry.key)) {
        kcalPer100g = entry.value;
        break;
      }
    }

    // Convert to grams
    double grams = amount;
    if (unit.contains('kg') || unit.contains('kilogram')) {
      grams = amount * 1000;
    } else if (unit.contains('g') || unit.contains('gram')) {
      grams = amount;
    } else if (unit.contains('lb') || unit.contains('pound')) {
      grams = amount * 453.592;
    } else if (unit.contains('oz') || unit.contains('ounce')) {
      grams = amount * 28.3495;
    } else if (unit.contains('cup')) {
      grams = amount * 200; // Approximate
    } else if (unit.contains('tbsp') || unit.contains('tablespoon')) {
      grams = amount * 15;
    } else if (unit.contains('tsp') || unit.contains('teaspoon')) {
      grams = amount * 5;
    } else if (unit.contains('ml') || unit.contains('milliliter')) {
      grams = amount; // Approximate for liquids
    } else if (unit.contains('liter') || unit.contains('l')) {
      grams = amount * 1000;
    } else {
      // Assume pieces = 100g each
      grams = amount * 100;
    }

    return ((kcalPer100g * grams) / 100).round();
  }

  /// Get category for an ingredient
  String _getIngredientCategory(String ingredientName) {
    final lower = ingredientName.toLowerCase();

    // Protein
    if (lower.contains('chicken') ||
        lower.contains('beef') ||
        lower.contains('pork') ||
        lower.contains('fish') ||
        lower.contains('shrimp') ||
        lower.contains('prawn') ||
        lower.contains('crab') ||
        lower.contains('salmon') ||
        lower.contains('tuna') ||
        lower.contains('bacon') ||
        lower.contains('ham') ||
        lower.contains('sausage') ||
        lower.contains('egg') ||
        lower.contains('tofu')) {
      return 'Protein';
    }

    // Carbs
    if (lower.contains('rice') ||
        lower.contains('pasta') ||
        lower.contains('noodle') ||
        lower.contains('bread') ||
        lower.contains('flour') ||
        lower.contains('potato') ||
        lower.contains('corn') ||
        lower.contains('cracker') ||
        lower.contains('tortilla') ||
        lower.contains('oats')) {
      return 'Carbs';
    }

    // Vegetables
    if (lower.contains('tomato') ||
        lower.contains('onion') ||
        lower.contains('garlic') ||
        lower.contains('carrot') ||
        lower.contains('broccoli') ||
        lower.contains('cabbage') ||
        lower.contains('lettuce') ||
        lower.contains('spinach') ||
        lower.contains('mushroom') ||
        lower.contains('pepper') ||
        lower.contains('cucumber') ||
        lower.contains('beans') ||
        lower.contains('peas') ||
        lower.contains('herb') ||
        lower.contains('basil') ||
        lower.contains('lemongrass') ||
        lower.contains('galangal') ||
        lower.contains('chili')) {
      return 'Vegetables';
    }

    // Dairy
    if (lower.contains('milk') ||
        lower.contains('cheese') ||
        lower.contains('butter') ||
        lower.contains('cream') ||
        lower.contains('yogurt') ||
        lower.contains('coconut')) {
      return 'Dairy';
    }

    return 'Others';
  }
}

/// Sort types for ingredients
enum GrocerySortType {
  nameAsc('Name (A-Z)'),
  nameDesc('Name (Z-A)'),
  category('Category'),
  dateAdded('Date Added'),
  priceAsc('Price (Low to High)'),
  priceDesc('Price (High to Low)');

  final String label;
  const GrocerySortType(this.label);
}
