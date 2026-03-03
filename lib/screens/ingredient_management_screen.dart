import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../services/spoonacular_service.dart';
import '../widgets/calorie_donut_chart.dart';

/// Ingredient Management Screen
/// Allows users to input ingredients via voice/text and displays categorized results
/// Features validation layer to verify ingredients against Spoonacular database
class IngredientManagementScreen extends StatefulWidget {
  const IngredientManagementScreen({super.key});

  @override
  State<IngredientManagementScreen> createState() =>
      _IngredientManagementScreenState();
}

class _IngredientManagementScreenState extends State<IngredientManagementScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isProcessing = false;
  bool _validateBeforeAdd = true; // Toggle for validation mode
  IngredientParseResult? _parseResult;
  String _errorMessage = '';

  // Validation state
  List<Ingredient> _validatedIngredients = [];
  List<String> _unrecognizedIngredients = [];

  // Quick add suggestions
  final List<String> _quickAddSuggestions = [
    '200g chicken breast',
    '3 eggs',
    '1 cup rice',
    '2 tbsp olive oil',
    '100g broccoli',
    '1 banana',
    '250ml milk',
    '2 slices bread',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Process ingredient input with validation
  Future<void> _processIngredients() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
      _parseResult = null;
      _validatedIngredients.clear();
      _unrecognizedIngredients.clear();
    });

    try {
      final service = context.read<SpoonacularService>();

      // Split input by lines for processing
      final lines = _inputController.text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (_validateBeforeAdd) {
        // Validate each ingredient individually
        await _validateAndConfirmIngredients(service, lines);
      } else {
        // Skip validation, parse directly
        final result = await service.smartParseIngredients(lines);
        setState(() {
          _parseResult = result;
          if (!result.success) {
            _errorMessage = result.message;
          } else {
            _validatedIngredients = result.ingredients;
          }
          _isProcessing = false;
        });

        if (result.success && result.ingredients.isNotEmpty) {
          _inputController.clear();
        }
      }

      // Scroll to results
      if (_scrollController.hasClients) {
        await Future.delayed(const Duration(milliseconds: 100));
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  /// Validate ingredients one by one and show confirmation dialogs
  Future<void> _validateAndConfirmIngredients(
    SpoonacularService service,
    List<String> lines,
  ) async {
    final validatedIngredients = <Ingredient>[];
    final unrecognizedIngredients = <String>[];

    for (final line in lines) {
      final ingredientName = line.trim();

      // Validate against Spoonacular database
      final validationResult = await service.validateIngredient(ingredientName);

      if (validationResult == null) {
        // Ingredient not found
        unrecognizedIngredients.add(ingredientName);

        // Show error dialog
        if (mounted) {
          final shouldContinue = await _showIngredientNotFoundDialog(ingredientName);
          if (!shouldContinue) {
            setState(() {
              _unrecognizedIngredients = unrecognizedIngredients;
              _isProcessing = false;
            });
            return;
          }
        }
      } else {
        // Show confirmation dialog with image
        if (mounted) {
          final shouldAdd = await _showIngredientConfirmationDialog(
            ingredientName,
            validationResult,
          );

          if (shouldAdd == true) {
            // Get full ingredient information with nutrition
            try {
              final fullIngredient = await service.getValidatedIngredientInformation(
                validationResult.id,
                amount: 1,
                unit: 'serving',
              );
              validatedIngredients.add(fullIngredient);
            } catch (e) {
              // If getting nutrition fails, create basic ingredient from search result
              final basicIngredient = Ingredient(
                id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + validationResult.id.toString(),
                name: validationResult.name,
                amount: 1,
                unit: 'serving',
                aisle: validationResult.aisle,
                nutrition: null,
              );
              validatedIngredients.add(basicIngredient);
            }
          } else if (shouldAdd == false) {
            // User canceled
            setState(() {
              _isProcessing = false;
            });
            return;
          }
          // If shouldAdd is null, skip this ingredient and continue
        }
      }
    }

    // Update state with results
    setState(() {
      _validatedIngredients = validatedIngredients;
      _unrecognizedIngredients = unrecognizedIngredients;
      _parseResult = IngredientParseResult(
        ingredients: validatedIngredients,
        success: validatedIngredients.isNotEmpty,
        message: validatedIngredients.isEmpty
            ? 'No ingredients were added.'
            : 'Successfully added ${validatedIngredients.length} ingredient${validatedIngredients.length != 1 ? 's' : ''}.'
                '${unrecognizedIngredients.isNotEmpty ? ' ${unrecognizedIngredients.length} not recognized.' : ''}',
      );
      _isProcessing = false;
    });

    // Clear input if we had success
    if (validatedIngredients.isNotEmpty) {
      _inputController.clear();
    }
  }

  /// Show confirmation dialog when ingredient is found
  Future<bool?> _showIngredientConfirmationDialog(
    String originalInput,
    IngredientSearchResult searchResult,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _IngredientConfirmationDialog(
        originalInput: originalInput,
        searchResult: searchResult,
      ),
    );
  }

  /// Show error dialog when ingredient is not found
  Future<bool> _showIngredientNotFoundDialog(String ingredientName) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Ingredient Not Recognized'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$ingredientName"',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This ingredient was not found in the Spoonacular database. '
              'Please check the spelling or try a different name.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stop'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Skip & Continue'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Add quick suggestion to input
  void _addQuickSuggestion(String suggestion) {
    final currentText = _inputController.text.trim();
    if (currentText.isEmpty) {
      _inputController.text = suggestion;
    } else {
      _inputController.text = '$currentText\n$suggestion';
    }
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ingredient Manager'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          // API Quota Indicator
          Consumer<SpoonacularService>(
            builder: (context, service, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Chip(
                    label: Text(
                      'Quota: ${service.remainingQuota}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: service.hasQuotaAvailable
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    side: BorderSide(
                      color: service.hasQuotaAvailable
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Input Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input Field
                TextField(
                  controller: _inputController,
                  maxLines: 4,
                  enabled: !_isProcessing,
                  decoration: InputDecoration(
                    hintText: 'Enter ingredients (one per line)\nExamples:\n'
                        '• 200g chicken breast\n'
                        '• 3 eggs\n'
                        '• 1 cup rice',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                ),

                const SizedBox(height: 8),

                // Validation Toggle
                Row(
                  children: [
                    Icon(
                      _validateBeforeAdd ? Icons.verified : Icons.offline_bolt,
                      size: 20,
                      color: _validateBeforeAdd ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validateBeforeAdd
                            ? 'Validate ingredients before adding'
                            : 'Quick add (skip validation)',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Switch(
                      value: _validateBeforeAdd,
                      onChanged: !_isProcessing
                          ? (value) {
                              setState(() {
                                _validateBeforeAdd = value;
                              });
                            }
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Quick Add Suggestions
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickAddSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _quickAddSuggestions[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == _quickAddSuggestions.length - 1
                              ? 0
                              : 8,
                        ),
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _addQuickSuggestion(suggestion),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Process Button
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processIngredients,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_validateBeforeAdd ? Icons.verified : Icons.restaurant_menu),
                  label: Text(
                    _isProcessing
                        ? 'Processing...'
                        : (_validateBeforeAdd ? 'Validate & Add Ingredients' : 'Parse Ingredients'),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: _validateBeforeAdd ? Colors.green : null,
                  ),
                ),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() => _errorMessage = '');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Results Section
          Expanded(
            child: _buildResults(context),
          ),
        ],
      ),
    );
  }

  /// Build the results section
  Widget _buildResults(BuildContext context) {
    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _validateBeforeAdd ? 'Validating ingredients...' : 'Parsing ingredients...',
            ),
            const SizedBox(height: 8),
            Consumer<SpoonacularService>(
              builder: (context, service, _) {
                return Text(
                  'API Quota: ${service.remainingQuota} remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // Use validated ingredients or parse result ingredients
    final displayIngredients = _validatedIngredients.isNotEmpty
        ? _validatedIngredients
        : (_parseResult?.ingredients ?? []);

    if (displayIngredients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No ingredients yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter ingredients above to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
    }

    // Group ingredients by category
    final groupedIngredients = <IngredientCategory, List<Ingredient>>{};
    for (final ingredient in displayIngredients) {
      final category = ingredient.category;
      groupedIngredients.putIfAbsent(category, () => []).add(ingredient);
    }

    // Calculate total calories
    final totalCalories = displayIngredients.fold<double>(
      0,
      (sum, ingredient) => sum + (ingredient.nutrition?.totalCalories ?? 0),
    );

    final uniqueCategories = groupedIngredients.keys.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Summary Header
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Success Message
                    if (_parseResult!.message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _parseResult!.message,
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            label: 'Ingredients',
                            value: displayIngredients.length.toString(),
                            icon: Icons.restaurant,
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            label: 'Categories',
                            value: uniqueCategories.length.toString(),
                            icon: Icons.category,
                            color: Colors.purple,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            label: 'Total Calories',
                            value: '${totalCalories.toStringAsFixed(0)} kcal',
                            icon: Icons.local_fire_department,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Calorie Distribution Chart
                    if (totalCalories > 0)
                      SizedBox(
                        height: 150,
                        child: CalorieDonutChart(
                          ingredients: displayIngredients,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Categorized Ingredients List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = uniqueCategories[index];
                final categoryIngredients = groupedIngredients[category];

                if (categoryIngredients == null || categoryIngredients.isEmpty) {
                  return const SizedBox.shrink();
                }

                return _CategoryTile(
                  category: category,
                  ingredients: categoryIngredients,
                );
              },
              childCount: uniqueCategories.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }
}

/// Stat Item Widget
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

/// Category Expansion Tile Widget
class _CategoryTile extends StatelessWidget {
  final IngredientCategory category;
  final List<Ingredient> ingredients;

  const _CategoryTile({
    required this.category,
    required this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    final totalCalories = ingredients.fold<double>(
      0,
      (sum, ing) => sum + (ing.nutrition?.totalCalories ?? 0),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                category.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          title: Text(
            category.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${ingredients.length} item${ingredients.length != 1 ? 's' : ''} • ${totalCalories.toStringAsFixed(0)} kcal',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: category.color.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${totalCalories.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: category.color.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.expand_more,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ingredients.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ingredient = ingredients[index];
                return _IngredientTile(
                  ingredient: ingredient,
                  categoryColor: category.color,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Ingredient Tile Widget
class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final Color categoryColor;

  const _IngredientTile({
    required this.ingredient,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Ingredient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.scale,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ingredient.formattedAmount,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.store,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ingredient.aisle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nutrition Info
          if (ingredient.nutrition != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ingredient.nutrition!.formattedCalories,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  if (ingredient.nutrition!.protein != null ||
                      ingredient.nutrition!.carbohydrates != null ||
                      ingredient.nutrition!.fat != null)
                    SizedBox(
                      width: 120,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        alignment: WrapAlignment.end,
                        children: [
                          if (ingredient.nutrition!.protein != null)
                            _NutrientChip(
                              label: 'P',
                              value: ingredient.nutrition!.protein!,
                              color: Colors.red,
                            ),
                          if (ingredient.nutrition!.carbohydrates != null)
                            _NutrientChip(
                              label: 'C',
                              value: ingredient.nutrition!.carbohydrates!,
                              color: Colors.blue,
                            ),
                          if (ingredient.nutrition!.fat != null)
                            _NutrientChip(
                              label: 'F',
                              value: ingredient.nutrition!.fat!,
                              color: Colors.yellow,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'No nutrition data',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Nutrient Chip Widget
class _NutrientChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _NutrientChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(0)}g',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color.withOpacity(0.9),
        ),
      ),
    );
  }
}

/// Ingredient Confirmation Dialog
/// Shows the validated ingredient with image and asks for user confirmation
class _IngredientConfirmationDialog extends StatelessWidget {
  final String originalInput;
  final IngredientSearchResult searchResult;

  const _IngredientConfirmationDialog({
    required this.originalInput,
    required this.searchResult,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with checkmark
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Ingredient Found!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Ingredient image
                if (searchResult.imageUrl != null)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        searchResult.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.restaurant,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),

                const SizedBox(height: 20),

                // Original input
                Text(
                  'You entered: "$originalInput"',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Official name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Official Name: ${searchResult.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Category/aisle info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        searchResult.aisle,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Skip button
        TextButton.icon(
          onPressed: () => Navigator.pop(context, null),
          icon: const Icon(Icons.skip_next, size: 18),
          label: const Text('Skip'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),

        // Add button
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.add_circle, size: 18),
          label: const Text('Add Ingredient'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(width: 8),
      ],
    );
  }
}

