import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/recipe.dart';

/// Recipe Suggestion Screen
/// Shows recipes based on available ingredients, missing items, and substitutes
class RecipeSuggestionScreen extends StatelessWidget {
  final List<String> ingredients;

  const RecipeSuggestionScreen({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    final matchingRecipes = RecipeDatabase.getMatchingRecipes(ingredients);

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
                child: matchingRecipes.isEmpty
                    ? _buildNoRecipesState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: matchingRecipes.length,
                        itemBuilder: (context, index) {
                          return _buildRecipeCard(
                            context,
                            matchingRecipes[index],
                            ingredients,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build app header
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            'Your Ingredients (${ingredients.length})',
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
            children: ingredients
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

  /// Build recipe card
  Widget _buildRecipeCard(
    BuildContext context,
    Recipe recipe,
    List<String> availableIngredients,
  ) {
    final matchPercentage = recipe.getMatchPercentage(availableIngredients);
    final missingIngredients = recipe.getMissingIngredients(availableIngredients);
    final availableSubstitutes = recipe.getAvailableSubstitutes(availableIngredients);
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
            availableSubstitutes,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recipe.nameThai,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: matchColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: matchColor),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${matchPercentage.toInt()}%',
                            style: GoogleFonts.poppins(
                              color: matchColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Match',
                            style: GoogleFonts.poppins(
                              color: matchColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.cookingTime} min',
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
                      recipe.difficulty,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (missingIngredients.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildMissingIngredients(
                    missingIngredients,
                    availableSubstitutes,
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
                      color: Colors.red.shade300,
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
                          color: Colors.green.shade300,
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
    Recipe recipe,
    List<String> availableIngredients,
    List<String> missingIngredients,
    Map<String, List<String>> availableSubstitutes,
  ) {
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
                  children: [
                    // Recipe name
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                recipe.nameThai,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.6),
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
                          '${recipe.cookingTime} min',
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          Icons.signal_cellular_alt,
                          recipe.difficulty,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

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
                    if (availableIngredients.isNotEmpty) ...[
                      _buildIngredientSection(
                        'Available',
                        recipe.ingredients
                            .where((ing) => !missingIngredients.contains(ing))
                            .toList(),
                        availableIngredients,
                        true,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Missing ingredients
                    if (missingIngredients.isNotEmpty) ...[
                      _buildIngredientSection(
                        'Missing',
                        missingIngredients,
                        availableIngredients,
                        false,
                        availableSubstitutes: availableSubstitutes,
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
                        recipe.instructions,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Thai instructions
                    Text(
                      'วิธีทำ',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recipe.instructionsThai,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build ingredient section
  Widget _buildIngredientSection(
    String title,
    List<String> items,
    List<String> availableIngredients,
    bool isAvailable, {
    Map<String, List<String>>? availableSubstitutes,
  }) {
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

          // Show substitutes if available
          if (!isAvailable && availableSubstitutes != null)
            ...availableSubstitutes.entries.map((entry) {
              final missingItem = entry.key;
              final subs = entry.value;

              if (items.any((item) => item.toLowerCase().contains(missingItem))) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.swap_horiz,
                                color: Colors.green,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Substitute with:',
                                style: GoogleFonts.poppins(
                                  color: Colors.green.shade300,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subs.join(', '),
                            style: GoogleFonts.poppins(
                              color: Colors.green.shade200,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return const SizedBox();
              }
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
}
