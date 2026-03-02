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
  produce('🥬', 'Produce', Colors.green),
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

  /// Get category based on item name (simple heuristic)
  static GroceryCategory getCategoryForItem(String itemName) {
    final lower = itemName.toLowerCase();

    if (lower.contains('vegetable') ||
        lower.contains('fruit') ||
        lower.contains('lettuce') ||
        lower.contains('tomato') ||
        lower.contains('onion') ||
        lower.contains('carrot')) {
      return GroceryCategory.produce;
    }
    if (lower.contains('milk') ||
        lower.contains('cheese') ||
        lower.contains('yogurt') ||
        lower.contains('cream')) {
      return GroceryCategory.dairy;
    }
    if (lower.contains('chicken') ||
        lower.contains('beef') ||
        lower.contains('pork') ||
        lower.contains('fish') ||
        lower.contains('meat')) {
      return GroceryCategory.meat;
    }
    if (lower.contains('bread') || lower.contains('bagel') || lower.contains('muffin')) {
      return GroceryCategory.bakery;
    }
    if (lower.contains('juice') || lower.contains('soda') || lower.contains('water')) {
      return GroceryCategory.beverages;
    }
    if (lower.contains('frozen')) {
      return GroceryCategory.frozen;
    }
    if (lower.contains('rice') ||
        lower.contains('pasta') ||
        lower.contains('oil') ||
        lower.contains('sauce') ||
        lower.contains('can')) {
      return GroceryCategory.pantry;
    }

    return GroceryCategory.other;
  }
}
