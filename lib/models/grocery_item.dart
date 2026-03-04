import 'package:flutter/material.dart';

/// Grocery Item Model
/// Represents a single grocery item with all relevant properties
class GroceryItem {
  final String id;
  final String name;
  final double amount;
  final String unit;
  final double price;
  final DateTime createdAt;
  final bool isPurchased;

  GroceryItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    this.price = 0.0,
    DateTime? createdAt,
    this.isPurchased = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create GroceryItem from JSON (AI response)
  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['item'] ?? json['name'] ?? 'Unknown Item',
      amount: _parseDouble(json['qty'] ?? json['quantity'] ?? json['amount'] ?? 1),
      unit: json['unit'] ?? 'pcs',
      price: _parseDouble(json['price'] ?? 0.0),
    );
  }

  /// Parse double safely from various types
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'unit': unit,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
      'isPurchased': isPurchased,
    };
  }

  /// Create a copy with modified fields
  GroceryItem copyWith({
    String? id,
    String? name,
    double? amount,
    String? unit,
    double? price,
    DateTime? createdAt,
    bool? isPurchased,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }

  /// Calculate total price for this item
  double get totalPrice => amount * price;

  /// Get formatted amount string
  String get formattedAmount {
    // Remove trailing zeros for whole numbers
    if (amount == amount.truncateToDouble()) {
      return '${amount.toInt()} $unit';
    }
    return '$amount $unit';
  }

  /// Get formatted price string
  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }

  /// Get formatted total price string
  String get formattedTotalPrice {
    return '\$${totalPrice.toStringAsFixed(2)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroceryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroceryItem{id: $id, name: $name, amount: $amount, unit: $unit, price: $price}';
  }
}

/// Grocery List Category for better organization
enum GroceryCategory {
  produce('🍅', 'Vegetables & Fruits', Colors.green),
  dairy('🥛', 'Dairy', Colors.blue),
  meat('🥩', 'Meat', Colors.red),
  pantry('🥫', 'Pantry', Colors.orange),
  frozen('❄️', 'Frozen', Colors.cyan),
  bakery('🍞', 'Bakery', Colors.brown),
  beverages('🥤', 'Beverages', Colors.purple),
  other('📦', 'Other', Colors.grey);

  final String emoji;
  final String label;
  final Color color;

  const GroceryCategory(this.emoji, this.label, this.color);

  /// Comprehensive ingredient database for accurate categorization
  static const Map<String, GroceryCategory> _ingredientDatabase = {
    // === PRODUCE (Vegetables & Fruits) ===
    // Vegetables
    'tomato': GroceryCategory.produce,
    'tomatoes': GroceryCategory.produce,
    'onion': GroceryCategory.produce,
    'onions': GroceryCategory.produce,
    'garlic': GroceryCategory.produce,
    'garlic clove': GroceryCategory.produce,
    'ginger': GroceryCategory.produce,
    'potato': GroceryCategory.produce,
    'potatoes': GroceryCategory.produce,
    'carrot': GroceryCategory.produce,
    'carrots': GroceryCategory.produce,
    'broccoli': GroceryCategory.produce,
    'cauliflower': GroceryCategory.produce,
    'cucumber': GroceryCategory.produce,
    'cucumbers': GroceryCategory.produce,
    'lettuce': GroceryCategory.produce,
    'spinach': GroceryCategory.produce,
    'kale': GroceryCategory.produce,
    'cabbage': GroceryCategory.produce,
    'celery': GroceryCategory.produce,
    'mushroom': GroceryCategory.produce,
    'mushrooms': GroceryCategory.produce,
    'pepper': GroceryCategory.produce,
    'peppers': GroceryCategory.produce,
    'bell pepper': GroceryCategory.produce,
    'jalapeno': GroceryCategory.produce,
    'chili': GroceryCategory.produce,
    'chili pepper': GroceryCategory.produce,
    'corn': GroceryCategory.produce,
    'beans': GroceryCategory.produce,
    'green beans': GroceryCategory.produce,
    'snap peas': GroceryCategory.produce,
    'snow peas': GroceryCategory.produce,
    'zucchini': GroceryCategory.produce,
    'squash': GroceryCategory.produce,
    'pumpkin': GroceryCategory.produce,
    'eggplant': GroceryCategory.produce,
    'asparagus': GroceryCategory.produce,
    'brussels sprouts': GroceryCategory.produce,
    'artichoke': GroceryCategory.produce,
    'beet': GroceryCategory.produce,
    'radish': GroceryCategory.produce,
    'turnip': GroceryCategory.produce,
    'leek': GroceryCategory.produce,
    'scallion': GroceryCategory.produce,
    'shallot': GroceryCategory.produce,
    'bok choy': GroceryCategory.produce,
    'chard': GroceryCategory.produce,
    'collard greens': GroceryCategory.produce,
    'arugula': GroceryCategory.produce,
    'endive': GroceryCategory.produce,
    'watercress': GroceryCategory.produce,
    'napa cabbage': GroceryCategory.produce,

    // Herbs
    'basil': GroceryCategory.produce,
    'parsley': GroceryCategory.produce,
    'cilantro': GroceryCategory.produce,
    'coriander': GroceryCategory.produce,
    'mint': GroceryCategory.produce,
    'dill': GroceryCategory.produce,
    'rosemary': GroceryCategory.produce,
    'thyme': GroceryCategory.produce,
    'oregano': GroceryCategory.produce,
    'sage': GroceryCategory.produce,
    'tarragon': GroceryCategory.produce,
    'marjoram': GroceryCategory.produce,
    'chives': GroceryCategory.produce,
    'bay leaf': GroceryCategory.produce,
    'lemongrass': GroceryCategory.produce,

    // Fruits
    'apple': GroceryCategory.produce,
    'apples': GroceryCategory.produce,
    'banana': GroceryCategory.produce,
    'bananas': GroceryCategory.produce,
    'orange': GroceryCategory.produce,
    'oranges': GroceryCategory.produce,
    'lemon': GroceryCategory.produce,
    'lemons': GroceryCategory.produce,
    'lime': GroceryCategory.produce,
    'limes': GroceryCategory.produce,
    'strawberry': GroceryCategory.produce,
    'strawberries': GroceryCategory.produce,
    'blueberry': GroceryCategory.produce,
    'blueberries': GroceryCategory.produce,
    'raspberry': GroceryCategory.produce,
    'raspberries': GroceryCategory.produce,
    'blackberry': GroceryCategory.produce,
    'grape': GroceryCategory.produce,
    'grapes': GroceryCategory.produce,
    'mango': GroceryCategory.produce,
    'pineapple': GroceryCategory.produce,
    'watermelon': GroceryCategory.produce,
    'cantaloupe': GroceryCategory.produce,
    'honeydew': GroceryCategory.produce,
    'peach': GroceryCategory.produce,
    'peaches': GroceryCategory.produce,
    'nectarine': GroceryCategory.produce,
    'plum': GroceryCategory.produce,
    'pear': GroceryCategory.produce,
    'cherry': GroceryCategory.produce,
    'cherries': GroceryCategory.produce,
    'kiwi': GroceryCategory.produce,
    'avocado': GroceryCategory.produce,
    'papaya': GroceryCategory.produce,
    'pomegranate': GroceryCategory.produce,
    'fig': GroceryCategory.produce,
    'date': GroceryCategory.produce,
    'coconut': GroceryCategory.produce,

    // === DAIRY ===
    'milk': GroceryCategory.dairy,
    'whole milk': GroceryCategory.dairy,
    'skim milk': GroceryCategory.dairy,
    'cream': GroceryCategory.dairy,
    'heavy cream': GroceryCategory.dairy,
    'whipping cream': GroceryCategory.dairy,
    'half and half': GroceryCategory.dairy,
    'cheese': GroceryCategory.dairy,
    'cheddar': GroceryCategory.dairy,
    'mozzarella': GroceryCategory.dairy,
    'parmesan': GroceryCategory.dairy,
    'gouda': GroceryCategory.dairy,
    'swiss cheese': GroceryCategory.dairy,
    'brie': GroceryCategory.dairy,
    'camembert': GroceryCategory.dairy,
    'feta': GroceryCategory.dairy,
    'goat cheese': GroceryCategory.dairy,
    'cream cheese': GroceryCategory.dairy,
    'cottage cheese': GroceryCategory.dairy,
    'ricotta': GroceryCategory.dairy,
    'yogurt': GroceryCategory.dairy,
    'greek yogurt': GroceryCategory.dairy,
    'butter': GroceryCategory.dairy,
    'margarine': GroceryCategory.dairy,
    'sour cream': GroceryCategory.dairy,
    'buttermilk': GroceryCategory.dairy,
    'condensed milk': GroceryCategory.dairy,
    'evaporated milk': GroceryCategory.dairy,
    'ice cream': GroceryCategory.dairy,
    'whipped cream': GroceryCategory.dairy,
    'coconut milk': GroceryCategory.dairy,

    // === MEAT (Proteins) ===
    'chicken': GroceryCategory.meat,
    'chicken breast': GroceryCategory.meat,
    'chicken thigh': GroceryCategory.meat,
    'chicken wing': GroceryCategory.meat,
    'whole chicken': GroceryCategory.meat,
    'beef': GroceryCategory.meat,
    'steak': GroceryCategory.meat,
    'ground beef': GroceryCategory.meat,
    'beef roast': GroceryCategory.meat,
    'ribs': GroceryCategory.meat,
    'brisket': GroceryCategory.meat,
    'pork': GroceryCategory.meat,
    'pork chop': GroceryCategory.meat,
    'pork loin': GroceryCategory.meat,
    'bacon': GroceryCategory.meat,
    'ham': GroceryCategory.meat,
    'sausage': GroceryCategory.meat,
    'meatball': GroceryCategory.meat,
    'lamb': GroceryCategory.meat,
    'lamb chop': GroceryCategory.meat,
    'veal': GroceryCategory.meat,
    'turkey': GroceryCategory.meat,
    'duck': GroceryCategory.meat,

    // Seafood
    'fish': GroceryCategory.meat,
    'salmon': GroceryCategory.meat,
    'tuna': GroceryCategory.meat,
    'cod': GroceryCategory.meat,
    'tilapia': GroceryCategory.meat,
    'trout': GroceryCategory.meat,
    'snapper': GroceryCategory.meat,
    'halibut': GroceryCategory.meat,
    'sardines': GroceryCategory.meat,
    'mackerel': GroceryCategory.meat,
    'shrimp': GroceryCategory.meat,
    'prawn': GroceryCategory.meat,
    'crab': GroceryCategory.meat,
    'lobster': GroceryCategory.meat,
    'scallops': GroceryCategory.meat,
    'clams': GroceryCategory.meat,
    'mussels': GroceryCategory.meat,
    'oysters': GroceryCategory.meat,
    'squid': GroceryCategory.meat,
    'calamari': GroceryCategory.meat,
    'octopus': GroceryCategory.meat,

    // Other proteins
    'egg': GroceryCategory.meat,
    'eggs': GroceryCategory.meat,
    'tofu': GroceryCategory.meat,
    'tempeh': GroceryCategory.meat,
    'seitan': GroceryCategory.meat,

    // === BAKERY ===
    'bread': GroceryCategory.bakery,
    'white bread': GroceryCategory.bakery,
    'whole wheat bread': GroceryCategory.bakery,
    'sourdough bread': GroceryCategory.bakery,
    'bagel': GroceryCategory.bakery,
    'bagels': GroceryCategory.bakery,
    'muffin': GroceryCategory.bakery,
    'muffins': GroceryCategory.bakery,
    'croissant': GroceryCategory.bakery,
    'bun': GroceryCategory.bakery,
    'buns': GroceryCategory.bakery,
    'roll': GroceryCategory.bakery,
    'rolls': GroceryCategory.bakery,
    'tortilla': GroceryCategory.bakery,
    'pita': GroceryCategory.bakery,
    'naan': GroceryCategory.bakery,
    'pastry': GroceryCategory.bakery,
    'danish': GroceryCategory.bakery,
    'donut': GroceryCategory.bakery,
    'cake': GroceryCategory.bakery,
    'cookie': GroceryCategory.bakery,
    'cracker': GroceryCategory.bakery,

    // === PANTRY (Dry goods, condiments, spices) ===
    // Grains & Pasta
    'rice': GroceryCategory.pantry,
    'white rice': GroceryCategory.pantry,
    'brown rice': GroceryCategory.pantry,
    'jasmine rice': GroceryCategory.pantry,
    'basmati rice': GroceryCategory.pantry,
    'wild rice': GroceryCategory.pantry,
    'pasta': GroceryCategory.pantry,
    'spaghetti': GroceryCategory.pantry,
    'penne': GroceryCategory.pantry,
    'macaroni': GroceryCategory.pantry,
    'linguine': GroceryCategory.pantry,
    'fettuccine': GroceryCategory.pantry,
    'lasagna': GroceryCategory.pantry,
    'ravioli': GroceryCategory.pantry,
    'noodle': GroceryCategory.pantry,
    'noodles': GroceryCategory.pantry,
    'ramen': GroceryCategory.pantry,
    'udon': GroceryCategory.pantry,
    'soba': GroceryCategory.pantry,
    'rice noodles': GroceryCategory.pantry,
    'egg noodles': GroceryCategory.pantry,
    'flour': GroceryCategory.pantry,
    'all purpose flour': GroceryCategory.pantry,
    'whole wheat flour': GroceryCategory.pantry,
    'bread flour': GroceryCategory.pantry,
    'cake flour': GroceryCategory.pantry,
    'almond flour': GroceryCategory.pantry,
    'coconut flour': GroceryCategory.pantry,
    'oats': GroceryCategory.pantry,
    'oatmeal': GroceryCategory.pantry,
    'cereal': GroceryCategory.pantry,
    'granola': GroceryCategory.pantry,
    'quinoa': GroceryCategory.pantry,
    'couscous': GroceryCategory.pantry,
    'barley': GroceryCategory.pantry,
    'bulgur': GroceryCategory.pantry,
    'farro': GroceryCategory.pantry,

    // Oils & Vinegars
    'oil': GroceryCategory.pantry,
    'olive oil': GroceryCategory.pantry,
    'vegetable oil': GroceryCategory.pantry,
    'canola oil': GroceryCategory.pantry,
    'sunflower oil': GroceryCategory.pantry,
    'sesame oil': GroceryCategory.pantry,
    'peanut oil': GroceryCategory.pantry,
    'coconut oil': GroceryCategory.pantry,
    'avocado oil': GroceryCategory.pantry,
    'vinegar': GroceryCategory.pantry,
    'balsamic vinegar': GroceryCategory.pantry,
    'apple cider vinegar': GroceryCategory.pantry,
    'white vinegar': GroceryCategory.pantry,
    'red wine vinegar': GroceryCategory.pantry,
    'rice vinegar': GroceryCategory.pantry,

    // Condiments & Sauces
    'sauce': GroceryCategory.pantry,
    'soy sauce': GroceryCategory.pantry,
    'tamari': GroceryCategory.pantry,
    'fish sauce': GroceryCategory.pantry,
    'oyster sauce': GroceryCategory.pantry,
    'hoisin sauce': GroceryCategory.pantry,
    'teriyaki sauce': GroceryCategory.pantry,
    'barbecue sauce': GroceryCategory.pantry,
    'ketchup': GroceryCategory.pantry,
    'mustard': GroceryCategory.pantry,
    'mayonnaise': GroceryCategory.pantry,
    'relish': GroceryCategory.pantry,
    'salsa': GroceryCategory.pantry,
    'pesto': GroceryCategory.pantry,
    'marinara': GroceryCategory.pantry,
    'alfredo sauce': GroceryCategory.pantry,
    'curry sauce': GroceryCategory.pantry,
    'tomato sauce': GroceryCategory.pantry,
    'tomato paste': GroceryCategory.pantry,
    'paste': GroceryCategory.pantry,
    'curry paste': GroceryCategory.pantry,
    'tahini': GroceryCategory.pantry,
    'hummus': GroceryCategory.pantry,
    'guacamole': GroceryCategory.pantry,
    'worcestershire': GroceryCategory.pantry,
    'hot sauce': GroceryCategory.pantry,
    'sriracha': GroceryCategory.pantry,
    'sambal': GroceryCategory.pantry,

    // Spices & Seasonings
    'salt': GroceryCategory.pantry,
    'sea salt': GroceryCategory.pantry,
    'kosher salt': GroceryCategory.pantry,
    'black pepper': GroceryCategory.pantry,
    'white pepper': GroceryCategory.pantry,
    'cayenne pepper': GroceryCategory.pantry,
    'paprika': GroceryCategory.pantry,
    'chili powder': GroceryCategory.pantry,
    'cumin': GroceryCategory.pantry,
    'turmeric': GroceryCategory.pantry,
    'ginger powder': GroceryCategory.pantry,
    'garlic powder': GroceryCategory.pantry,
    'onion powder': GroceryCategory.pantry,
    'cinnamon': GroceryCategory.pantry,
    'nutmeg': GroceryCategory.pantry,
    'allspice': GroceryCategory.pantry,
    'cloves': GroceryCategory.pantry,
    'cardamom': GroceryCategory.pantry,
    'star anise': GroceryCategory.pantry,
    'bay leaves': GroceryCategory.pantry,
    'baking powder': GroceryCategory.pantry,
    'baking soda': GroceryCategory.pantry,
    'yeast': GroceryCategory.pantry,
    'vanilla extract': GroceryCategory.pantry,
    'almond extract': GroceryCategory.pantry,

    // Sweeteners
    'sugar': GroceryCategory.pantry,
    'white sugar': GroceryCategory.pantry,
    'brown sugar': GroceryCategory.pantry,
    'powdered sugar': GroceryCategory.pantry,
    'confectioners sugar': GroceryCategory.pantry,
    'honey': GroceryCategory.pantry,
    'maple syrup': GroceryCategory.pantry,
    'agave': GroceryCategory.pantry,
    'molasses': GroceryCategory.pantry,
    'corn syrup': GroceryCategory.pantry,
    'stevia': GroceryCategory.pantry,
    'splenda': GroceryCategory.pantry,

    // Canned & Packaged
    'can': GroceryCategory.pantry,
    'canned': GroceryCategory.pantry,
    'canned tomatoes': GroceryCategory.pantry,
    'canned beans': GroceryCategory.pantry,
    'canned corn': GroceryCategory.pantry,
    'canned tuna': GroceryCategory.pantry,
    'canned soup': GroceryCategory.pantry,
    'broth': GroceryCategory.pantry,
    'chicken broth': GroceryCategory.pantry,
    'vegetable broth': GroceryCategory.pantry,
    'beef broth': GroceryCategory.pantry,
    'stock': GroceryCategory.pantry,

    // Nuts & Seeds
    'peanut': GroceryCategory.pantry,
    'peanuts': GroceryCategory.pantry,
    'almond': GroceryCategory.pantry,
    'almonds': GroceryCategory.pantry,
    'walnut': GroceryCategory.pantry,
    'walnuts': GroceryCategory.pantry,
    'cashew': GroceryCategory.pantry,
    'cashews': GroceryCategory.pantry,
    'pecan': GroceryCategory.pantry,
    'pecans': GroceryCategory.pantry,
    'pistachio': GroceryCategory.pantry,
    'pistachios': GroceryCategory.pantry,
    'macadamia': GroceryCategory.pantry,
    'hazelnut': GroceryCategory.pantry,
    'brazil nut': GroceryCategory.pantry,
    'pine nut': GroceryCategory.pantry,
    'sunflower seeds': GroceryCategory.pantry,
    'pumpkin seeds': GroceryCategory.pantry,
    'chia seeds': GroceryCategory.pantry,
    'flax seeds': GroceryCategory.pantry,
    'sesame seeds': GroceryCategory.pantry,

    // Dried Fruit
    'raisins': GroceryCategory.pantry,
    'currants': GroceryCategory.pantry,
    'dates': GroceryCategory.pantry,
    'figs': GroceryCategory.pantry,
    'apricots': GroceryCategory.pantry,
    'cranberries': GroceryCategory.pantry,
    'prunes': GroceryCategory.pantry,

    // === BEVERAGES ===
    'juice': GroceryCategory.beverages,
    'orange juice': GroceryCategory.beverages,
    'apple juice': GroceryCategory.beverages,
    'grape juice': GroceryCategory.beverages,
    'cranberry juice': GroceryCategory.beverages,
    'soda': GroceryCategory.beverages,
    'water': GroceryCategory.beverages,
    'sparkling water': GroceryCategory.beverages,
    'club soda': GroceryCategory.beverages,
    'tonic': GroceryCategory.beverages,
    'tea': GroceryCategory.beverages,
    'green tea': GroceryCategory.beverages,
    'black tea': GroceryCategory.beverages,
    'herbal tea': GroceryCategory.beverages,
    'iced tea': GroceryCategory.beverages,
    'coffee': GroceryCategory.beverages,
    'espresso': GroceryCategory.beverages,
    'cappuccino': GroceryCategory.beverages,
    'latte': GroceryCategory.beverages,
    'beer': GroceryCategory.beverages,
    'wine': GroceryCategory.beverages,
    'red wine': GroceryCategory.beverages,
    'white wine': GroceryCategory.beverages,
    'champagne': GroceryCategory.beverages,
    'liquor': GroceryCategory.beverages,
    'vodka': GroceryCategory.beverages,
    'gin': GroceryCategory.beverages,
    'rum': GroceryCategory.beverages,
    'tequila': GroceryCategory.beverages,
    'whiskey': GroceryCategory.beverages,

    // === FROZEN ===
    'frozen': GroceryCategory.frozen,
    'frozen vegetables': GroceryCategory.frozen,
    'frozen fruit': GroceryCategory.frozen,
    'frozen pizza': GroceryCategory.frozen,
    'frozen dinner': GroceryCategory.frozen,
    'frozen yogurt': GroceryCategory.frozen,
    'sorbet': GroceryCategory.frozen,
    'popsicle': GroceryCategory.frozen,
    'frozen waffles': GroceryCategory.frozen,
    'frozen pancakes': GroceryCategory.frozen,
    'frozen meat': GroceryCategory.frozen,
    'frozen chicken': GroceryCategory.frozen,
    'frozen fish': GroceryCategory.frozen,
  };

  /// Get category based on item name using comprehensive database lookup
  static GroceryCategory getCategoryForItem(String itemName) {
    final lower = itemName.toLowerCase().trim();

    // First, try exact match in database
    if (_ingredientDatabase.containsKey(lower)) {
      return _ingredientDatabase[lower]!;
    }

    // Then, try partial match - check if any database keyword is contained in the item name
    for (final entry in _ingredientDatabase.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }

    // Fallback: Check for category keywords
    // Produce
    if (lower.contains('vegetable') || lower.contains('fruit')) {
      return GroceryCategory.produce;
    }
    // Dairy
    if (lower.contains('dairy') || lower.contains('lactose')) {
      return GroceryCategory.dairy;
    }
    // Meat
    if (lower.contains('protein') || lower.contains('organ meat')) {
      return GroceryCategory.meat;
    }
    // Bakery
    if (lower.contains('gluten') || lower.contains('wheat')) {
      return GroceryCategory.bakery;
    }
    // Beverages
    if (lower.contains('drink') || lower.contains('beverage')) {
      return GroceryCategory.beverages;
    }
    // Pantry
    if (lower.contains('seasoning') || lower.contains('flavoring') || lower.contains('extract')) {
      return GroceryCategory.pantry;
    }

    return GroceryCategory.other;
  }
}
