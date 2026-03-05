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
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF5EFDF), // cream
        Color(0xFFEDE4CF),
      ],
    ),
  );
}

  /// Build app header
  Widget _buildHeader(BuildContext context) {
  const forestGreen = Color(0xFF0F5741);
  const primaryAmber = Color(0xFFFFBF00);

  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryAmber,
                primaryAmber.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.kitchen_rounded,
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
                'Smart Kitchen',
                style: GoogleFonts.poppins(
                  color: forestGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Voice Recipe Assistant',
                style: GoogleFonts.poppins(
                  color: forestGreen.withOpacity(0.6),
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
  Widget _buildIngredientCountCard(
    BuildContext context, GroceryProvider provider) {
  const forestGreen = Color(0xFF0F5741);
  const primaryAmber = Color(0xFFFFBF00);

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: forestGreen.withOpacity(0.08),
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
            color: primaryAmber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.shopping_basket_outlined,
            color: forestGreen,
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Ingredients',
              style: GoogleFonts.poppins(
                color: forestGreen.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            Text(
              '${provider.totalItems}',
              style: GoogleFonts.poppins(
                color: forestGreen,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
  const forestGreen = Color(0xFF0F5741);

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mic_none,
          size: 70,
          color: forestGreen.withOpacity(0.3),
        ),
        const SizedBox(height: 20),
        Text(
          'No ingredients yet',
          style: GoogleFonts.poppins(
            color: forestGreen,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap the microphone to start adding',
          style: GoogleFonts.poppins(
            color: forestGreen.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

  /// Build ingredient card
  Widget _buildIngredientCard(
  BuildContext context,
  GroceryItem item,
  GroceryProvider provider,
) {
  final category = GroceryCategory.getCategoryForItem(item.name);
  const forestGreen = Color(0xFF0F5741);

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: forestGreen.withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        )
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(category.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: forestGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.formattedAmount,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: forestGreen.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          color: forestGreen.withOpacity(0.5),
          onPressed: () =>
              _showItemOptions(context, item, provider),
        ),
      ],
    ),
  );
}

  /// Build input section
  Widget _buildInputSection(BuildContext context) {
  final provider = context.watch<GroceryProvider>();
  final isListening = provider.voiceService.isListening;

  const forestGreen = Color(0xFF0F5741);
  const primaryAmber = Color(0xFFFFBF00);
  const softCream = Color(0xFFF6F1E5);

  return Container(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(36),
        topRight: Radius.circular(36),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 30,
          offset: const Offset(0, -10),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          /// ===== ERROR MESSAGE =====
          if (provider.errorMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade400, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.errorMessage,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => provider.clearError(),
                    child: Icon(Icons.close,
                        size: 16, color: Colors.red.shade400),
                  )
                ],
              ),
            ),

          /// ===== TEXT FIELD WITH BUILT-IN MIC =====
          /// ===== TEXT FIELD WITH MIC ON THE LEFT =====
Container(
  decoration: BoxDecoration(
    color: softCream,
    borderRadius: BorderRadius.circular(30),
    border: Border.all(
      color: isListening
          ? Colors.red
          : primaryAmber.withOpacity(0.4),
      width: 1.5,
    ),
  ),
  child: TextField(
    controller: _textController,
    enabled: !_isValidating,
    style: GoogleFonts.poppins(
      color: forestGreen,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
    decoration: InputDecoration(
      hintText: _validateBeforeAdd
          ? 'Type ingredient to validate & add...'
          : 'Type or hold mic to speak...',
      hintStyle: GoogleFonts.poppins(
        color: forestGreen.withOpacity(0.4),
        fontSize: 14,
      ),
      border: InputBorder.none,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18),

      /// 🎤 MIC ON LEFT
      prefixIcon: GestureDetector(
        onTapDown: (_) => _startListening(context),
        onTapUp: (_) => _stopListening(context),
        onTapCancel: () => _stopListening(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isListening
                ? Colors.red
                : forestGreen,
            boxShadow: isListening
                ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Icon(
            isListening ? Icons.mic : Icons.mic_none,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),

      /// ➤ SEND BUTTON RIGHT
      suffixIcon: !_isValidating
          ? IconButton(
              icon: const Icon(Icons.send),
              color: primaryAmber,
              onPressed: () => _submitText(context),
            )
          : null,
    ),
    onSubmitted: (_) => _submitText(context),
  ),
),

          const SizedBox(height: 14),

          /// ===== VALIDATION TOGGLE (CLEANER VERSION) =====
          Row(
            children: [
              Icon(
                _validateBeforeAdd
                    ? Icons.verified_rounded
                    : Icons.flash_on_rounded,
                size: 18,
                color: _validateBeforeAdd
                    ? primaryAmber
                    : forestGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _validateBeforeAdd
                      ? 'Validation Mode'
                      : 'Quick Add Mode',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: forestGreen,
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

  thumbColor: MaterialStateProperty.resolveWith((states) {
    if (states.contains(MaterialState.selected)) {
      return primaryAmber; // ตอนเปิด = เหลือง
    }
    return forestGreen; // ตอนปิด = เขียว
  }),

  trackColor: MaterialStateProperty.resolveWith((states) {
    if (states.contains(MaterialState.selected)) {
      return primaryAmber.withOpacity(0.35);
    }
    return forestGreen.withOpacity(0.35);
  }),

  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
),
            ],
          ),
        ],
      ),
    ),
  );
}

  /// Build "Calculate Recipes" button
  Widget _buildCalculateButton(BuildContext context) {
  final provider = context.watch<GroceryProvider>();

  const forestGreen = Color(0xFF0F5741);

  /// 👇 ถ้าไม่มี ingredient เลย ไม่ต้องแสดงปุ่ม
  if (provider.totalItems == 0) {
    return const SizedBox.shrink();
  }

  return Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 58,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeSuggestionScreen(
                  ingredients: provider.unpurchasedItems
                      .map((e) => e.name)
                      .toList(),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: forestGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant_menu, size: 22),
              const SizedBox(width: 10),
              Text(
                'Calculate Recipes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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

/// Unit Selection Dialog
/// Allows users to manually add ingredients with custom amount and unit
Future<void> showAddIngredientManuallyDialog(BuildContext context) async {
  final ingredientController = TextEditingController();
  final amountController = TextEditingController(text: '1');
  String selectedUnit = 'pcs';

  return showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          title: Row(
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Ingredient Manually',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'เพิ่มวัตถุดิบแบบระบุ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ingredient name input
                Text(
                  'Ingredient Name / ชื่อวัตถุดิบ',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ingredientController,
                  decoration: InputDecoration(
                    hintText: 'e.g., ไก่, chicken, ข้าว',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.restaurant, color: Colors.orange),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Amount input
                Text(
                  'Amount / ปริมาณ',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '1',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.numbers, color: Colors.blue),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Unit selection
                Text(
                  'Unit / หน่วย',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedUnit,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2A2A3E),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                      items: [
                        DropdownMenuItem(
                          value: 'pcs',
                          child: Text('Pieces / ชิ้น', style: GoogleFonts.poppins()),
                        ),
                        DropdownMenuItem(
                          value: 'ตัว',
                          child: Text('ตัว', style: GoogleFonts.poppins()),
                        ),
                        DropdownMenuItem(
                          value: 'g',
                          child: Text('Grams (g)', style: GoogleFonts.poppins()),
                        ),
                        DropdownMenuItem(
                          value: 'กรัม',
                          child: Text('กรัม', style: GoogleFonts.poppins()),
                        ),
                        DropdownMenuItem(
                          value: 'kg',
                          child: Text('Kilograms (kg)', style: GoogleFonts.poppins()),
                        ),
                        DropdownMenuItem(
                          value: 'กิโล',
                          child: Text('กิโล', style: GoogleFonts.poppins()),
                        ),
                        DropdownMenuItem(
                          value: 'cup',
                          child: Text('Cup / ถ้วย', style: GoogleFonts.poppins()),
                        ),
                        DropdownMenuItem(
                          value: 'tbsp',
                          child: Text('Tablespoon / ช้อนโตเที่ยม', style: GoogleFonts.poppins()),
                        ),
                        DropdownMenuItem(
                          value: 'tsp',
                          child: Text('Teaspoon / ช้อนชา', style: GoogleFonts.poppins()),
                        ),
                        DropdownMenuItem(
                          value: 'ml',
                          child: Text('Milliliter (ml) / มิลลิลิตร', style: GoogleFonts.poppins()),
                        ),
                        DropdownMenuItem(
                          value: 'liter',
                          child: Text('Liter / ลิตร', style: GoogleFonts.poppins()),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedUnit = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick unit buttons
                Text(
                  'Quick Select / เลือกด่วน',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickUnitButton('pcs', 'ชิ้น', selectedUnit, (unit) {
                      setState(() => selectedUnit = unit);
                    }),
                    _buildQuickUnitButton('g', 'กรัม', selectedUnit, (unit) {
                      setState(() => selectedUnit = unit);
                    }),
                    _buildQuickUnitButton('kg', 'กิโล', selectedUnit, (unit) {
                      setState(() => selectedUnit = unit);
                    }),
                    _buildQuickUnitButton('cup', 'ถ้วย', selectedUnit, (unit) {
                      setState(() => selectedUnit = unit);
                    }),
                    _buildQuickUnitButton('ตัว', 'ตัว', selectedUnit, (unit) {
                      setState(() => selectedUnit = unit);
                    }),
                    _buildQuickUnitButton('หัว', 'หัว', selectedUnit, (unit) {
                      setState(() => selectedUnit = unit);
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancel / ยกเลิก'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade400,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (ingredientController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter ingredient name / กรุณาใส่่ชื่อวัตถุดิบ',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text) ?? 1.0;

                final provider = context.read<GroceryProvider>();
                final item = GroceryItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: ingredientController.text.trim(),
                  amount: amount,
                  unit: selectedUnit,
                );

                provider.addItemManually(item);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added ${ingredientController.text} ($amount $selectedUnit) / เพิ่ม ${ingredientController.text} ($amount $selectedUnit) แล้ว',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.add_circle, size: 18),
              label: const Text('Add / เพิ่ม'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// Build quick unit selection button
Widget _buildQuickUnitButton(
  String unitValue,
  String label,
  String selectedUnit,
  Function(String) onTap,
) {
  final isSelected = selectedUnit == unitValue;
  return OutlinedButton(
    onPressed: () => onTap(unitValue),
    style: OutlinedButton.styleFrom(
      backgroundColor: isSelected ? Colors.orange.withValues(alpha: 0.2) : Colors.transparent,
      foregroundColor: isSelected ? Colors.orange : Colors.white.withValues(alpha: 0.6),
      side: BorderSide(
        color: isSelected ? Colors.orange : Colors.white.withValues(alpha: 0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: Text(
      label,
      style: GoogleFonts.poppins(fontSize: 11),
    ),
  );
}

