import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';

class GroceryPage extends StatefulWidget {
  const GroceryPage({super.key});

  @override
  State<GroceryPage> createState() => _GroceryPageState();
}

class _GroceryPageState extends State<GroceryPage> {
  final Set<String> selectedItems = {};

  @override
  Widget build(BuildContext context) {
    final primaryAmber = Theme.of(context).colorScheme.primary;
    final forestGreen = Theme.of(context).colorScheme.secondary;
    final creamBackground = Theme.of(context).colorScheme.surface;

    final provider = context.watch<GroceryProvider>();
    final items = [...provider.unpurchasedItems];

    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final Map<GroceryCategory, List<GroceryItem>> groupedItems = {};
    for (final item in items) {
      final category = GroceryCategory.getCategoryForItem(item.name);
      groupedItems.putIfAbsent(category, () => []).add(item);
    }

    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              _buildIngredientsHeader(context),

              if (selectedItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: Text("Delete selected(${selectedItems.length})"),
                    onPressed: () {
                      for (var id in selectedItems) {
                        provider.deleteItem(id);
                      }
                      setState(() {
                        selectedItems.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFEF5350).withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState(context)
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children:
                            (groupedItems.entries.toList()..sort(
                                  (a, b) => a.key.index.compareTo(b.key.index),
                                ))
                                .map((entry) {
                                  final sortedItems = [...entry.value]
                                    ..sort(
                                      (a, b) => a.name.toLowerCase().compareTo(
                                        b.name.toLowerCase(),
                                      ),
                                    );
                                  return _buildCategorySection(
                                    context,
                                    entry.key,
                                    sortedItems,
                                    provider,
                                  );
                                })
                                .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsHeader(BuildContext context) {
    final primaryAmber = Theme.of(context).colorScheme.primary;
    final forestGreen = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: primaryAmber,
              borderRadius: BorderRadius.circular(16),
              
            ),
            child: Icon(Icons.set_meal_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Ingredients',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: forestGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All items in your kitchen!',
                  style: TextStyle(
                    fontSize: 13,
                    color: forestGreen.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            color: Color(0xFFEF5350).withValues(alpha: 0.8),
            onPressed: () {
              context.read<GroceryProvider>().clearAllItems();

              setState(() {
                selectedItems.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.kitchen_rounded,
            size: 80,
            color: Colors.orange.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16),
          Text(
            'Your ingredients list is empty!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    GroceryCategory category,
    List<GroceryItem> items,
    GroceryProvider provider,
  ) {
    final primaryAmber = Theme.of(context).colorScheme.primary;
    final forestGreen = Theme.of(context).colorScheme.secondary;
    final creamBackground = Theme.of(context).colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                category.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: category.color,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} items',
                style: TextStyle(color: forestGreen.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildItemCard(context, item, provider)),
      ],
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    GroceryItem item,
    GroceryProvider provider,
  ) {
    final primaryAmber = Theme.of(context).colorScheme.primary;
    final forestGreen = Theme.of(context).colorScheme.secondary;
    final creamBackground = Theme.of(context).colorScheme.surface;

    final isSelected = selectedItems.contains(item.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          activeColor: primaryAmber.withValues(alpha: 0.5),
          side: BorderSide(color: forestGreen, width: 1.5),
          checkColor: forestGreen,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                selectedItems.add(item.id);
              } else {
                selectedItems.remove(item.id);
              }
            });
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(color: forestGreen, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          item.unit,
          style: TextStyle(
            color: forestGreen.withValues(alpha: 0.8),
            fontWeight: FontWeight.w400,
          ),
          /*item.formattedAmount,
          style: TextStyle(
            color: forestGreen.withValues(alpha: 0.8),
            fontWeight: FontWeight.w400,
          ),*/
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          /*decoration: BoxDecoration(
            color: primaryAmber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),*/
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  if (item.amount > 1) {
                    provider.updateItem(item.copyWith(amount: item.amount - 1));
                  }
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),

              Text(
                item.amount.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryAmber,
                ),
              ),

              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  provider.updateItem(item.copyWith(amount: item.amount + 1));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5EFDF), Color(0xFFEDE4CF), Color(0xFFE3D7BB)],
      ),
    );
  }
}
