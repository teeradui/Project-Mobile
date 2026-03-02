import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grocery_item.dart';
import '../models/recipe.dart';
import '../services/ai_service.dart';
import '../services/voice_service.dart';
import '../config/api_config.dart';

/// Ingredient & Recipe Provider
/// Manages ingredients and recipe suggestions
class GroceryProvider extends ChangeNotifier {
  // State
  final List<GroceryItem> _items = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Services
  final AIService _aiService = AIService();
  final VoiceService _voiceService = VoiceService();

  // Getters
  List<GroceryItem> get items => List.unmodifiable(_items);
  List<GroceryItem> get unpurchasedItems => _items.where((item) => !item.isPurchased).toList();
  List<GroceryItem> get purchasedItems => _items.where((item) => item.isPurchased).toList();
  int get totalItems => _items.length;
  int get purchasedCount => _items.where((item) => item.isPurchased).length;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasItems => _items.isNotEmpty;

  // Voice Service getter for UI access
  VoiceService get voiceService => _voiceService;

  // Recipe suggestions
  List<Recipe> get matchingRecipes {
    final ingredientNames = unpurchasedItems.map((e) => e.name).toList();
    return RecipeDatabase.getMatchingRecipes(ingredientNames);
  }

  int get recipeCount => matchingRecipes.length;

  // Category breakdown
  Map<GroceryCategory, List<GroceryItem>> get itemsByCategory {
    final map = <GroceryCategory, List<GroceryItem>>{};
    for (final category in GroceryCategory.values) {
      map[category] = _items.where((item) => GroceryCategory.getCategoryForItem(item.name) == category).toList();
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
      final newItems = await _aiService.processInput(input);

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

  /// Add a single ingredient
  void _addItem(GroceryItem item) {
    // Check for duplicates
    final existingIndex = _items.indexWhere(
      (existing) =>
          existing.name.toLowerCase() == item.name.toLowerCase() &&
          existing.unit == item.unit &&
          !existing.isPurchased,
    );

    if (existingIndex != -1) {
      // Merge with existing item
      final existing = _items[existingIndex];
      _items[existingIndex] = existing.copyWith(
        amount: existing.amount + item.amount,
      );
    } else {
      // Add new item
      _items.add(item);
    }

    notifyListeners();
  }

  /// Add ingredient manually
  void addItemManually(GroceryItem item) {
    _addItem(item);
    _saveToPreferences();
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
  void deleteItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
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
        _items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case GrocerySortType.nameDesc:
        _items.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
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
    return _items.where((item) => GroceryCategory.getCategoryForItem(item.name) == category).toList();
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
      await prefs.setString('ingredients', jsonEncode(_items.map((e) => e.toJson()).toList()));
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
        _items.addAll(decoded.map((json) => GroceryItem(
              id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: json['name'] ?? '',
              amount: (json['amount'] as num).toDouble(),
              unit: json['unit'] ?? 'pcs',
              price: (json['price'] as num?)?.toDouble() ?? 0.0,
              createdAt: json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'])
                  : DateTime.now(),
              isPurchased: json['isPurchased'] ?? false,
            )));
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
          _items.add(GroceryItem(
            id: itemJson['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: itemJson['name'] ?? '',
            amount: (itemJson['amount'] as num).toDouble(),
            unit: itemJson['unit'] ?? 'pcs',
            price: (itemJson['price'] as num?)?.toDouble() ?? 0.0,
            createdAt: itemJson['createdAt'] != null
                ? DateTime.parse(itemJson['createdAt'])
                : DateTime.now(),
            isPurchased: itemJson['isPurchased'] ?? false,
          ));
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
