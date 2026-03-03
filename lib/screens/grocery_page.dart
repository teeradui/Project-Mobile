import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';

class GroceryPage extends StatelessWidget {
  const GroceryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroceryProvider>();
    final items = provider.unpurchasedItems;

    final Map<GroceryCategory, List<GroceryItem>> groupedItems = {};
    for (final item in items) {
      final category = GroceryCategory.getCategoryForItem(item.name);
      groupedItems.putIfAbsent(category, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('MyGrocery')),
      body: items.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: groupedItems.entries.map((entry) {
                return _buildCategorySection(
                  context,
                  entry.key,
                  entry.value,
                  provider,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.local_grocery_store_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Your grocery list is empty!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
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
                style: TextStyle(color: Colors.grey.shade400),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(item.name),
        subtitle: Text(item.formattedAmount),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => provider.deleteItem(item.id),
        ),
      ),
    );
  }
}
