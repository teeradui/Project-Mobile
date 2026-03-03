import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/grocery_item.dart';
import '../models/recipe.dart';
import '../providers/grocery_provider.dart';
import '../services/spoonacular_service.dart';
import '../widgets/calorie_donut_chart.dart';

/// Recipe Suggestion Screen
/// Shows recipes based on available ingredients with API integration
class RecipeSuggestionScreen extends StatefulWidget {
  final List<String> ingredients;

  const RecipeSuggestionScreen({super.key, required this.ingredients});

  @override
  State<RecipeSuggestionScreen> createState() => _RecipeSuggestionScreenState();
}

class _RecipeSuggestionScreenState extends State<RecipeSuggestionScreen> {
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // Fetch recipes from API after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecipes();
    });
  }

  Future<void> _fetchRecipes() async {
    final provider = context.read<GroceryProvider>();
    await provider.fetchRecipesFromAPI();
    if (mounted) {
      setState(() {
        _isInitialLoad = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildIngredientsHeader(context),
              Expanded(
                child: Consumer<GroceryProvider>(
                  builder: (context, provider, child) {
                    // Show loading state on initial fetch
                    if (_isInitialLoad && provider.isLoadingRecipes) {
                      return _buildLoadingState(context);
                    }

                    // Show error message if API failed (but still show fallback recipes)
                    if (provider.apiError != null) {
                      return Column(
                        children: [
                          _buildApiWarning(context, provider.apiError!),
                          Expanded(child: _buildRecipeList(provider)),
                        ],
                      );
                    }

                    // Show recipes
                    return _buildRecipeList(provider);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build API warning banner
  Widget _buildApiWarning(BuildContext context, String message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.orange.shade200,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.orange, size: 16),
            onPressed: () => context.read<GroceryProvider>().clearApiError(),
          ),
        ],
      ),
    );
  }

  /// Build recipe list
  Widget _buildRecipeList(GroceryProvider provider) {
    final recipes = provider.matchingRecipes;

    if (recipes.isEmpty) {
      return _buildNoRecipesState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: recipes.length,
      clipBehavior: Clip.none,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRecipeCard(
            context,
            recipes[index],
            widget.ingredients,
          ),
        );
      },
    );
  }

  /// Build loading state
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: Colors.orange,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Searching for recipes...',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build app header
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recipe Suggestions',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Based on your available ingredients',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build ingredients header
  Widget _buildIngredientsHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.2),
            Colors.orange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Ingredients (${widget.ingredients.length})',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.ingredients
                .map((ingredient) => Chip(
                      label: Text(
                        ingredient,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Build no recipes state
  Widget _buildNoRecipesState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No matching recipes found',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adding more ingredients',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build recipe card (handles both Recipe and SpoonacularRecipe)
  Widget _buildRecipeCard(
    BuildContext context,
    dynamic recipe,
    List<String> availableIngredients,
  ) {
    // Determine recipe type and extract data
    final isSpoonacular = recipe is SpoonacularRecipe;

    String name;
    String imageUrl;
    double matchPercentage;
    List<String> missingIngredients;
    int cookingTime;
    String difficulty;
    int? calories;
    Map<String, int>? calorieBreakdown;

    if (isSpoonacular) {
      final sr = recipe as SpoonacularRecipe;
      name = sr.title;
      imageUrl = sr.image;
      matchPercentage = sr.matchPercentage;
      missingIngredients = sr.missingIngredientNames;
      cookingTime = 30; // Not provided by basic API
      difficulty = 'Medium';

      // Estimate calories from ingredients
      calories = _estimateCalories(sr.usedIngredients, sr.missedIngredients);
      calorieBreakdown = _estimateCategoryBreakdown(sr.usedIngredients, sr.missedIngredients);
    } else {
      final r = recipe as Recipe;
      name = r.name;
      imageUrl = r.imageUrl;
      matchPercentage = r.getMatchPercentage(availableIngredients);
      missingIngredients = r.getMissingIngredients(availableIngredients);
      cookingTime = r.cookingTime;
      difficulty = r.difficulty;
      calories = r.getTotalCalories();
      calorieBreakdown = r.getCalorieBreakdown();
    }

    final isPerfectMatch = missingIngredients.isEmpty;

    Color matchColor;
    if (matchPercentage >= 75) {
      matchColor = Colors.green;
    } else if (matchPercentage >= 50) {
      matchColor = Colors.orange;
    } else {
      matchColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPerfectMatch
              ? [
                  Colors.green.withValues(alpha: 0.15),
                  Colors.green.withValues(alpha: 0.08),
                ]
              : [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPerfectMatch
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showRecipeDetail(
            context,
            recipe,
            availableIngredients,
            missingIngredients,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Recipe image if available
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.white24,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    if (imageUrl.isNotEmpty) const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: matchColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: matchColor, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${matchPercentage.toInt()}% Match',
                                      style: GoogleFonts.poppins(
                                        color: matchColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (missingIngredients.isNotEmpty) ...[
                                      const SizedBox(width: 3),
                                                                      Text(
                                                                        '(${missingIngredients.length} missing)',
                                                                        style: GoogleFonts.poppins(
                                                                          color: matchColor.withValues(alpha: 0.7),
                                                                          fontSize: 9,
                                                                          fontWeight: FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ],
                                                                ),
                                                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue, width: 1),
                                ),
                                child: Text(
                                  '$calories kcal',
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue.shade300,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Recipe metadata
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$cookingTime min',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.signal_cellular_alt,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      difficulty,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    if (isSpoonacular) ...[
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.purple.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud,
                              size: 12,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'API',
                              style: GoogleFonts.poppins(
                                color: Colors.purple.shade300,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (missingIngredients.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildMissingIngredients(missingIngredients),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build missing ingredients section
  Widget _buildMissingIngredients(List<String> missing) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Missing ${missing.length} ingredient${missing.length > 1 ? "s" : ""}',
                style: GoogleFonts.poppins(
                  color: Colors.orange.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: missing.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '• $item',
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade300,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Show recipe detail bottom sheet
  void _showRecipeDetail(
    BuildContext context,
    dynamic recipe,
    List<String> availableIngredients,
    List<String> missingIngredients,
  ) async {
    // Show loading dialog
    if (recipe is SpoonacularRecipe) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    final provider = context.read<GroceryProvider>();
    final detail = await provider.getRecipeDetail(recipe);

    // Close loading dialog
    if (recipe is SpoonacularRecipe && context.mounted) {
      Navigator.pop(context);
    }

    if (detail == null) return;

    // Show detail bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: _buildDetailContent(context, detail, missingIngredients),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build detail content widgets list
  List<Widget> _buildDetailContent(BuildContext context, Map<String, dynamic> detail, List<String> missingIngredients) {
    // Extract used ingredients
    final used = List<String>.from(detail['usedIngredients'] ?? detail['ingredients'] ?? []);

    return [
      // Recipe name
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail['title'] ?? 'Recipe',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant,
              color: Colors.orange,
              size: 28,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),

      // Recipe info
      Row(
        children: [
          _buildInfoChip(
            Icons.access_time,
            '${detail['cookingTime'] ?? 30} min',
          ),
          const SizedBox(width: 12),
          _buildInfoChip(
            Icons.signal_cellular_alt,
            detail['difficulty'] ?? 'Medium',
          ),
        ],
      ),
      const SizedBox(height: 20),

      // Calories (if available)
      if (detail['calories'] != null) ...[
        Row(
          children: [
            CalorieDonutChart(
              calorieBreakdown: detail['calorieBreakdown'] ?? {},
              totalCalories: detail['calories'] ?? 0,
              size: 80,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Calories',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${detail['calories']} kcal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (detail['calorieBreakdown'] != null)
                    const SizedBox(height: 8),
                  if (detail['calorieBreakdown'] != null)
                    CalorieLegend(breakdown: detail['calorieBreakdown']),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],

      // Ingredients section
      Text(
        'Ingredients',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 12),

      // Available ingredients
      if (used.isNotEmpty) ...[
        _buildIngredientSection(
          context,
          'Available',
          used,
          true,
        ),
        const SizedBox(height: 16),
      ],

      // Missing ingredients
      if (missingIngredients.isNotEmpty) ...[
        _buildIngredientSection(
          context,
          'Missing',
          missingIngredients,
          false,
        ),
        const SizedBox(height: 16),

        // Add all missing ingredients button
        ElevatedButton.icon(
          onPressed: () => _addMissingIngredients(context, detail),
          icon: const Icon(Icons.add_shopping_cart, size: 18),
          label: Text(
            'Add All Missing Ingredients (${missingIngredients.length})',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],

      // Instructions section
      Text(
        'Instructions',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          detail['instructions'] ?? 'No instructions available.',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
            height: 1.5,
          ),
        ),
      ),
      const SizedBox(height: 32),
    ];
  }

  /// Build ingredient section
  Widget _buildIngredientSection(
    BuildContext context,
    String title,
    List<String> items,
    bool isAvailable,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isAvailable ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$title (${items.length})',
                style: GoogleFonts.poppins(
                  color: isAvailable ? Colors.green.shade300 : Colors.red.shade300,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((ingredient) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isAvailable ? Icons.check : Icons.close,
                    color: isAvailable ? Colors.green.shade400 : Colors.red.shade400,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ingredient,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build info chip
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.orange),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Add all missing ingredients to the grocery list
  void _addMissingIngredients(BuildContext context, Map<String, dynamic> detail) {
    final provider = context.read<GroceryProvider>();
    final missingIngredients = List<String>.from(detail['missedIngredients'] ?? []);

    if (missingIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No missing ingredients to add',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    // Add each missing ingredient to the list
    int addedCount = 0;
    for (final ingredient in missingIngredients) {
      // Create a new grocery item with default amount
      final newItem = GroceryItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_$addedCount',
        name: ingredient,
        amount: 1,
        unit: 'pcs',
      );

      // Check if it already exists
      final existing = provider.items.any((item) =>
        item.name.toLowerCase() == ingredient.toLowerCase() &&
        !item.isPurchased
      );

      if (!existing) {
        provider.addItemManually(newItem);
        addedCount++;
      }
    }

    // Show success message
    if (addedCount > 0 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added $addedCount ingredient${addedCount > 1 ? 's' : ''} to your list!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Close the bottom sheet after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          Navigator.pop(context);
        }
      });
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All ingredients already in your list',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Estimate calories for Spoonacular recipe
  int _estimateCalories(
    List<dynamic> usedIngredients,
    List<dynamic> missedIngredients,
  ) {
    int total = 0;

    // Simple calorie database (per 100g)
    final calorieMap = {
      'chicken': 165, 'beef': 250, 'pork': 242, 'fish': 140, 'shrimp': 99,
      'salmon': 208, 'tuna': 130, 'crab': 97, 'bacon': 541, 'ham': 145,
      'egg': 155,
      'milk': 42, 'cheese': 402, 'butter': 717, 'cream': 340, 'yogurt': 59,
      'tomato': 18, 'onion': 40, 'garlic': 149, 'carrot': 41, 'potato': 77,
      'broccoli': 34, 'lettuce': 15, 'spinach': 23, 'mushroom': 22,
      'rice': 130, 'pasta': 131, 'bread': 265, 'flour': 364,
      'apple': 52, 'banana': 89, 'orange': 47,
      'oil': 884, 'sugar': 387,
    };

    // Estimate for all ingredients (assume 100g each for simplicity)
    for (var ing in [...usedIngredients, ...missedIngredients]) {
      final name = ing.toString().toLowerCase();
      int kcalPer100g = 100;

      for (var entry in calorieMap.entries) {
        if (name.contains(entry.key)) {
          kcalPer100g = entry.value;
          break;
        }
      }

      total += kcalPer100g; // Assume 100g per ingredient
    }

    return total;
  }

  /// Estimate category breakdown for Spoonacular recipe
  Map<String, int> _estimateCategoryBreakdown(
    List<dynamic> usedIngredients,
    List<dynamic> missedIngredients,
  ) {
    final breakdown = <String, int>{
      'Protein': 0,
      'Carbs': 0,
      'Vegetables': 0,
      'Dairy': 0,
      'Others': 0,
    };

    // Simple calorie database (per 100g)
    final calorieMap = {
      'chicken': 165, 'beef': 250, 'pork': 242, 'fish': 140, 'shrimp': 99,
      'salmon': 208, 'tuna': 130, 'crab': 97, 'bacon': 541, 'ham': 145,
      'egg': 155,
      'milk': 42, 'cheese': 402, 'butter': 717, 'cream': 340, 'yogurt': 59,
      'tomato': 18, 'onion': 40, 'garlic': 149, 'carrot': 41, 'potato': 77,
      'broccoli': 34, 'lettuce': 15, 'spinach': 23, 'mushroom': 22,
      'rice': 130, 'pasta': 131, 'bread': 265, 'flour': 364,
      'apple': 52, 'banana': 89, 'orange': 47,
      'oil': 884, 'sugar': 387,
    };

    // Process all ingredients
    for (var ing in [...usedIngredients, ...missedIngredients]) {
      final name = ing is String ? ing as String : ing.toString().toLowerCase();
      int kcalPer100g = 100;

      for (var entry in calorieMap.entries) {
        if (name.contains(entry.key)) {
          kcalPer100g = entry.value;
          break;
        }
      }

      final category = _getCategoryForIngredient(name);
      breakdown[category] = (breakdown[category] ?? 0) + kcalPer100g;
    }

    // Remove categories with zero calories
    breakdown.removeWhere((key, value) => value == 0);

    return breakdown;
  }

  /// Get category for an ingredient
  String _getCategoryForIngredient(String ingredientName) {
    final lower = ingredientName.toLowerCase();

    if (lower.contains('chicken') || lower.contains('beef') || lower.contains('pork') ||
        lower.contains('fish') || lower.contains('shrimp') || lower.contains('crab') ||
        lower.contains('salmon') || lower.contains('tuna') || lower.contains('bacon') ||
        lower.contains('ham') || lower.contains('egg')) {
      return 'Protein';
    }

    if (lower.contains('rice') || lower.contains('pasta') || lower.contains('noodle') ||
        lower.contains('bread') || lower.contains('flour') || lower.contains('potato') ||
        lower.contains('corn')) {
      return 'Carbs';
    }

    if (lower.contains('tomato') || lower.contains('onion') || lower.contains('garlic') ||
        lower.contains('carrot') || lower.contains('broccoli') || lower.contains('cabbage') ||
        lower.contains('lettuce') || lower.contains('spinach') || lower.contains('mushroom')) {
      return 'Vegetables';
    }

    if (lower.contains('milk') || lower.contains('cheese') || lower.contains('butter') ||
        lower.contains('cream') || lower.contains('yogurt')) {
      return 'Dairy';
    }

    return 'Others';
  }
}
