class Recipe {
  final String id;
  final String name;
  final String nameThai;
  final List<String> ingredients;
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
}

/// Recipe Database with Substitute Options
class RecipeDatabase {
  static const Map<String, List<String>> commonSubstitutes = {
    // Meat substitutes
    'chicken': ['tofu', 'paneer', 'seitan', 'mushroom'],
    'pork': ['chicken', 'tofu', 'mushroom'],
    'beef': ['mushroom', 'lentils', 'tofu'],
    'fish': ['tofu', 'chicken', 'shrimp'],
    'shrimp': ['chicken', 'tofu', 'crab', 'prawn'],

    // Dairy substitutes
    'milk': ['coconut milk', 'almond milk', 'soy milk', 'yogurt', 'cream'],
    'cheese': ['nutritional yeast', 'cashew cheese', 'tofu', 'paneer'],
    'butter': ['oil', 'coconut oil', 'ghee', 'margarine'],
    'cream': ['coconut cream', 'milk', 'yogurt'],
    'eggs': ['flax eggs', 'chia eggs', 'banana', 'applesauce'],

    // Vegetable substitutes
    'onion': ['shallot', 'leek', 'green onion', 'red onion'],
    'garlic': ['garlic powder', 'shallot', 'onion powder', 'roasted garlic'],
    'tomato': ['canned tomato', 'tomato paste', 'red bell pepper'],
    'carrot': ['parsnip', 'sweet potato', 'squash', 'turnip'],
    'broccoli': ['cauliflower', 'asparagus', 'green beans'],

    // Herb/spice substitutes
    'basil': ['oregano', 'thyme', 'parsley', 'cilantro'],
    'coriander': ['parsley', 'cilantro', 'basil'],
    'chili': ['paprika', 'cayenne', 'pepper flakes', 'chili powder'],
    'lemongrass': ['lemon zest', 'lime zest', 'ginger'],
    'galangal': ['ginger', 'galangal powder'],
  };

  static List<Recipe> getRecipes() {
    return [
      Recipe(
        id: '1',
        name: 'Fried Rice',
        nameThai: 'ข้าวผัด',
        ingredients: ['rice', 'egg', 'onion', 'garlic', 'oil', 'soy sauce', 'vegetables'],
        instructions: 'Heat oil, sauté garlic and onion. Add rice and vegetables. Add soy sauce and mix well. Serve with fried egg.',
        instructionsThai: 'ตั้งน้ำมันร้อน ผัดกระเทียมและหอมใหญ่ ใส่ข้าวและผัก ปรุงรสด้วยซอส จัดเสิร์ฟพร้อมไข่ทอด',
        cookingTime: 15,
        difficulty: 'Easy',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '2',
        name: 'Stir-fried Chicken with Basil',
        nameThai: 'ผัดกะเพราไก่',
        ingredients: ['chicken', 'basil', 'garlic', 'chili', 'soy sauce', 'oil', 'onion'],
        instructions: 'Stir-fry garlic and chili. Add chicken and cook. Add basil and season with soy sauce.',
        instructionsThai: 'ผัดกระเทียมและพริก ใส่ไก่และผัดจนสุก ใส่ใบกะเพราและปรุงรสด้วยซอส',
        cookingTime: 15,
        difficulty: 'Easy',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '3',
        name: 'Tom Yum Goong',
        nameThai: 'ต้มยำกุ้ง',
        ingredients: ['shrimp', 'mushroom', 'chili', 'lemongrass', 'lime', 'galangal', 'fish sauce'],
        instructions: 'Boil water with lemongrass and galangal. Add shrimp and mushrooms. Season with fish sauce and lime juice.',
        instructionsThai: 'ต้มน้ำกับตะไคร้และข่า ใส่กุ้งและเห็ด ปรุงรสด้วยน้ำปลาและน้ำมะนาว',
        cookingTime: 20,
        difficulty: 'Medium',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '4',
        name: 'Green Curry Chicken',
        nameThai: 'แกงเขียวหวานไก่',
        ingredients: ['chicken', 'coconut milk', 'green curry paste', 'basil', 'bamboo shoots', 'fish sauce'],
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
        id: '5',
        name: 'Omelette',
        nameThai: 'ไข่เจียว',
        ingredients: ['eggs', 'oil', 'onion', 'fish sauce', 'pepper'],
        instructions: 'Beat eggs with fish sauce. Heat oil and fry until golden.',
        instructionsThai: 'ตีไข่กับน้ำปลา ตั้งน้ำมันร้อนแล้วทอบจนเหลือง',
        cookingTime: 10,
        difficulty: 'Easy',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '6',
        name: 'Pad Thai',
        nameThai: 'ผัดไทย',
        ingredients: ['rice noodles', 'shrimp', 'tofu', 'bean sprouts', 'eggs', 'tamarind sauce', 'peanuts', 'chili'],
        instructions: 'Soak noodles. Stir-fry shrimp, tofu and egg. Add noodles and sauce. Top with peanuts and sprouts.',
        instructionsThai: 'แช่เส้น ผัดกุ้งเห็ดและไข่ ใส่เส้นและซอส โรยถั่วและถั่วงอก',
        cookingTime: 25,
        difficulty: 'Medium',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '7',
        name: 'Chicken Soup',
        nameThai: 'ซุปไก่',
        ingredients: ['chicken', 'onion', 'garlic', 'carrot', 'potato', 'pepper', 'water'],
        instructions: 'Boil chicken with garlic and onion. Add vegetables. Season with pepper.',
        instructionsThai: 'ต้มไก่กับกระเทียมและหอมใหญ่ ใส่ผัก ปรุงรสด้วยพริกไทย',
        cookingTime: 40,
        difficulty: 'Easy',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '8',
        name: 'Vegetable Stir-fry',
        nameThai: 'ผัดผักรวมมิตร',
        ingredients: ['broccoli', 'carrot', 'cabbage', 'garlic', 'oil', 'soy sauce', 'oyster sauce'],
        instructions: 'Stir-fry garlic. Add vegetables and cook. Season with soy and oyster sauce.',
        instructionsThai: 'ผัดกระเทียม ใส่ผักแล้วผัดจนสุก ปรุงรสด้วยซอสและซอสหอยนา',
        cookingTime: 15,
        difficulty: 'Easy',
        substitutes: commonSubstitutes,
      ),
      Recipe(
        id: '9',
        name: 'Spicy Salad (Som Tum)',
        nameThai: 'ส้มตำ',
        ingredients: ['papaya', 'tomato', 'garlic', 'chili', 'fish sauce', 'lime', 'peanuts'],
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
        instructions: 'Fry curry paste with coconut milk. Add chicken and vegetables. Simmer until tender.',
        instructionsThai: 'ผัดพริกแกงกับกะทิ ใส่ไก่และผัก ต้มจนนุ่ม',
        cookingTime: 45,
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
