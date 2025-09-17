// lib/views/order/order_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/order_type_model.dart';
import 'package:resto2/models/table_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/order_provider.dart';
import 'package:resto2/providers/order_type_provider.dart';
import 'package:resto2/providers/table_provider.dart';
import 'package:resto2/views/order/widgets/occupied_table_dialog.dart';
import 'package:resto2/views/order/widgets/order_bottom_sheet.dart';
import 'package:resto2/views/widgets/app_drawer.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';
import 'package:resto2/utils/constants.dart';

class OrderPage extends ConsumerWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderTypesAsync = ref.watch(orderTypesStreamProvider);

    return orderTypesAsync.when(
      data: (orderTypes) {
        if (orderTypes.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text(UIStrings.posNewOrder)),
            drawer: const AppDrawer(),
            body: const Center(child: Text(UIStrings.createOrderTypeMessage)),
          );
        }

        return DefaultTabController(
          length: orderTypes.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(UIStrings.posNewOrder),
              bottom: TabBar(
                isScrollable: true,
                tabs: orderTypes.map((ot) => Tab(text: ot.name)).toList(),
              ),
            ),
            drawer: const AppDrawer(),
            body: TabBarView(
              children: orderTypes.map((ot) {
                return _TableSelectionView(orderType: ot);
              }).toList(),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text(UIStrings.posNewOrder)),
        body: const LoadingIndicator(),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text(UIStrings.posNewOrder)),
        body: Center(child: Text('Error: ${e.toString()}')),
      ),
    );
  }
}

class _TableSelectionView extends ConsumerWidget {
  final OrderType orderType;
  const _TableSelectionView({required this.orderType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesStreamProvider);
    final theme = Theme.of(context);
    final restaurantId = ref
        .watch(currentUserProvider)
        .asData
        ?.value
        ?.restaurantId;

    void handleTableTap(TableModel table) async {
      if (restaurantId == null) return;

      if (table.isOccupied) {
        // Show a loading indicator while fetching the order
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final args = TableOrderArgs(
            tableId: table.id,
            restaurantId: restaurantId,
          );
          final order = await ref.read(activeOrderProvider(args).future);

          // **THE FIX IS HERE:** Guard all uses of BuildContext with a mounted check.
          if (context.mounted) {
            Navigator.of(context).pop(); // Dismiss loading indicator

            if (order != null) {
              showDialog(
                context: context,
                builder: (_) => OccupiedTableDialog(order: order),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(UIMessages.couldNotFindActiveOrder),
                ),
              );
            }
          }
        } catch (e) {
          // **THE FIX IS HERE:** Guard all uses of BuildContext with a mounted check.
          if (context.mounted) {
            Navigator.of(context).pop(); // Dismiss loading indicator
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  UIMessages.errorLoadingOrder.replaceFirst(
                    '{error}',
                    e.toString(),
                  ),
                ),
              ),
            );
          }
        }
      } else {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => OrderBottomSheet(table: table, orderType: orderType),
        );
      }
    }

    return tablesAsync.when(
      data: (allTables) {
        final filteredTables = allTables.where((table) {
          return table.orderTypeId == null || table.orderTypeId == orderType.id;
        }).toList();

        if (filteredTables.isEmpty) {
          return const Center(child: Text(UIStrings.noTablesForOrderType));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            childAspectRatio: 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredTables.length,
          itemBuilder: (context, index) {
            final table = filteredTables[index];
            final isOccupied = table.isOccupied;
            final cardColor = isOccupied
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.primaryContainer;
            final textColor = isOccupied
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer;

            return Card(
              color: cardColor,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => handleTableTap(table),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isOccupied
                          ? Icons.people_alt_outlined
                          : Icons.table_restaurant_outlined,
                      size: 32,
                      color: textColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      table.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      UIStrings.capacity.replaceFirst(
                        '{value}',
                        table.capacity.toString(),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, st) => Center(child: Text('Error: ${e.toString()}')),
    );
  }
}
