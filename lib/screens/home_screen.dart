import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';
import '../services/spoonacular_service.dart';
import 'recipe_suggestion_screen.dart';

// Export the IngredientSearchResult for use in this file
export '../services/spoonacular_service.dart' show IngredientSearchResult;

/// Home Screen - Voice Input with Validation
/// Main screen for adding ingredients via voice/text with validation layer
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Validation state
  bool _validateBeforeAdd = false;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroceryProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Consumer<GroceryProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      children: [
                        _buildIngredientCountCard(context, provider),
                        Expanded(child: _buildIngredientList(context, provider)),
                      ],
                    );
                  },
                ),
              ),
              _buildInputSection(context),
              _buildCalculateButton(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build gradient background decoration
  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1A1A2E),
          Color(0xFF16213E),
          Color(0xFF0F3460),
        ],
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.kitchen_rounded,
              color: Colors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Kitchen',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Voice Recipe Assistant',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _buildSettingsButton(context),
        ],
      ),
    );
  }

  /// Build settings button
  Widget _buildSettingsButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: const Icon(Icons.settings_outlined, color: Colors.white),
        onPressed: () => _showSettingsDialog(context),
      ),
    );
  }

  /// Build ingredient count card
  Widget _buildIngredientCountCard(BuildContext context, GroceryProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.25),
            Colors.orange.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              color: Colors.orange,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Ingredients',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.totalItems} items',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (provider.totalItems > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                'Ready to cook!',
                style: GoogleFonts.poppins(
                  color: Colors.green.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build ingredient list
  Widget _buildIngredientList(BuildContext context, GroceryProvider provider) {
    final items = provider.unpurchasedItems;

    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildIngredientCard(context, items[index], provider),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none,
            size: 64,
            color: Colors.orange.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No ingredients yet',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the microphone to add ingredients',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build ingredient card
  Widget _buildIngredientCard(BuildContext context, GroceryItem item, GroceryProvider provider) {
    final category = GroceryCategory.getCategoryForItem(item.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: category.color.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              category.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          item.formattedAmount,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _showItemOptions(context, item, provider),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build input section
  Widget _buildInputSection(BuildContext context) {
    final provider = context.watch<GroceryProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message display
            if (provider.errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.errorMessage,
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade200,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => provider.clearError(),
                      child: const Icon(Icons.close, color: Colors.red, size: 16),
                    ),
                  ],
                ),
              ),

            // Text input field
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                enabled: !_isValidating,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: _isValidating
                      ? 'Validating ingredient...'
                      : (_validateBeforeAdd
                          ? 'Type ingredient to validate & add...'
                          : 'Type or speak to add ingredients...'),
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  suffixIcon: _isValidating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.orange),
                          onPressed: () => _submitText(context),
                        ),
                ),
                onSubmitted: (_) => _submitText(context),
              ),
            ),

            const SizedBox(height: 8),

            // API Quota Indicator (when validation is enabled)
            if (_validateBeforeAdd)
              Consumer<SpoonacularService>(
                builder: (context, service, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: service.hasQuotaAvailable
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: service.hasQuotaAvailable
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.api,
                          size: 14,
                          color: service.hasQuotaAvailable
                              ? Colors.green.shade400
                              : Colors.red.shade400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'API Quota: ${service.remainingQuota}/150',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            if (_validateBeforeAdd) const SizedBox(height: 8),

            // Validation Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _validateBeforeAdd ? Icons.verified : Icons.offline_bolt,
                    size: 18,
                    color: _validateBeforeAdd ? Colors.green.shade400 : Colors.orange.shade400,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _validateBeforeAdd
                          ? 'Validate ingredients before adding'
                          : 'Quick add (skip validation)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Switch(
                    value: _validateBeforeAdd,
                    onChanged: !_isValidating
                        ? (value) {
                            setState(() {
                              _validateBeforeAdd = value;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Voice recording button
            _buildRecordButton(context, provider),
          ],
        ),
      ),
    );
  }

  /// Build "Calculate Recipes" button
  Widget _buildCalculateButton(BuildContext context) {
    final provider = context.watch<GroceryProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ElevatedButton(
        onPressed: provider.totalItems > 0
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeSuggestionScreen(
                      ingredients: provider.unpurchasedItems.map((e) => e.name).toList(),
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade700,
          disabledForegroundColor: Colors.grey.shade500,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 28),
            const SizedBox(width: 12),
            Text(
              'Calculate Recipes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build animated record button
  Widget _buildRecordButton(BuildContext context, GroceryProvider provider) {
    final isListening = provider.voiceService.isListening;

    return GestureDetector(
      onTapDown: (_) => _startListening(context),
      onTapUp: (_) => _stopListening(context),
      onTapCancel: () => _stopListening(context),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isListening
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : [Colors.orange.shade400, Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isListening
                  ? [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 20 * _pulseAnimation.value,
                        spreadRadius: 5 * (_pulseAnimation.value - 1),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: isListening
                  ? _buildListeningIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mic, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Hold to Speak',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  /// Build listening indicator
  Widget _buildListeningIndicator() {
    return Shimmer.fromColors(
      baseColor: Colors.white,
      highlightColor: Colors.white.withValues(alpha: 0.5),
      period: const Duration(milliseconds: 800),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mic, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Text(
            'Listening...',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Start voice listening
  void _startListening(BuildContext context) async {
    final provider = context.read<GroceryProvider>();
    final voiceService = provider.voiceService;

    if (!voiceService.hasPermission) {
      final granted = await voiceService.requestMicrophonePermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    await voiceService.startListening(
      onResult: (text) async {
        if (_validateBeforeAdd) {
          // Validate the voice input
          _textController.text = text;
          await _validateAndAddIngredient(context);
        } else {
          provider.processInput(text, isVoice: true);
        }
      },
    );

    _pulseController.repeat();
  }

  /// Stop voice listening
  void _stopListening(BuildContext context) async {
    final provider = context.read<GroceryProvider>();
    await provider.voiceService.stopListening();
    _pulseController.stop();
    _pulseController.reset();
  }

  /// Submit text input
  Future<void> _submitText(BuildContext context) async {
    if (_textController.text.trim().isEmpty) return;

    if (_validateBeforeAdd) {
      await _validateAndAddIngredient(context);
    } else {
      final provider = context.read<GroceryProvider>();
      provider.processInput(_textController.text, isVoice: false);
      _textController.clear();
    }
  }

  /// Validate ingredient before adding
  Future<void> _validateAndAddIngredient(BuildContext context) async {
    final ingredientName = _textController.text.trim();
    final service = context.read<SpoonacularService>();

    setState(() => _isValidating = true);

    try {
      // Validate against Spoonacular database
      final validationResult = await service.validateIngredient(ingredientName);

      if (validationResult == null) {
        // Ingredient not found
        if (mounted) {
          _showIngredientNotFoundDialog(ingredientName);
        }
      } else {
        // Show confirmation dialog
        if (mounted) {
          final shouldAdd = await _showIngredientConfirmationDialog(
            ingredientName,
            validationResult,
          );

          if (shouldAdd == true) {
            // Add the validated ingredient
            final provider = context.read<GroceryProvider>();
            provider.processInput(validationResult.name, isVoice: false);
            _textController.clear();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
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
  void _showIngredientNotFoundDialog(String ingredientName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ingredient Not Recognized',
                style: TextStyle(color: Colors.white),
              ),
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This ingredient was not found in the Spoonacular database. '
              'Please check the spelling or try a different name.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show item options
  void _showItemOptions(BuildContext context, GroceryItem item, GroceryProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                title: Text(
                  'Edit',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, item, provider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  provider.deleteItem(item.id);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Show edit dialog
  void _showEditDialog(BuildContext context, GroceryItem item, GroceryProvider provider) {
    final nameController = TextEditingController(text: item.name);
    final amountController = TextEditingController(text: item.amount.toString());
    final unitController = TextEditingController(text: item.unit);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Ingredient',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditField(nameController, 'Name', Icons.label_outline),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEditField(amountController, 'Qty', Icons.format_list_numbered),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEditField(unitController, 'Unit', Icons.straighten),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.updateItem(item.copyWith(
                name: nameController.text,
                amount: double.tryParse(amountController.text) ?? item.amount,
                unit: unitController.text,
              ));
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  /// Build edit field
  Widget _buildEditField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange),
        ),
      ),
    );
  }

  /// Show settings dialog
  void _showSettingsDialog(BuildContext context) {
    final provider = context.read<GroceryProvider>();
    final apiKeyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: TextField(
          controller: apiKeyController,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Gemini API Key (optional)',
            labelStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              if (apiKeyController.text.isNotEmpty) {
                provider.setApiKey(apiKeyController.text);
              }
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ingredient Confirmation Dialog for Home Screen
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
      backgroundColor: const Color(0xFF1A1A2E),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with checkmark
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.green.shade50.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.green.shade400,
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
                      color: Colors.white,
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
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
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
                            color: Colors.grey.shade800,
                            child: Icon(
                              Icons.restaurant,
                              size: 48,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade900,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.orange,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: 48,
                      color: Colors.grey.shade600,
                    ),
                  ),

                const SizedBox(height: 16),

                // Original input
                Text(
                  'You entered: "$originalInput"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
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
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        searchResult.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category,
                        size: 14,
                        color: Colors.blue.shade300,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        searchResult.aisle,
                        style: TextStyle(
                          color: Colors.blue.shade200,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
        // Cancel button
        TextButton.icon(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Cancel'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade400,
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

