import 'package:flutter/material.dart';

/// Ingredient Model with Nutrition Information
/// Represents a parsed ingredient from Spoonacular API
class Ingredient {
  final String id;
  final String name;
  final double amount;
  final String unit;
  final String aisle;
  final Nutrition? nutrition;

  Ingredient({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.aisle,
    this.nutrition,
  });

  /// Create Ingredient from Spoonacular API response
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: '${DateTime.now().millisecondsSinceEpoch}_${json['id'] ?? ''}',
      name: json['name'] ?? 'Unknown Ingredient',
      amount: _parseDouble(json['amount'] ?? json['quantity'] ?? 0),
      unit: json['unit'] ?? json['unitLong'] ?? json['unitShort'] ?? '',
      aisle: json['aisle'] ?? 'Other',
      nutrition: json['nutrition'] != null
          ? Nutrition.fromJson(json['nutrition'])
          : null,
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
      'aisle': aisle,
      'nutrition': nutrition?.toJson(),
    };
  }

  /// Get formatted amount string
  String get formattedAmount {
    // Remove trailing zeros for whole numbers
    if (amount == amount.truncateToDouble()) {
      return '${amount.toInt()} $unit';
    }
    return '$amount $unit';
  }

  /// Get category based on aisle
  IngredientCategory get category {
    return IngredientCategory.fromAisle(aisle);
  }

  /// Create a copy with modified fields
  Ingredient copyWith({
    String? id,
    String? name,
    double? amount,
    String? unit,
    String? aisle,
    Nutrition? nutrition,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      aisle: aisle ?? this.aisle,
      nutrition: nutrition ?? this.nutrition,
    );
  }

  @override
  String toString() {
    return 'Ingredient{name: $name, amount: $formattedAmount, aisle: $aisle}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ingredient &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Nutrition Model for ingredient nutritional information
class Nutrition {
  final List<Nutrient> nutrients;
  final double? calories;

  Nutrition({
    required this.nutrients,
    this.calories,
  });

  /// Create Nutrition from Spoonacular API response
  factory Nutrition.fromJson(Map<String, dynamic> json) {
    final nutrientsList = <Nutrient>[];
    double? calValue;

    // Parse nutrients array
    if (json['nutrients'] != null) {
      for (var nutrient in json['nutrients']) {
        final nutrientObj = Nutrient.fromJson(nutrient);
        nutrientsList.add(nutrientObj);

        // Extract calories
        if (nutrientObj.name.toLowerCase() == 'calories' ||
            nutrientObj.name.toLowerCase() == 'calorie') {
          calValue = nutrientObj.amount;
        }
      }
    }

    return Nutrition(
      nutrients: nutrientsList,
      calories: calValue,
    );
  }

  /// Get calories (fallback to calculation if not directly available)
  double get totalCalories {
    if (calories != null) return calories!;
    return 0;
  }

  /// Get formatted calories string
  String get formattedCalories {
    if (calories == null) return 'N/A';
    return '${calories!.toStringAsFixed(0)} kcal';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'nutrients': nutrients.map((n) => n.toJson()).toList(),
      'calories': calories,
    };
  }

  /// Get a specific nutrient by name
  Nutrient? getNutrient(String name) {
    try {
      return nutrients.firstWhere(
        (n) => n.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get protein content
  double? get protein => getNutrient('Protein')?.amount;

  /// Get carbohydrates content
  double? get carbohydrates => getNutrient('Carbohydrates')?.amount;

  /// Get fat content
  double? get fat => getNutrient('Fat')?.amount;
}

/// Individual Nutrient Model
class Nutrient {
  final String name;
  final double amount;
  final String unit;
  final double? percentOfDailyNeeds;

  Nutrient({
    required this.name,
    required this.amount,
    required this.unit,
    this.percentOfDailyNeeds,
  });

  /// Create Nutrient from JSON
  factory Nutrient.fromJson(Map<String, dynamic> json) {
    return Nutrient(
      name: json['name'] ?? json['title'] ?? 'Unknown',
      amount: _parseDouble(json['amount'] ?? 0),
      unit: json['unit'] ?? '',
      percentOfDailyNeeds: _parseDouble(json['percentOfDailyNeeds']),
    );
  }

  /// Parse double safely
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'percentOfDailyNeeds': percentOfDailyNeeds,
    };
  }

  /// Get formatted string
  String get formatted {
    if (amount == amount.truncateToDouble()) {
      return '${amount.toInt()} $unit';
    }
    return '${amount.toStringAsFixed(1)} $unit';
  }

  @override
  String toString() {
    return '$name: $formatted';
  }
}

/// Ingredient Category Enum
/// Categories ingredients based on their aisle
enum IngredientCategory {
  produce('🥬', 'Produce', Color(0xFF4CAF50)),
  meat('🥩', 'Meat', Color(0xFFF44336)),
  seafood('🐟', 'Seafood', Color(0xFF2196F3)),
  dairy('🥛', 'Dairy', Color(0xFF03A9F4)),
  bakery('🍞', 'Bakery', Color(0xFFFF9800)),
  frozen('❄️', 'Frozen', Color(0xFF00BCD4)),
  canned('🥫', 'Canned & Jarred', Color(0xFF795548)),
  dry('🌾', 'Dry & Baking', Color(0xFFFFC107)),
  beverages('🥤', 'Beverages', Color(0xFF9C27B0)),
  snacks('🍿', 'Snacks', Color(0xFFFFEB3B)),
  condiments('🧂', 'Condiments & Spices', Color(0xFFFF5722)),
  oils('🫒', 'Oils & Vinegars', Color(0xFFCDDC39)),
  alcohol('🍷', 'Alcoholic Beverages', Color(0xFF673AB7)),
  health('💊', 'Health', Color(0xFFE91E63)),
  other('📦', 'Other', Color(0xFF9E9E9E));

  final String emoji;
  final String label;
  final Color color;

  const IngredientCategory(this.emoji, this.label, this.color);

  /// Get category from aisle string
  static IngredientCategory fromAisle(String aisle) {
    final lowerAisle = aisle.toLowerCase();

    // Map common aisle names to categories
    if (lowerAisle.contains('produce') ||
        lowerAisle.contains('vegetable') ||
        lowerAisle.contains('fruit')) {
      return IngredientCategory.produce;
    }
    if (lowerAisle.contains('meat')) {
      return IngredientCategory.meat;
    }
    if (lowerAisle.contains('seafood') || lowerAisle.contains('fish')) {
      return IngredientCategory.seafood;
    }
    if (lowerAisle.contains('dairy') || lowerAisle.contains('cheese') || lowerAisle.contains('milk')) {
      return IngredientCategory.dairy;
    }
    if (lowerAisle.contains('bakery') || lowerAisle.contains('bread')) {
      return IngredientCategory.bakery;
    }
    if (lowerAisle.contains('frozen')) {
      return IngredientCategory.frozen;
    }
    if (lowerAisle.contains('canned') || lowerAisle.contains('jarred')) {
      return IngredientCategory.canned;
    }
    if (lowerAisle.contains('dry') ||
        lowerAisle.contains('baking') ||
        lowerAisle.contains('pasta') ||
        lowerAisle.contains('rice')) {
      return IngredientCategory.dry;
    }
    if (lowerAisle.contains('beverage') || lowerAisle.contains('drink')) {
      return IngredientCategory.beverages;
    }
    if (lowerAisle.contains('snack') || lowerAisle.contains('chip') || lowerAisle.contains('cracker')) {
      return IngredientCategory.snacks;
    }
    if (lowerAisle.contains('condiment') ||
        lowerAisle.contains('spice') ||
        lowerAisle.contains('sauce')) {
      return IngredientCategory.condiments;
    }
    if (lowerAisle.contains('oil') || lowerAisle.contains('vinegar')) {
      return IngredientCategory.oils;
    }
    if (lowerAisle.contains('alcohol') || lowerAisle.contains('beer') || lowerAisle.contains('wine')) {
      return IngredientCategory.alcohol;
    }
    if (lowerAisle.contains('health')) {
      return IngredientCategory.health;
    }

    return IngredientCategory.other;
  }

  /// Get sorted list of categories (excluding "Other" which goes last)
  static List<IngredientCategory> get sortedCategories {
    final categories = IngredientCategory.values.toList()
      ..remove(IngredientCategory.other);
    categories.sort((a, b) => a.label.compareTo(b.label));
    categories.add(IngredientCategory.other);
    return categories;
  }
}
