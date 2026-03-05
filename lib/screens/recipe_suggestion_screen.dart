import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';
import '../widgets/calorie_donut_chart.dart';

/// Recipe Suggestion Screen
/// Shows recipes based on available ingredients with API integration
class RecipeSuggestionScreen extends StatefulWidget {
  final List<String> ingredients;
  final bool shouldFetchOnLoad;

  const RecipeSuggestionScreen({
    super.key,
    required this.ingredients,
    this.shouldFetchOnLoad = true,
  });

  @override
  State<RecipeSuggestionScreen> createState() => _RecipeSuggestionScreenState();
}

class _RecipeSuggestionScreenState extends State<RecipeSuggestionScreen> {
  bool _isInitialLoad = true;
  static const Color _forestGreen = Color(0xFF0F5741);
  static const Color _primaryAmber = Color(0xFFFFBF00);
  static const Color _cream = Color(0xFFF5EFDF);
  static const Color _warmCream = Color(0xFFEDE4CF);

  @override
  void initState() {
    super.initState();
    // Fetch recipes from API after frame is rendered (only if shouldFetchOnLoad is true)
    if (widget.shouldFetchOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchRecipes();
      });
    }
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_cream, _warmCream],
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
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primaryAmber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryAmber.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: _forestGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: _forestGreen.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: _forestGreen, size: 16),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      itemCount: recipes.length,
      clipBehavior: Clip.hardEdge,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRecipeCard(context, recipes[index], widget.ingredients),
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
              color: _forestGreen,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Searching for recipes...',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _forestGreen.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build app header
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryAmber, _primaryAmber.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Menu',
                  style: GoogleFonts.poppins(
                    color: _forestGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Recipe suggestions based on your ingredients',
                  style: GoogleFonts.poppins(
                    color: _forestGreen.withValues(alpha: 0.65),
                    fontSize: 13,
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
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _forestGreen.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primaryAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: _forestGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Ingredients',
                      style: GoogleFonts.poppins(
                        color: _forestGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Items ready for cooking',
                      style: GoogleFonts.poppins(
                        color: _forestGreen.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primaryAmber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _primaryAmber.withValues(alpha: 0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${widget.ingredients.length}',
                    style: GoogleFonts.poppins(
                      color: _forestGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _warmCream.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _forestGreen.withValues(alpha: 0.08)),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.ingredients
                  .map(
                    (ingredient) => Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        ingredient,
                        style: GoogleFonts.poppins(
                          color: _forestGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: _primaryAmber.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _primaryAmber.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
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
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _forestGreen.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.restaurant_outlined,
              size: 44,
              color: _forestGreen.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No matching recipes found',
            style: GoogleFonts.poppins(
              color: _forestGreen,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No matching recipes yet. Try adding more ingredients.',
            style: GoogleFonts.poppins(
              color: _forestGreen.withValues(alpha: 0.55),
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
    final isSpoonacular = recipe.runtimeType.toString().contains('Spoonacular');

    String name;
    String imageUrl;
    double matchPercentage;
    List<String> missingIngredients;
    int cookingTime;
    String difficulty;
    int? calories;

    if (isSpoonacular) {
      name = recipe.title;
      imageUrl = recipe.image;
      matchPercentage = recipe.matchPercentage;
      missingIngredients = recipe.missingIngredientNames;
      cookingTime = 30; // Not provided by basic API
      difficulty = recipe.difficulty;

      // Estimate calories from ingredients
      calories = recipe.totalCalories;
    } else {
      name = recipe.name;
      imageUrl = recipe.imageUrl;
      matchPercentage = recipe.getMatchPercentage(availableIngredients);
      missingIngredients = recipe.getMissingIngredients(availableIngredients);
      cookingTime = recipe.cookingTime;
      difficulty = recipe.difficulty;
      calories = recipe.getTotalCalories();
    }

    final isPerfectMatch = missingIngredients.isEmpty;

    Color matchColor;
    if (matchPercentage >= 75) {
      matchColor = const Color(0xFF1F8E62);
    } else if (matchPercentage >= 50) {
      matchColor = const Color(0xFFC17E00);
    } else {
      matchColor = const Color(0xFFC05A45);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPerfectMatch
              ? const Color(0xFF1F8E62).withValues(alpha: 0.35)
              : _forestGreen.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _forestGreen.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
            padding: const EdgeInsets.all(14),
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
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _warmCream.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: _forestGreen,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    if (imageUrl.isNotEmpty) const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              color: _forestGreen,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: matchColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: matchColor,
                                    width: 1,
                                  ),
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
                                          color: matchColor.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (calories != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '$calories kcal',
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (isSpoonacular)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _forestGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _forestGreen.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.cloud,
                                        size: 12,
                                        color: _forestGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'API',
                                        style: GoogleFonts.poppins(
                                          color: _forestGreen,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
                      color: _forestGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$cookingTime min',
                      style: GoogleFonts.poppins(
                        color: _forestGreen.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.signal_cellular_alt,
                      size: 16,
                      color: _forestGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      difficulty,
                      style: GoogleFonts.poppins(
                        color: _forestGreen.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (missingIngredients.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildMissingIngredients(
                    missingIngredients,
                    recipe.getAvailableSubstitutes(availableIngredients),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build missing ingredients section
  Widget _buildMissingIngredients(
    List<String> missing,
    Map<String, List<String>> substitutes,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC05A45).withValues(alpha: 0.32),
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
                color: Color(0xFFC17E00),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Missing ${missing.length} ingredient${missing.length > 1 ? "s" : ""}',
                style: GoogleFonts.poppins(
                  color: _forestGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...missing.map((item) {
            final availableSubs = substitutes[item];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• $item',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFC05A45),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (availableSubs != null && availableSubs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        'Can substitute with: ${availableSubs.join(", ")}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1F8E62),
                          fontSize: 11,
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

  /// Show recipe detail bottom sheet
  void _showRecipeDetail(
    BuildContext context,
    dynamic recipe,
    List<String> availableIngredients,
    List<String> missingIngredients,
  ) async {
    // Store scaffold messenger before async call
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading dialog for API recipes
    if (recipe.runtimeType.toString().contains('Spoonacular')) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator(color: _forestGreen)),
      );
    }

    final provider = context.read<GroceryProvider>();
    final detail = await provider.getRecipeDetail(recipe);

    // Close loading dialog
    if (recipe.runtimeType.toString().contains('Spoonacular') &&
        context.mounted) {
      Navigator.pop(context);
    }

    if (detail == null) {
      // Show error message if detail fetch failed
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Unable to load recipe details. The recipe might be unavailable.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFFC17E00),
            action: SnackBarAction(
              label: 'Close',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      return;
    }

    // Show detail bottom sheet
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _forestGreen.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: _buildDetailContent(
                    context,
                    detail,
                    availableIngredients,
                    missingIngredients,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build detail content widgets list
  List<Widget> _buildDetailContent(
    BuildContext context,
    Map<String, dynamic> detail,
    List<String> availableIngredients,
    List<String> missingIngredients,
  ) {
    // Extract used ingredients
    final used = List<String>.from(
      detail['usedIngredients'] ?? detail['ingredients'] ?? [],
    );
    final imageUrl = detail['image'] ?? '';

    return [
      // Recipe image (if available)
      if (imageUrl.isNotEmpty)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryAmber.withValues(alpha: 0.2),
                      _warmCream.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: _forestGreen,
                ),
              );
            },
          ),
        ),
      if (imageUrl.isNotEmpty) const SizedBox(height: 20),

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
                    color: _forestGreen,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryAmber.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              detail['isFromAPI'] == true ? Icons.cloud : Icons.restaurant,
              color: detail['isFromAPI'] == true ? _forestGreen : _forestGreen,
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _warmCream.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _forestGreen.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CalorieDonutChart(
                calorieBreakdown: detail['calorieBreakdown'] ?? {},
                totalCalories: detail['calories'] ?? 0,
                size: 84,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Calories',
                      style: GoogleFonts.poppins(
                        color: _forestGreen.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${detail['calories']} kcal',
                      style: GoogleFonts.poppins(
                        color: _forestGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (detail['calorieBreakdown'] != null)
                      const SizedBox(height: 8),
                    if (detail['calorieBreakdown'] != null)
                      CalorieLegend(
                        breakdown: detail['calorieBreakdown'],
                        textColor: _forestGreen.withValues(alpha: 0.9),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],

      // Ingredients section
      Text(
        'Ingredients',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _forestGreen,
        ),
      ),
      const SizedBox(height: 12),

      // Available ingredients
      if (used.isNotEmpty) ...[
        _buildIngredientSection(context, 'Available', used, true),
        const SizedBox(height: 16),
      ],

      // Missing ingredients
      if (missingIngredients.isNotEmpty) ...[
        _buildIngredientSection(context, 'Missing', missingIngredients, false),
        const SizedBox(height: 16),

        // Add all missing ingredients button
        ElevatedButton.icon(
          onPressed: () => _addMissingIngredients(context, detail),
          icon: const Icon(Icons.add_shopping_cart, size: 18),
          label: Text(
            'Add All Missing (${missingIngredients.length})',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryAmber,
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
          color: _forestGreen,
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _forestGreen.withValues(alpha: 0.12)),
        ),
        child: Text(
          detail['instructions'] ?? 'No instructions available.',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: _forestGreen.withValues(alpha: 0.9),
            height: 1.5,
          ),
        ),
      ),

      SizedBox(height: MediaQuery.of(context).padding.bottom + 28),
    ];
  }

  /// Build ingredient section
  Widget _buildIngredientSection(
    BuildContext context,
    String title,
    List<String> items,
    bool isAvailable,
  ) {
    final sectionColor = isAvailable
        ? const Color(0xFF1F8E62)
        : const Color(0xFFC05A45);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sectionColor.withValues(alpha: 0.35),
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
                color: sectionColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$title (${items.length})',
                style: GoogleFonts.poppins(
                  color: _forestGreen,
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
                    color: sectionColor,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ingredient,
                      style: GoogleFonts.poppins(
                        color: _forestGreen,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _forestGreen.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primaryAmber),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: _forestGreen,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Add all missing ingredients to the grocery list
  void _addMissingIngredients(
    BuildContext context,
    Map<String, dynamic> detail,
  ) {
    final provider = context.read<GroceryProvider>();
    final missingIngredients = List<String>.from(
      detail['missedIngredients'] ?? detail['ingredients'] ?? [],
    );

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
      final existing = provider.items.any(
        (item) =>
            item.name.toLowerCase() == ingredient.toLowerCase() &&
            !item.isPurchased,
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
            'Added $addedCount ingredient${addedCount > 1 ? 's' : ''}',
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
            'All ingredients are already in your list',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFC17E00),
        ),
      );
    }
  }
}
