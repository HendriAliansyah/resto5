// lib/views/inventory/inventory_management_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/inventory_item_model.dart';
import 'package:resto2/providers/inventory_filter_provider.dart';
import 'package:resto2/providers/inventory_provider.dart';
import 'package:resto2/views/inventory/widgets/inventory_bottom_sheet.dart';
import 'package:resto2/views/widgets/filter_expansion_tile.dart';
import 'package:resto2/views/widgets/shared/entity_management_page.dart';
import 'package:resto2/views/widgets/sort_order_toggle.dart';
import 'package:resto2/utils/constants.dart';

class InventoryManagementPage extends ConsumerWidget {
  const InventoryManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedInventory = ref.watch(sortedInventoryProvider);
    final filterState = ref.watch(inventoryFilterProvider);

    void showItemSheet({InventoryItem? item}) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => InventoryBottomSheet(item: item),
      );
    }

    return EntityManagementPage<InventoryItem>(
      title: UIStrings.inventoryAndStock,
      noItemsFoundText: UIStrings.noInventoryItems,
      items: sortedInventory,
      onAdd: () => showItemSheet(),
      filterTile: FilterExpansionTile(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: UIStrings.searchByName,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => ref
                .read(inventoryFilterProvider.notifier)
                .setSearchQuery(value),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(UIStrings.sortByName),
              const SizedBox(width: 8),
              SortOrderToggle(
                currentOrder: filterState.sortOrder,
                onOrderChanged: (order) => ref
                    .read(inventoryFilterProvider.notifier)
                    .setSortOrder(order),
              ),
            ],
          ),
        ],
      ),
      itemBuilder: (context, item) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: ListTile(
            onTap: () => showItemSheet(item: item),
            leading: SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: item.imageUrl != null
                    ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.inventory_2_outlined),
                      ),
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              UIStrings.stockLabel.replaceFirst(
                '{value}',
                item.quantityInStock.toStringAsFixed(2),
              ),
            ),
            trailing: Text(
              UIStrings.avgCostLabel.replaceFirst(
                '{value}',
                item.averageCost.toStringAsFixed(2),
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
