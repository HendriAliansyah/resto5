// lib/views/inventory/stock_movement_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:resto2/models/inventory_item_model.dart';
import 'package:resto2/providers/stock_movement_provider.dart';
import 'package:resto2/views/purchase/widgets/inventory_item_selector.dart';
import 'package:resto2/views/widgets/app_drawer.dart';
import 'package:resto2/views/widgets/custom_app_bar.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';
import 'package:resto2/utils/constants.dart';

class StockMovementHistoryPage extends HookConsumerWidget {
  const StockMovementHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItem = useState<InventoryItem?>(null);
    final movementsAsync = selectedItem.value != null
        ? ref.watch(stockMovementsStreamProvider(selectedItem.value!.id))
        : null;

    return Scaffold(
      appBar: const CustomAppBar(title: Text(UIStrings.stockMovementHistory)),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InventoryItemSelector(
              initialValue: selectedItem.value,
              validator: (item) => null, // No validation needed here
              onSaved: (item) {}, // Not used here
              onChanged: (item) {
                selectedItem.value = item;
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedItem.value == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          UIStrings.selectAnItem,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          UIStrings.selectAnItemToViewHistory,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : movementsAsync!.when(
                    data: (movements) {
                      if (movements.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_toggle_off_outlined,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                UIStrings.noHistoryFound,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                UIStrings.noHistoryMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: movements.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final movement = movements[index];
                          final isAddition = movement.quantityChanged > 0;
                          final formattedDate = DateFormat.yMd()
                              .add_jm()
                              .format(movement.createdAt.toDate());
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      Text(
                                        UIStrings.byUser.replaceFirst(
                                          '{name}',
                                          movement.userDisplayName,
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isAddition
                                            ? Colors.green.withAlpha(26)
                                            : Colors.red.withAlpha(26),
                                        child: Icon(
                                          isAddition
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          color: isAddition
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(UIStrings.change),
                                            Text(
                                              '${isAddition ? '+' : ''}${movement.quantityChanged.toStringAsFixed(2)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            const Text(UIStrings.newQuantity),
                                            Text(
                                              movement.quantityAfter
                                                  .toStringAsFixed(2),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    UIStrings.reasonLabel.replaceFirst(
                                      '{reason}',
                                      movement.reason,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const LoadingIndicator(),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
          ),
        ],
      ),
    );
  }
}
