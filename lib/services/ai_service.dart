import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/grocery_item.dart';

/// AI Service - Enhanced for Recipe & Ingredient Extraction
/// Handles communication with Gemini API for intelligent ingredient extraction
class AIService extends ChangeNotifier {
  // Gemini API Configuration
  static const String _baseUrl = 'generativelanguage.googleapis.com';
  static const String _apiVersion = 'v1beta';

  // API Key - Set this via setApiKey()
  String _apiKey = '';
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isConfigured => _apiKey.isNotEmpty;

  // Valid food ingredients database for filtering (English only)
  static const Set<String> _validIngredients = {
    // Vegetables
    'tomato', 'tomatoes', 'onion', 'onions', 'garlic', 'ginger', 'carrot', 'carrots',
    'potato', 'potatoes', 'broccoli', 'cabbage', 'lettuce', 'spinach', 'mushroom',
    'mushrooms', 'bell pepper', 'peppers', 'cucumber', 'celery', 'corn',
    'green beans', 'asparagus', 'zucchini', 'eggplant', 'cauliflower',
    'kale', 'peas', 'artichoke', 'brussels sprouts',

    // Meat
    'chicken', 'beef', 'pork', 'fish', 'shrimp', 'crab', 'bacon', 'ham', 'sausage',
    'meatball', 'meatballs', 'lamb', 'duck', 'turkey', 'veal', 'steak', 'salmon',
    'tuna', 'cod', 'tilapia', 'scallops', 'lobster',

    // Dairy
    'milk', 'cheese', 'butter', 'cream', 'yogurt', 'egg', 'eggs', 'sour cream',
    'whipped cream', 'heavy cream', 'buttermilk', 'condensed milk', 'parmesan',
    'mozzarella', 'cheddar', 'swiss', 'gouda', 'ricotta', 'feta', 'goat cheese',

    // Fruits
    'apple', 'apples', 'banana', 'bananas', 'orange', 'oranges', 'lemon', 'lime',
    'strawberry', 'strawberries', 'watermelon', 'mango', 'pineapple', 'grape', 'grapes',
    'blueberry', 'raspberry', 'blackberry', 'peach', 'pear', 'plum', 'cherry', 'kiwi',
    'avocado', 'coconut', 'pomegranate', 'fig', 'date',

    // Grains & Starch
    'rice', 'pasta', 'noodle', 'noodles', 'bread', 'flour', 'oats', 'cereal',
    'quinoa', 'barley', 'couscous', 'lentils', 'chickpeas', 'tortilla',
    'cracker', 'crackers', 'bagel', 'muffin', 'pancake', 'waffle', 'croissant',

    // Condiments & Sauces
    'salt', 'pepper', 'sugar', 'oil', 'olive oil', 'vegetable oil', 'soy sauce',
    'fish sauce', 'oyster sauce', 'vinegar', 'ketchup', 'mayonnaise', 'mustard',
    'relish', 'hot sauce', 'salsa', 'pesto', 'barbecue sauce', 'teriyaki sauce',
    'worcestershire sauce', 'tahini', 'hummus', 'guacamole',

    // Herbs & Spices
    'basil', 'oregano', 'thyme', 'rosemary', 'parsley', 'cilantro', 'dill', 'mint',
    'sage', 'cumin', 'paprika', 'cinnamon', 'nutmeg', 'cayenne', 'chili powder',
    'garlic powder', 'onion powder', 'turmeric', 'curry powder',

    // Nuts & Seeds
    'peanut', 'peanuts', 'almond', 'almonds', 'walnut', 'cashew', 'pecan',
    'pistachio', 'hazelnut', 'macadamia', 'sesame seeds', 'sunflower seeds',
    'pumpkin seeds', 'chia seeds', 'flax seeds',

    // Others
    'water', 'juice', 'coffee', 'tea', 'chocolate', 'honey', 'maple syrup',
    'vanilla extract', 'baking powder', 'baking soda', 'yeast', 'gelatin',
    'broth', 'stock', 'tomato sauce', 'pasta sauce', 'coconut milk',
  };

  // Invalid words to filter out (common speech recognition errors)
  static const Set<String> _invalidWords = {
    'um', 'uh', 'ah', 'like', 'just', 'basically',
    'kind of', 'sort of', 'you know', 'I mean', 'okay', 'alright',
    'maybe', 'probably', 'literally', 'seriously',
  };

  // Set your Gemini API Key here or use setApiKey()
  void setApiKey(String key) {
    _apiKey = key;
    notifyListeners();
  }

  /// Enhanced prompt for ingredient extraction (English only)
  static const String _systemPrompt = '''
You are a food ingredient extraction assistant specialized in English cuisine.

STRICT RULES:
1. Return ONLY a valid JSON array
2. Each item must have: "item" (name), "qty" (number), "unit" (pcs, kg, g, cup, liter, etc)
3. Extract ONLY food/ingredients - ignore non-food items
4. Remove speech filler words (um, uh, like, etc)
5. Use English ingredient names only
6. Default quantity is 1 if not specified
7. Default unit is "pcs" if not specified

VALID FOOD CATEGORIES:
- Vegetables: tomato, onion, garlic, carrot, broccoli, cabbage, lettuce, spinach, mushrooms
- Meat: chicken, pork, beef, fish, shrimp, crab, bacon, ham, sausage
- Dairy: milk, cheese, butter, eggs, yogurt, cream
- Fruits: apple, banana, orange, lemon, strawberry, mango
- Grains: rice, pasta, bread, flour, oats, cereal
- Condiments: salt, sugar, oil, soy sauce, vinegar, ketchup

INPUT EXAMPLES:
- "2 kg chicken" -> [{"item":"chicken","qty":2,"unit":"kg"}]
- "500g beef and 3 onions" -> [{"item":"beef","qty":500,"unit":"g"},{"item":"onions","qty":3,"unit":"pcs"}]
- "Need eggs and milk" -> [{"item":"eggs","qty":1,"unit":"pcs"},{"item":"milk","qty":1,"unit":"liter"}]
- "5 apples" -> [{"item":"apples","qty":5,"unit":"pcs"}]

Return ONLY the JSON array, no explanation.
''';

  /// Process input string and return structured ingredients
  /// Enhanced to filter invalid words and focus on food ingredients
  Future<List<GroceryItem>> processInput(String userInput) async {
    if (userInput.trim().isEmpty) {
      _errorMessage = 'Input cannot be empty';
      notifyListeners();
      return [];
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Pre-process input: remove invalid words
      final cleanedInput = _cleanInput(userInput);
      debugPrint('Processing input: "$cleanedInput"');

      // Try AI API first (if configured)
      if (isConfigured) {
        try {
          final items = await _callGeminiAPI(cleanedInput);
          final validItems = _filterValidIngredients(items);

          if (validItems.isNotEmpty) {
            _isLoading = false;
            notifyListeners();
            debugPrint('API returned ${validItems.length} items');
            return validItems;
          }
        } catch (e) {
          debugPrint('AI API failed, falling back to local parsing: $e');
        }
      }

      // Fallback to enhanced local parsing
      final items = _tryLocalParsing(cleanedInput);
      final validItems = _filterValidIngredients(items);

      // ULTIMATE FALLBACK: If still empty, try to extract ANY word as ingredient
      if (validItems.isEmpty) {
        debugPrint('Local parsing failed, trying ultimate fallback');
        final fallbackItems = _ultimateFallback(cleanedInput);
        if (fallbackItems.isNotEmpty) {
          _isLoading = false;
          notifyListeners();
          return fallbackItems;
        }
      }

      _isLoading = false;
      notifyListeners();

      return validItems;
    } catch (e) {
      _errorMessage = 'Error processing input: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Process Input Error: $e');

      // Return empty list on error
      return [];
    }
  }

  /// Ultimate fallback - extract ANY word as ingredient with default values
  List<GroceryItem> _ultimateFallback(String input) {
    debugPrint('Ultimate fallback for: "$input"');
    final List<GroceryItem> items = [];

    // Extract all words (2-20 characters, letters only)
    final words = RegExp(r'\b[a-zA-Z]{2,20}\b').allMatches(input).map((m) => m.group(0)!).toList();

    for (final word in words) {
      final lower = word.toLowerCase();
      // Skip obvious non-words
      if (['the', 'and', 'for', 'with', 'have', 'want', 'need', 'get', 'make', 'cook'].contains(lower)) {
        continue;
      }

      items.add(GroceryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_${items.length}',
        name: lower,
        amount: 1,
        unit: 'pcs',
      ));
      debugPrint('  -> Fallback added: $lower');
    }

    return items;
  }

  /// Clean input by removing invalid filler words
  String _cleanInput(String input) {
    String cleaned = input;

    // Remove invalid words
    for (final word in _invalidWords) {
      cleaned = cleaned.replaceAll(RegExp(r'\b' + word + r'\b', caseSensitive: false), '');
    }

    // Clean up multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  /// Filter ingredients to keep only valid food items
  List<GroceryItem> _filterValidIngredients(List<GroceryItem> items) {
    return items.where((item) {
      final itemName = item.name.toLowerCase();
      return _isValidIngredient(itemName);
    }).toList();
  }

  /// Check if an ingredient is valid food item (English only)
  bool _isValidIngredient(String itemName) {
    // Check against valid ingredients list (partial match allowed)
    for (final valid in _validIngredients) {
      if (itemName.contains(valid) || valid.contains(itemName)) {
        return true;
      }
    }

    // Check if it's a plural of a valid ingredient
    if (itemName.endsWith('s')) {
      final singular = itemName.substring(0, itemName.length - 1);
      return _validIngredients.contains(singular);
    }

    // If not found in list, use basic food keyword check (English only)
    final foodKeywords = [
      'meat', 'fish', 'chicken', 'pork', 'beef', 'shrimp', 'crab',
      'vegetable', 'fruit', 'dairy', 'grain', 'herb', 'spice',
    ];

    for (final keyword in foodKeywords) {
      if (itemName.contains(keyword)) {
        return true;
      }
    }

    // Accept short words (likely valid ingredients)
    if (itemName.length <= 15 && itemName.length >= 2) {
      // Only accept English letters and spaces
      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(itemName)) {
        return false;
      }
      return true;
    }

    return false;
  }

  /// Call Gemini API for ingredient extraction
  Future<List<GroceryItem>> _callGeminiAPI(String userInput) async {
    final url = Uri.https(_baseUrl, '/$_apiVersion/models/gemini-pro:generateContent', {
      'key': _apiKey,
    });

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': '$_systemPrompt\n\nUser Input: "$userInput"\n\nJSON Response:'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2, // Lower for more consistent output
        'maxOutputTokens': 1024,
        'topK': 40,
        'topP': 0.95,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('AI request timed out');
      },
    );

    if (response.statusCode == 200) {
      return _parseGeminiResponse(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API Key');
    } else if (response.statusCode == 429) {
      throw Exception('API rate limit exceeded');
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Parse Gemini API response
  List<GroceryItem> _parseGeminiResponse(String responseBody) {
    try {
      final jsonData = jsonDecode(responseBody);

      if (jsonData['candidates'] != null &&
          jsonData['candidates'].isNotEmpty &&
          jsonData['candidates'][0]['content'] != null &&
          jsonData['candidates'][0]['content']['parts'] != null &&
          jsonData['candidates'][0]['content']['parts'].isNotEmpty) {

        String text = jsonData['candidates'][0]['content']['parts'][0]['text'] ?? '';

        // Clean the response
        text = text.trim();
        if (text.startsWith('```json')) {
          text = text.substring(7);
        } else if (text.startsWith('```')) {
          text = text.substring(3);
        }
        if (text.endsWith('```')) {
          text = text.substring(0, text.length - 3);
        }
        text = text.trim();

        // Parse JSON array
        final List<dynamic> jsonList = jsonDecode(text);

        return jsonList.map((json) => GroceryItem.fromJson(json)).toList();
      }

      throw Exception('Invalid response structure from Gemini');
    } catch (e) {
      debugPrint('Parse Error: $e');
      throw Exception('Failed to parse AI response: $e');
    }
  }

  /// Enhanced local parsing for English ingredients
  List<GroceryItem> _tryLocalParsing(String input) {
    final List<GroceryItem> items = [];

    debugPrint('Local parsing input: "$input"');

    // Simple patterns to try in order
    final patterns = [
      // Pattern 1: "2 kg chicken" or "500g beef"
      RegExp(r'(\d+(?:\.\d+)?)\s*(kg|g|gram|grams|lb|oz|liter|ml|cup|pcs|pieces)?\s*([a-z]+)', caseSensitive: false),
      // Pattern 2: "chicken 2kg" or "beef 500g"
      RegExp(r'([a-z]+)\s+(\d+(?:\.\d+)?)\s*(kg|g|gram|grams|lbs?|oz|ml|liter|cup|pcs)?', caseSensitive: false),
      // Pattern 3: "5 apples" or "10 eggs"
      RegExp(r'(\d+(?:\.\d+)?)\s+([a-z]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(input);
      debugPrint('Pattern ${pattern.pattern} found ${matches.length} matches');

      for (final match in matches) {
        try {
          late final String name;
          late final double amount;
          late final String unit;

          // Determine which pattern matched and extract accordingly
          if (match.groupCount >= 3 && match.group(3) != null && RegExp(r'[a-z]', caseSensitive: false).hasMatch(match.group(3) ?? '')) {
            // Pattern 1: amount unit name
            amount = double.tryParse(match.group(1) ?? '1') ?? 1;
            unit = _normalizeUnit(match.group(2) ?? '');
            name = _cleanItemName(match.group(3) ?? '');
          } else if (match.group(1) != null && RegExp(r'[a-z]', caseSensitive: false).hasMatch(match.group(1) ?? '')) {
            // Pattern 2: name amount unit
            name = _cleanItemName(match.group(1) ?? '');
            amount = double.tryParse(match.group(2) ?? '1') ?? 1;
            unit = _normalizeUnit(match.group(3) ?? '');
          } else {
            // Pattern 3: amount name
            amount = double.tryParse(match.group(1) ?? '1') ?? 1;
            name = _cleanItemName(match.group(2) ?? '');
            unit = 'pcs';
          }

          if (name.isNotEmpty && _isLikelyIngredient(name)) {
            final item = GroceryItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              amount: amount,
              unit: unit.isNotEmpty ? unit : 'pcs',
            );
            items.add(item);
            debugPrint('  -> Parsed: ${item.name} (${item.amount} ${item.unit})');
          }
        } catch (e) {
          debugPrint('Parse error: $e');
        }
      }

      if (items.isNotEmpty) break; // Stop if we found something
    }

    // Remove duplicates based on name
    final uniqueItems = <String, GroceryItem>{};
    for (final item in items) {
      final key = item.name.toLowerCase();
      if (!uniqueItems.containsKey(key)) {
        uniqueItems[key] = item;
      }
    }

    debugPrint('Final parsed items: ${uniqueItems.values.length}');
    return uniqueItems.values.toList();
  }

  /// Check if a word is likely a food ingredient (English only)
  bool _isLikelyIngredient(String name) {
    if (name.isEmpty) return false;

    final lower = name.toLowerCase().trim();

    debugPrint('Checking if "$name" is likely ingredient');

    // Reject obvious non-food words
    final nonFood = [
      'the', 'a', 'an', 'and', 'or', 'but', 'for', 'with', 'without',
      'want', 'need', 'have', 'get', 'add', 'put', 'make', 'cook',
      'some', 'more', 'much', 'many', 'lot', 'little', 'bit',
      'recipe', 'dish', 'meal', 'food', 'cooking',
      'please', 'thanks', 'thank', 'hello', 'hi',
    ];

    if (nonFood.contains(lower)) {
      debugPrint('  -> Rejected (non-food word)');
      return false;
    }

    // Accept known ingredients
    if (_isValidIngredient(lower)) {
      debugPrint('  -> Accepted (valid ingredient)');
      return true;
    }

    // Accept if it's a food-related word (2-25 characters)
    if (lower.length >= 2 && lower.length <= 25) {
      // Common food categories
      final foodCategories = [
        'meat', 'fish', 'chicken', 'pork', 'beef', 'shrimp', 'crab',
        'fruit', 'vegetable', 'dairy', 'cheese', 'milk', 'egg', 'eggs',
        'rice', 'bread', 'pasta', 'noodle', 'sauce', 'oil', 'spice',
        'salt', 'sugar', 'pepper', 'onion', 'garlic', 'tomato', 'tomatoes',
        'potato', 'carrot', 'beans', 'leaf', 'green', 'apple', 'banana',
      ];

      for (final category in foodCategories) {
        if (lower.contains(category)) {
          debugPrint('  -> Accepted (contains food category: $category)');
          return true;
        }
      }

      // More permissive: Accept reasonable length words that aren't obvious junk
      if (RegExp(r'^[a-z\s]+$').hasMatch(lower)) {
        debugPrint('  -> Accepted (valid word format)');
        return true;
      }
    }

    debugPrint('  -> Rejected (failed all checks)');
    return false;
  }

  /// Clean item name from extra words and symbols (English only)
  String _cleanItemName(String name) {
    return name
        .replaceAll(RegExp(r'[0-9]'), '')
        .replaceAll(RegExp(r'[^\w\s]'), '')  // Only alphanumeric and spaces
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .join(' ');
  }

  /// Normalize unit names (English only)
  String _normalizeUnit(String unit) {
    final normalized = unit.toLowerCase().trim();

    final unitMap = {
      'kilogram': 'kg', 'kg': 'kg',
      'gram': 'g', 'g': 'g',
      'pound': 'lb', 'lb': 'lb',
      'ounce': 'oz', 'oz': 'oz',
      'liter': 'liter', 'litre': 'liter', 'l': 'liter',
      'milliliter': 'ml', 'ml': 'ml',
      'piece': 'pcs', 'pieces': 'pcs', 'pc': 'pcs', 'pcs': 'pcs',
      'dozen': 'dozen',
      'pack': 'pack', 'package': 'pack',
      'bag': 'bag',
      'bottle': 'bottle',
      'can': 'can', 'cans': 'can',
      'head': 'head',
      'clove': 'cloves', 'cloves': 'cloves',
      'cup': 'cup', 'cups': 'cup',
    };

    return unitMap[normalized] ?? normalized;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
