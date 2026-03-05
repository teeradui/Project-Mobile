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

  // Valid food ingredients database for filtering
  static const Set<String> _validIngredients = {
    // Vegetables (ผัก)
    'tomato', 'tomatoes', 'onion', 'onions', 'garlic', 'ginger', 'carrot', 'carrots',
    'potato', 'potatoes', 'broccoli', 'cabbage', 'lettuce', 'spinach', 'mushroom',
    'mushrooms', 'bell pepper', 'peppers', 'cucumber', 'celery', 'corn', 'beans',
    'ถั่ว', 'ผัก', 'มะเขือ', 'พริก', 'กระเทียม', 'หอม', 'แครอท', 'มัน', 'ผักกาด',

    // Meat (เนื้อ)
    'chicken', 'beef', 'pork', 'fish', 'shrimp', 'crab', 'bacon', 'ham', 'sausage',
    'meatball', 'meatballs', 'lamb', 'duck', 'ไก่', 'หมู', 'เนื้อ', 'ปลา', 'กุ้ง', 'หมึก',

    // Dairy (นม)
    'milk', 'cheese', 'butter', 'cream', 'yogurt', 'egg', 'eggs',
    'นม', 'เนย', 'ไข่', 'ชีส', 'โยเกิร์ต',

    // Fruits (ผลไม้)
    'apple', 'apples', 'banana', 'bananas', 'orange', 'oranges', 'lemon', 'lime',
    'strawberry', 'watermelon', 'mango', 'pineapple', 'grape', 'grapes',
    'ส้ม', 'กล้วย', 'แอปเปิ้ล', 'มะนาว', 'สับปะรด', 'มะม่วง',

    // Grains & Starch (ธัญพืช)
    'rice', 'pasta', 'noodle', 'noodles', 'bread', 'flour', 'oats', 'cereal',
    'ข้าว', 'บะหมี่', 'เส้น', 'ขนมปัง', 'แป้ง',

    // Condiments & Sauces (เครื่องปรุง)
    'salt', 'pepper', 'sugar', 'oil', 'soy sauce', 'fish sauce', 'oyster sauce',
    'vinegar', 'ketchup', 'mayonnaise', 'mustard', 'herbs', 'spices',
    'น้ำปลา', 'ซอส', 'น้ำมัน', 'เกลือ', 'พริกไทย', 'น้ำตาล', 'น้ำส้ม',

    // Others (อื่นๆ)
    'water', 'juice', 'coffee', 'tea', 'chocolate', 'honey', 'peanut', 'peanuts',
    'almond', 'almonds', 'walnut', 'cashew', 'coconut', 'น้ำ', 'กาแฟ', 'ชา', 'มะพร้าว',
  };

  // Invalid words to filter out (common speech recognition errors)
  static const Set<String> _invalidWords = {
    'um', 'uh', 'ah', 'like', 'just', 'actually', 'basically',
    'kind of', 'sort of', 'you know', 'I mean', 'okay', 'alright',
    'เออ', 'อือ', 'อะ', 'ง่า', 'ซึ้ง', 'นะ', 'อ่ะ', 'อ่อ',
  };

  // Set your Gemini API Key here or use setApiKey()
  void setApiKey(String key) {
    _apiKey = key;
    notifyListeners();
  }

  /// Enhanced prompt for ingredient extraction
  static const String _systemPrompt = '''
You are a food ingredient extraction assistant specialized in Thai and English cuisine.

STRICT RULES:
1. Return ONLY a valid JSON array
2. Each item must have: "item" (name), "qty" (number), "unit" (pcs, kg, g, cup, liter, etc)
3. Extract ONLY food/ingredients - ignore non-food items
4. Remove speech filler words (um, uh, like, etc)
5. Support both Thai and English ingredient names
6. Default quantity is 1 if not specified
7. Default unit is "pcs" if not specified

VALID FOOD CATEGORIES:
- Vegetables: tomato, onion, garlic, carrot, broccoli, ถั่ว, ผัก, มะเขือ, พริก
- Meat: chicken, pork, beef, fish, shrimp, ไก่, หมู, เนื้อ, ปลา, กุ้ง
- Dairy: milk, cheese, butter, eggs, นม, ไข่
- Fruits: apple, banana, orange,'berry', 'berries' ส้ม, กล้วย, มะม่วง
- Grains: rice, pasta, bread, ข้าว, บะหมี่, ขนมปัง
- Condiments: salt, sugar, oil, sauce, เกลือ, น้ำปลา, ซอส

INPUT EXAMPLES:
- "2 kg chicken" -> [{"item":"chicken","qty":2,"unit":"kg"}]
- "ไก่ 2 ตัว พริก 5 เม็ด" -> [{"item":"ไก่","qty":2,"unit":"ตัว"},{"item":"พริก","qty":5,"unit":"เม็ด"}]
- "Need eggs and milk" -> [{"item":"eggs","qty":1,"unit":"pcs"},{"item":"milk","qty":1,"unit":"liter"}]
- "ขอไก่กับพริกหน่อย" -> [{"item":"ไก่","qty":1,"unit":"ตัว"},{"item":"พริก","qty":1,"unit":"ถุง"}]

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

      // Try AI API first (if configured)
      if (isConfigured) {
        try {
          final items = await _callGeminiAPI(cleanedInput);
          final validItems = _filterValidIngredients(items);

          if (validItems.isNotEmpty) {
            _isLoading = false;
            notifyListeners();
            return validItems;
          }
        } catch (e) {
          debugPrint('AI API failed, falling back to local parsing: $e');
        }
      }

      // Fallback to enhanced local parsing
      final items = _tryLocalParsing(cleanedInput);
      final validItems = _filterValidIngredients(items);

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

  /// Check if an ingredient is valid food item
  bool _isValidIngredient(String itemName) {
    // Check against valid ingredients list (partial match allowed)
    for (final valid in _validIngredients) {
      if (itemName.contains(valid) || valid.contains(itemName)) {
        return true;
      }
    }

    // Check if it's a plural of a valid ingredient
  // Handle plural forms
  if (itemName.endsWith('ies') && itemName.length > 3) {
    final singular = itemName.substring(0, itemName.length - 3) + 'y';
    if (_validIngredients.contains(singular)) return true;
  }

  if (itemName.endsWith('s') && !itemName.endsWith('ss')) {
    final singular = itemName.substring(0, itemName.length - 1);
    if (_validIngredients.contains(singular)) return true;
  }
    // If not found in list, use basic food keyword check
    final foodKeywords = [
      'meat', 'fish', 'chicken', 'pork', 'beef', 'shrimp', 'crab',
      'vegetable', 'fruit', 'dairy', 'grain', 'herb', 'spice',
      'เนื้อ', 'ปลา', 'ไก่', 'หมู', 'กุ้ง', 'ผัก', 'ผลไม้', 'เครื่องเทศ',
    ];

    for (final keyword in foodKeywords) {
      if (itemName.contains(keyword)) {
        return true;
      }
    }

    // Accept short words (likely valid ingredients)
    if (itemName.length <= 15 && itemName.length >= 2) {
      // Reject obviously invalid patterns
      if (!RegExp(r'^[a-zA-Zก-๙ะ-์\s]+$').hasMatch(itemName)) {
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

  /// Enhanced local parsing for Thai and English ingredients
  List<GroceryItem> _tryLocalParsing(String input) {
    final List<GroceryItem> items = [];

    // Thai pattern: "ไก่ 2 ตัว", "พริก 5 เม็ด"
    final thaiPattern = RegExp(
      r'([ก-๙\s]+)\s*(\d+(?:\.\d+)?)\s*(ตัว|เม็ด|กรัม|กิโล|ถ้วย|หัว|ลูก|ซอง|แพ็ค|ลิตร)?',
      caseSensitive: false,
    );

    // English pattern: "2 kg chicken", "5 apples"
   final englishPattern = RegExp(
  r'(\d+(?:\.\d+)?)\s*(kg|g|lb|oz|liter|ml|cup|pcs|pieces|dozen|pack|bag|bottle|cans?)?\s*(?:of\s+)?([a-zA-Z]+(?:\s+[a-zA-Z]+)*)',
  caseSensitive: false,
);

    // Simple pattern: "chicken", "ไก่"
    final simplePattern = RegExp(r'([a-zA-Zก-๙]+(?:\s+[a-zA-Zก-๙]+)*)', caseSensitive: false);

    // Try Thai pattern first
    final thaiMatches = thaiPattern.allMatches(input);
    for (final match in thaiMatches) {
      try {
        final name = _cleanItemName(match.group(1) ?? '');
        final amount = double.tryParse(match.group(2) ?? '1') ?? 1;
        final unit = match.group(3) ?? 'ตัว';

        if (name.isNotEmpty && _isValidIngredient(name)) {
          items.add(GroceryItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            amount: amount,
            unit: unit,
          ));
        }
      } catch (e) {
        debugPrint('Thai parse error: $e');
      }
    }

    // Try English pattern
    final englishMatches = englishPattern.allMatches(input);
    for (final match in englishMatches) {
      try {
        final amount = double.tryParse(match.group(1) ?? '1') ?? 1;
        final unit = _normalizeUnit(match.group(2) ?? 'pcs');
        final name = _cleanItemName(match.group(3) ?? '');

        if (name.isNotEmpty && _isValidIngredient(name)) {
          items.add(GroceryItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            amount: amount,
            unit: unit,
          ));
        }
      } catch (e) {
        debugPrint('English parse error: $e');
      }
    }

    // If no patterns matched, try simple word extraction
    if (items.isEmpty) {
      final simpleMatches = simplePattern.allMatches(input);
      final words = simpleMatches.map((m) => m.group(1)!).toSet();

      for (final word in words) {
        final cleaned = _cleanItemName(word);
        if (cleaned.length >= 2 && _isValidIngredient(cleaned)) {
          items.add(GroceryItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: cleaned,
            amount: 1,
            unit: 'pcs',
          ));
        }
      }
    }

    return items;
  }

  /// Normalize unit names
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
      'ตัว': 'ตัว',
      'เม็ด': 'เม็ด',
      'กรัม': 'g',
      'กิโล': 'kg',
      'ลิตร': 'liter',
      'ถ้วย': 'cup',
      'หัว': 'head',
      'ลูก': 'pcs',
      'ซอง': 'can',
      'แพ็ค': 'pack',
    };

    return unitMap[normalized] ?? normalized;
  }

  /// Clean item name from extra words and symbols
  String _cleanItemName(String name) {
    return name
        .replaceAll(RegExp(r'[0-9]'), '')
        .replaceAll(RegExp(r'[^\w\sก-๙ะ-์]'), '')
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .join(' ');
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
