/// Recipe Model with Calorie Information and Bilingual Support
/// Enhanced with ingredient quantities, calorie calculation, and Thai language support

/// Ingredient Calorie Data
class IngredientCalorie {
  final String name;
  final int kcalPer100g;

  const IngredientCalorie({
    required this.name,
    required this.kcalPer100g,
  });
}

/// Calorie Database for Ingredients
/// Contains calorie information per 100g for common ingredients
class CalorieDatabase {
  static const Map<String, int> caloriesPer100g = {
    // Proteins (per 100g)
    'chicken': 165,
    'chicken breast': 120,
    'pork': 242,
    'beef': 250,
    'fish': 140,
    'shrimp': 99,
    'crab': 97,
    'prawn': 99,
    'egg': 155,
    'eggs': 155,
    'tofu': 76,
    'paneer': 265,
    'bacon': 541,
    'ham': 145,
    'sausage': 320,
    'meatball': 250,

    // Dairy (per 100g)
    'milk': 42,
    'cheese': 402,
    'butter': 717,
    'cream': 340,
    'yogurt': 59,
    'coconut milk': 197,
    'coconut cream': 330,
    'condensed milk': 321,

    // Grains & Starch (per 100g)
    'rice': 130,
    'rice noodles': 110,
    'pasta': 131,
    'bread': 265,
    'flour': 364,
    'oats': 389,
    'noodle': 138,

    // Vegetables (per 100g)
    'onion': 40,
    'garlic': 149,
    'tomato': 18,
    'carrot': 41,
    'potato': 77,
    'broccoli': 34,
    'cabbage': 25,
    'lettuce': 15,
    'spinach': 23,
    'mushroom': 22,
    'beans': 347,
    'bamboo shoots': 27,
    'baby corn': 26,
    'green beans': 31,
    'asparagus': 20,
    'bell pepper': 31,
    'zucchini': 17,
    'corn': 86,
    'papaya': 43,
    'green mango': 60,

    // Fruits (per 100g)
    'apple': 52,
    'banana': 89,
    'orange': 47,
    'lemon': 29,
    'lime': 30,
    'tamarind': 239,

    // Condiments (per 100g)
    'oil': 884,
    'olive oil': 884,
    'soy sauce': 60,
    'fish sauce': 50,
    'oyster sauce': 70,
    'tamarind sauce': 150,
    'sugar': 387,
    'pepper': 255,
    'salt': 0,
    'ketchup': 112,
    'mustard': 66,
    'curry paste': 200,
    'massaman curry paste': 220,
    'green curry paste': 180,

    // Nuts & Seeds (per 100g)
    'peanuts': 567,
    'cashew': 553,
    'almond': 579,
    'walnut': 654,

    // Herbs (per 100g)
    'basil': 23,
    'parsley': 36,
    'cilantro': 23,
    'lemongrass': 99,
    'galangal': 70,
    'chili': 40,
    'paprika': 282,

    // Others (per 100g)
    'water': 0,
    'vegetables': 25,
  };

  /// Get calories for an ingredient
  static int getCalories(String ingredientName) {
    final lower = ingredientName.toLowerCase();

    for (var entry in caloriesPer100g.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }

    return 50; // Default calories for unknown ingredients
  }

  /// Estimate calories with default serving size
  static int estimateCalories(String ingredientName, double amount, String unit) {
    final kcalPer100g = getCalories(ingredientName);

    // Convert to grams
    double grams = _toGrams(amount, unit);

    return ((kcalPer100g * grams) / 100).round();
  }

  /// Convert various units to grams
  static double _toGrams(double amount, String unit) {
    final lower = unit.toLowerCase();

    if (lower.contains('kg') || lower.contains('kilogram')) {
      return amount * 1000;
    } else if (lower.contains('g') || lower.contains('gram')) {
      return amount;
    } else if (lower.contains('lb') || lower.contains('pound')) {
      return amount * 453.592;
    } else if (lower.contains('oz') || lower.contains('ounce')) {
      return amount * 28.3495;
    } else if (lower.contains('cup')) {
      return amount * 240; // Approximate for dry ingredients
    } else if (lower.contains('tbsp') || lower.contains('tablespoon')) {
      return amount * 15;
    } else if (lower.contains('tsp') || lower.contains('teaspoon')) {
      return amount * 5;
    } else if (lower.contains('ml') || lower.contains('milliliter')) {
      return amount; // Approximate for liquids
    } else if (lower.contains('liter') || lower.contains('l')) {
      return amount * 1000;
    }

    // Default for pieces, heads, etc.
    return amount * 100; // Assume 100g per piece
  }
}

/// Recipe Class with Calorie Information and Bilingual Support
class Recipe {
  final String id;
  final String name;
  final String nameThai;
  final List<String> ingredients;
  final List<Map<String, dynamic>> ingredientQuantities; // [{"name": "chicken", "amount": 200, "unit": "g"}]
  final String instructions;
  final String instructionsThai;
  final int cookingTime;
  final String difficulty;
  final String imageUrl;
  final Map<String, List<String>> substitutes; // ingredient -> [substitutes]

  Recipe({
    required this.id,
    required this.name,
    required this.nameThai,
    required this.ingredients,
    required this.ingredientQuantities,
    required this.instructions,
    required this.instructionsThai,
    required this.cookingTime,
    required this.difficulty,
    this.imageUrl = '',
    this.substitutes = const {},
  });

  /// Calculate match percentage based on available ingredients
  double getMatchPercentage(List<String> availableIngredients) {
    if (ingredients.isEmpty) return 0;

    int matchedCount = 0;
    for (String ingredient in ingredients) {
      for (String available in availableIngredients) {
        if (_ingredientMatches(ingredient, available)) {
          matchedCount++;
          break;
        }
      }
    }

    return (matchedCount / ingredients.length) * 100;
  }

  /// Check if ingredients match (including substitutes)
  bool _ingredientMatches(String required, String available) {
    // Direct match
    if (required.toLowerCase().contains(available.toLowerCase()) ||
        available.toLowerCase().contains(required.toLowerCase())) {
      return true;
    }

    // Check if available is a substitute for required
    if (substitutes.containsKey(required.toLowerCase())) {
      for (String substitute in substitutes[required.toLowerCase()]!) {
        if (available.toLowerCase().contains(substitute.toLowerCase()) ||
            substitute.toLowerCase().contains(available.toLowerCase())) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get missing ingredients
  List<String> getMissingIngredients(List<String> availableIngredients) {
    List<String> missing = [];
    for (String ingredient in ingredients) {
      bool found = false;
      for (String available in availableIngredients) {
        if (_ingredientMatches(ingredient, available)) {
          found = true;
          break;
        }
      }
      if (!found) {
        missing.add(ingredient);
      }
    }
    return missing;
  }

  /// Get available substitutes for missing ingredients
  Map<String, List<String>> getAvailableSubstitutes(List<String> availableIngredients) {
    Map<String, List<String>> availableSubs = {};
    List<String> missing = getMissingIngredients(availableIngredients);

    for (String missingItem in missing) {
      String missingLower = missingItem.toLowerCase();

      // Check if this missing item has substitutes
      for (var entry in substitutes.entries) {
        if (missingLower.contains(entry.key) || entry.key.contains(missingLower)) {
          // Check which substitutes are available
          List<String> found = [];
          for (String sub in entry.value) {
            for (String available in availableIngredients) {
              if (available.toLowerCase().contains(sub.toLowerCase()) ||
                  sub.toLowerCase().contains(available.toLowerCase())) {
                found.add(sub);
                break;
              }
            }
          }
          if (found.isNotEmpty) {
            availableSubs[missingItem] = found;
          }
        }
      }
    }

    return availableSubs;
  }

  /// Calculate total calories for this recipe
  int getTotalCalories() {
    int total = 0;

    for (var item in ingredientQuantities) {
      final name = item['name'] as String;
      final amount = (item['amount'] as num).toDouble();
      final unit = item['unit'] as String;

      total += CalorieDatabase.estimateCalories(name, amount, unit);
    }

    // Add base calories for oil and seasonings (approximately)
    total += 100; // ~100 kcal for oil and seasonings

    return total;
  }

  /// Get calorie breakdown by ingredient category
  Map<String, int> getCalorieBreakdown() {
    Map<String, int> breakdown = {
      'Protein': 0,
      'Carbs': 0,
      'Vegetables': 0,
      'Dairy': 0,
      'Others': 0,
    };

    for (var item in ingredientQuantities) {
      final name = item['name'] as String;
      final amount = (item['amount'] as num).toDouble();
      final unit = item['unit'] as String;

      final calories = CalorieDatabase.estimateCalories(name, amount, unit);
      final category = _getIngredientCategory(name);

      breakdown[category] = (breakdown[category] ?? 0) + calories;
    }

    return breakdown;
  }

  String _getIngredientCategory(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('chicken') || lower.contains('pork') || lower.contains('beef') ||
        lower.contains('fish') || lower.contains('shrimp') || lower.contains('prawn') ||
        lower.contains('crab') || lower.contains('egg') || lower.contains('tofu') ||
        lower.contains('bacon') || lower.contains('ham') || lower.contains('sausage')) {
      return 'Protein';
    }

    if (lower.contains('rice') || lower.contains('noodle') || lower.contains('bread') ||
        lower.contains('pasta') || lower.contains('potato') || lower.contains('flour') ||
        lower.contains('oats') || lower.contains('corn')) {
      return 'Carbs';
    }

    if (lower.contains('onion') || lower.contains('garlic') || lower.contains('tomato') ||
        lower.contains('carrot') || lower.contains('broccoli') || lower.contains('cabbage') ||
        lower.contains('beans') || lower.contains('vegetable') || lower.contains('pepper') ||
        lower.contains('zucchini') || lower.contains('spinach') || lower.contains('lettuce') ||
        lower.contains('asparagus') || lower.contains('mushroom') || lower.contains('papaya') ||
        lower.contains('mango') || lower.contains('bamboo')) {
      return 'Vegetables';
    }

    if (lower.contains('milk') || lower.contains('cheese') || lower.contains('butter') ||
        lower.contains('cream') || lower.contains('yogurt') || lower.contains('coconut')) {
      return 'Dairy';
    }

    return 'Others';
  }
}

/// Recipe Database with Complete Data
class RecipeDatabase {
  static const Map<String, List<String>> commonSubstitutes = {
    // Meat substitutes
    'chicken': ['tofu', 'paneer', 'seitan', 'mushroom'],
    'pork': ['chicken', 'tofu', 'mushroom'],
    'beef': ['mushroom', 'lentils', 'tofu'],
    'fish': ['tofu', 'chicken', 'shrimp', 'prawn'],
    'shrimp': ['chicken', 'tofu', 'crab', 'prawn'],
    'prawn': ['chicken', 'tofu', 'crab', 'shrimp'],

    // Dairy substitutes
    'milk': ['coconut milk', 'almond milk', 'soy milk', 'yogurt', 'cream'],
    'cheese': ['nutritional yeast', 'cashew cheese', 'tofu', 'paneer'],
    'butter': ['oil', 'coconut oil', 'ghee', 'margarine'],
    'cream': ['coconut cream', 'milk', 'yogurt'],
    'coconut milk': ['milk', 'cream', 'almond milk'],
    'eggs': ['flax eggs', 'chia eggs', 'banana', 'applesauce'],

    // Vegetable substitutes
    'onion': ['shallot', 'leek', 'green onion', 'red onion'],
    'garlic': ['garlic powder', 'shallot', 'onion powder', 'roasted garlic'],
    'tomato': ['canned tomato', 'tomato paste', 'red bell pepper'],
    'carrot': ['parsnip', 'sweet potato', 'squash', 'turnip'],
    'broccoli': ['cauliflower', 'asparagus', 'green beans'],
    'papaya': ['green mango', 'green apple', 'cucumber'],
    'bamboo shoots': ['green beans', 'asparagus', 'baby corn'],

    // Herb/spice substitutes
    'basil': ['oregano', 'thyme', 'parsley', 'cilantro'],
    'coriander': ['parsley', 'cilantro', 'basil'],
    'chili': ['paprika', 'cayenne', 'pepper flakes', 'chili powder'],
    'lemongrass': ['lemon zest', 'lime zest', 'ginger'],
    'galangal': ['ginger', 'galangal powder'],
  };

  static List<Recipe> getRecipes() {
    return [
      // Easy Recipes
      Recipe(
        id: '1',
        name: 'Fried Rice',
        nameThai: 'ข้าวผัด',
        ingredients: ['rice', 'eggs', 'onion', 'garlic', 'oil', 'soy sauce', 'vegetables'],
        ingredientQuantities: [
          {'name': 'rice', 'amount': 300, 'unit': 'g'},
          {'name': 'eggs', 'amount': 2, 'unit': 'pcs'},
          {'name': 'onion', 'amount': 50, 'unit': 'g'},
          {'name': 'garlic', 'amount': 10, 'unit': 'g'},
          {'name': 'oil', 'amount': 2, 'unit': 'tbsp'},
          {'name': 'vegetables', 'amount': 100, 'unit': 'g'},
        ],
        instructions: 'Heat oil in a wok over high heat. Sauté garlic and onion until fragrant. Add cooked rice and stir-fry for 2-3 minutes. Add vegetables and cook until tender. Push rice to the side, scramble eggs, then mix together. Season with soy sauce. Serve hot.',
        instructionsThai: 'ตั้งน้ำมันร้อน ผัดกระเทียมและหอมใหญ่จนหอม ใส่ข้าวและผัด 2-3 นาที ใส่ผักและผัดจนสุก ผลักข้าวออกข้างๆ ตีไข่แล้วคลุกเข้าด้วยกัน ปรุงรสด้วยซอส จัดเสิร์ฟร้อน',
        cookingTime: 15,
        difficulty: 'Easy',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '2',
        name: 'Stir-fried Chicken with Basil',
        nameThai: 'ผัดกะเพราไก่',
        ingredients: ['chicken', 'basil', 'garlic', 'chili', 'soy sauce', 'oil', 'onion'],
        ingredientQuantities: [
          {'name': 'chicken', 'amount': 200, 'unit': 'g'},
          {'name': 'garlic', 'amount': 10, 'unit': 'g'},
          {'name': 'chili', 'amount': 3, 'unit': 'pcs'},
          {'name': 'oil', 'amount': 2, 'unit': 'tbsp'},
          {'name': 'onion', 'amount': 30, 'unit': 'g'},
          {'name': 'basil', 'amount': 10, 'unit': 'g'},
        ],
        instructions: 'Heat oil in a wok. Stir-fry garlic and chili until fragrant. Add chicken and cook until no longer pink. Add basil leaves and soy sauce. Stir until basil is wilted. Serve over rice.',
        instructionsThai: 'ตั้งน้ำมันร้อน ผัดกระเทียมและพริกจนหอม ใส่ไก่และผัดจนสุก ใส่ใบกะเพราและซอส ผัดจนใบกะเพราโดย จัดเสิร์ฟกับข้าวสวย',
        cookingTime: 15,
        difficulty: 'Easy',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '3',
        name: 'Omelette',
        nameThai: 'ไข่เจียว',
        ingredients: ['eggs', 'oil', 'onion', 'fish sauce', 'pepper'],
        ingredientQuantities: [
          {'name': 'eggs', 'amount': 3, 'unit': 'pcs'},
          {'name': 'oil', 'amount': 2, 'unit': 'tbsp'},
          {'name': 'onion', 'amount': 30, 'unit': 'g'},
        ],
        instructions: 'Beat eggs with fish sauce and pepper. Heat oil in a pan over medium heat. Sauté onion until soft. Pour in eggs and cook until set. Fold and serve hot.',
        instructionsThai: 'ตีไข่กับน้ำปลาและพริกไทย ตั้งน้ำมันร้อน ผัดหอมใหญ่จนนุ่ม เทไข่ลงไปและทอบจนสุก พับและจัดเสิร์ฟร้อน',
        cookingTime: 10,
        difficulty: 'Easy',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '4',
        name: 'Vegetable Stir-fry',
        nameThai: 'ผัดผักรวมมิตร',
        ingredients: ['broccoli', 'carrot', 'cabbage', 'garlic', 'oil', 'soy sauce', 'oyster sauce'],
        ingredientQuantities: [
          {'name': 'broccoli', 'amount': 150, 'unit': 'g'},
          {'name': 'carrot', 'amount': 100, 'unit': 'g'},
          {'name': 'cabbage', 'amount': 100, 'unit': 'g'},
          {'name': 'garlic', 'amount': 10, 'unit': 'g'},
          {'name': 'oil', 'amount': 2, 'unit': 'tbsp'},
        ],
        instructions: 'Heat oil in a wok. Stir-fry garlic until fragrant. Add vegetables and stir-fry for 3-4 minutes. Season with soy sauce and oyster sauce. Serve hot.',
        instructionsThai: 'ตั้งน้ำมันร้อน ผัดกระเทียมจนหอม ใส่ผักและผัด 3-4 นาที ปรุงรสด้วยซอสและซอสหอยนางรม จัดเสิร์ฟร้อน',
        cookingTime: 15,
        difficulty: 'Easy',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '5',
        name: 'Tom Yum Goong',
        nameThai: 'ต้มยำกุ้ง',
        ingredients: ['shrimp', 'mushroom', 'chili', 'lemongrass', 'lime', 'galangal', 'fish sauce'],
        ingredientQuantities: [
          {'name': 'shrimp', 'amount': 200, 'unit': 'g'},
          {'name': 'mushroom', 'amount': 100, 'unit': 'g'},
          {'name': 'chili', 'amount': 3, 'unit': 'pcs'},
          {'name': 'lemongrass', 'amount': 2, 'unit': 'stalk'},
          {'name': 'lime', 'amount': 2, 'unit': 'pcs'},
        ],
        instructions: 'Boil water with lemongrass and galangal. Add shrimp and mushrooms. Season with fish sauce and lime juice. Serve hot.',
        instructionsThai: 'ต้มน้ำกับตะไคร้และข่า ใส่กุ้งและเห็ด ปรุงรสด้วยน้ำปลาและน้ำมะนาว จัดเสิร์ฟร้อน',
        cookingTime: 20,
        difficulty: 'Medium',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '6',
        name: 'Green Curry Chicken',
        nameThai: 'แกงเขียวหวานไก่',
        ingredients: ['chicken', 'coconut milk', 'green curry paste', 'basil', 'bamboo shoots', 'fish sauce'],
        ingredientQuantities: [
          {'name': 'chicken', 'amount': 300, 'unit': 'g'},
          {'name': 'coconut milk', 'amount': 300, 'unit': 'ml'},
          {'name': 'green curry paste', 'amount': 2, 'unit': 'tbsp'},
          {'name': 'bamboo shoots', 'amount': 100, 'unit': 'g'},
          {'name': 'basil', 'amount': 10, 'unit': 'g'},
        ],
        instructions: 'Fry curry paste with coconut milk. Add chicken and cook. Season with fish sauce. Add basil leaves.',
        instructionsThai: 'ผัดพริกแกงกับกะทิ ใส่ไก่และต้ม ปรุงรสด้วยน้ำปลา ใส่ใบโหระพา',
        cookingTime: 30,
        difficulty: 'Medium',
        substitutes: {
          ...commonSubstitutes,
          'bamboo shoots': ['green beans', 'asparagus', 'baby corn'],
        },
      ),
      Recipe(
        id: '7',
        name: 'Pad Thai',
        nameThai: 'ผัดไทย',
        ingredients: ['rice noodles', 'shrimp', 'tofu', 'bean sprouts', 'eggs', 'tamarind sauce', 'peanuts', 'chili'],
        ingredientQuantities: [
          {'name': 'rice noodles', 'amount': 200, 'unit': 'g'},
          {'name': 'shrimp', 'amount': 100, 'unit': 'g'},
          {'name': 'tofu', 'amount': 100, 'unit': 'g'},
          {'name': 'eggs', 'amount': 2, 'unit': 'pcs'},
          {'name': 'peanuts', 'amount': 20, 'unit': 'g'},
        ],
        instructions: 'Soak rice noodles in warm water for 30 minutes. Heat oil in a wok. Stir-fry shrimp and tofu until cooked. Push aside and scramble eggs. Add noodles and tamarind sauce. Toss until combined. Add bean sprouts and cook for 1 minute. Serve topped with crushed peanuts and chili flakes.',
        instructionsThai: 'แช่เส้นข้าวในน้ำอุ่น 30 นาที ตั้งน้ำมันร้อน ผัดกุ้งและเห็ดทองจนสุก ผลักข้างๆ แล้วตีไข่ ใส่เส้นและซอสมะขาว คลุกเข้าด้วยกัน ใส่ถั่วงอกและผัด 1 นาที โรยถั่วและพริกบุบ',
        cookingTime: 25,
        difficulty: 'Medium',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '8',
        name: 'Chicken Soup',
        nameThai: 'ซุปไก่',
        ingredients: ['chicken', 'onion', 'garlic', 'carrot', 'potato', 'pepper', 'water'],
        ingredientQuantities: [
          {'name': 'chicken', 'amount': 300, 'unit': 'g'},
          {'name': 'onion', 'amount': 50, 'unit': 'g'},
          {'name': 'garlic', 'amount': 10, 'unit': 'g'},
          {'name': 'carrot', 'amount': 100, 'unit': 'g'},
          {'name': 'potato', 'amount': 100, 'unit': 'g'},
        ],
        instructions: 'Place chicken in a pot with water. Bring to boil, skim foam. Add garlic, onion, carrot, and potato. Simmer for 30 minutes until chicken and vegetables are tender. Season with salt and pepper. Serve hot.',
        instructionsThai: 'ใส่ไก่ลงในหม้อกับน้ำ ต้มจนเดือด ตักฟองออก ใส่กระเทียม หอมใหญ่ แครอท และมันฝรั่ง ต้ม 30 นาทีจนนุ่ม ปรุงรสด้วยเกลือและพริกไทย จัดเสิร์ฟร้อน',
        cookingTime: 40,
        difficulty: 'Easy',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '9',
        name: 'Spicy Salad (Som Tum)',
        nameThai: 'ส้มตำ',
        ingredients: ['papaya', 'tomato', 'garlic', 'chili', 'fish sauce', 'lime', 'peanuts'],
        ingredientQuantities: [
          {'name': 'papaya', 'amount': 200, 'unit': 'g'},
          {'name': 'tomato', 'amount': 50, 'unit': 'g'},
          {'name': 'garlic', 'amount': 10, 'unit': 'g'},
          {'name': 'chili', 'amount': 3, 'unit': 'pcs'},
          {'name': 'peanuts', 'amount': 20, 'unit': 'g'},
        ],
        instructions: 'Pound garlic and chili. Add papaya and pound. Mix with seasoning and topped with peanuts.',
        instructionsThai: 'โขลกระเทียมและพริก ใส่มะละกอแล้วโขลก ผสมเครื่องเคียงและโรยถั่ว',
        cookingTime: 15,
        difficulty: 'Easy',
        substitutes: {
          ...commonSubstitutes,
          'papaya': ['green mango', 'green apple', 'cucumber'],
        },
      ),
      Recipe(
        id: '10',
        name: 'Massaman Curry',
        nameThai: 'แกงมัสมัน',
        ingredients: ['chicken', 'potato', 'onion', 'coconut milk', 'massaman curry paste', 'peanuts'],
        ingredientQuantities: [
          {'name': 'chicken', 'amount': 300, 'unit': 'g'},
          {'name': 'potato', 'amount': 200, 'unit': 'g'},
          {'name': 'onion', 'amount': 50, 'unit': 'g'},
          {'name': 'coconut milk', 'amount': 300, 'unit': 'ml'},
          {'name': 'massaman curry paste', 'amount': 2, 'unit': 'tbsp'},
          {'name': 'peanuts', 'amount': 20, 'unit': 'g'},
        ],
        instructions: 'Fry curry paste with coconut milk. Add chicken and vegetables. Simmer until tender.',
        instructionsThai: 'ผัดพริกแกงกับกะทิ ใส่ไก่และผัก ต้มจนนุ่ม',
        cookingTime: 45,
        difficulty: 'Medium',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '11',
        name: 'Grilled Cheese Sandwich',
        nameThai: 'แซนวิชชีสย่าง',
        ingredients: ['bread', 'cheese', 'butter'],
        ingredientQuantities: [
          {'name': 'bread', 'amount': 2, 'unit': 'slices'},
          {'name': 'cheese', 'amount': 50, 'unit': 'g'},
          {'name': 'butter', 'amount': 10, 'unit': 'g'},
        ],
        instructions: 'Butter one side of each bread slice. Place cheese between bread slices, butter side out. Grill in a pan over medium heat until golden brown on both sides and cheese is melted. Cut in half and serve.',
        instructionsThai: 'ทาเนยข้างนึงของแต่ละแผ่นขนมปัง วางชีสระหว่างขนมปัง ด้านทาเนยออกด้านนอก ย่างบนกระทะไฟปานกลางจนเหลืองกรอบทั้งสองด้านและชีสละลาย ตัดครึ่งและจัดเสิร์ฟ',
        cookingTime: 10,
        difficulty: 'Easy',
        substitutes: {
          ...commonSubstitutes,
          'cheese': ['cheddar', 'mozzarella', 'swiss'],
        },
      ),
      Recipe(
        id: '12',
        name: 'Spaghetti Bolognese',
        nameThai: 'สปาเก็ตตีโบโลเนส',
        ingredients: ['pasta', 'beef', 'tomato', 'onion', 'garlic', 'oil', 'cheese'],
        ingredientQuantities: [
          {'name': 'pasta', 'amount': 200, 'unit': 'g'},
          {'name': 'beef', 'amount': 200, 'unit': 'g'},
          {'name': 'tomato', 'amount': 200, 'unit': 'g'},
          {'name': 'onion', 'amount': 50, 'unit': 'g'},
          {'name': 'garlic', 'amount': 10, 'unit': 'g'},
          {'name': 'oil', 'amount': 2, 'unit': 'tbsp'},
        ],
        instructions: 'Cook pasta according to package directions. Heat oil in a pan, sauté garlic and onion. Add beef and cook until browned. Add chopped tomatoes and simmer for 15 minutes. Season with salt and pepper. Serve sauce over pasta, topped with cheese.',
        instructionsThai: 'ตุ๋นพาสตาตามคำแนะนำบนบรรจุภัณฑ์ ตั้งน้ำมันร้อน ผัดกระเทียมและหอมใหญ่ ใส่เนื้อและผัดจนเป็นสีน้ำตาล ใส่มะเขือเทศหั่นและต้ม 15 นาที ปรุงรสด้วยเกลือและพริกไทย จัดเสิร์ฟซอสบนพาสตา โรยชีส',
        cookingTime: 30,
        difficulty: 'Medium',
        substitutes: commonSubstitutes,
      ),
    ];
  }

  /// Get recipes that match available ingredients
  static List<Recipe> getMatchingRecipes(List<String> availableIngredients, {int minMatchPercentage = 30}) {
    List<Recipe> allRecipes = getRecipes();
    List<Recipe> matchingRecipes = [];

    for (Recipe recipe in allRecipes) {
      double matchPercentage = recipe.getMatchPercentage(availableIngredients);
      if (matchPercentage >= minMatchPercentage) {
        matchingRecipes.add(recipe);
      }
    }

    // Sort by match percentage (highest first)
    matchingRecipes.sort((a, b) =>
      b.getMatchPercentage(availableIngredients).compareTo(
        a.getMatchPercentage(availableIngredients)
      )
    );

    return matchingRecipes;
  }
}
