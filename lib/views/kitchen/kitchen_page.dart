// lib/views/kitchen/kitchen_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/kitchen_order_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/providers/kitchen_provider.dart';
import 'package:resto2/views/kitchen/widgets/order_ticket.dart';
import 'package:resto2/views/widgets/app_drawer.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';
import 'package:resto2/utils/constants.dart';

// Enum to manage the view state
enum KitchenView { orders, summary }

class KitchenPage extends HookConsumerWidget {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrdersAsync = ref.watch(activeOrdersStreamProvider);
    // Hook to manage the view state, defaulting to the orders view
    final currentView = useState(KitchenView.orders);

    return Scaffold(
      appBar: AppBar(
        title: const Text(UIStrings.kitchenDisplaySystem),
        actions: [
          // Toggle button to switch views
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SegmentedButton<KitchenView>(
              segments: const [
                ButtonSegment(
                  value: KitchenView.orders,
                  label: Text(UIStrings.orders),
                  icon: Icon(Icons.receipt_long_outlined),
                ),
                ButtonSegment(
                  value: KitchenView.summary,
                  label: Text(UIStrings.summary),
                  icon: Icon(Icons.view_list_outlined),
                ),
              ],
              selected: {currentView.value},
              onSelectionChanged: (newSelection) {
                currentView.value = newSelection.first;
              },
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: activeOrdersAsync.when(
        data: (orders) {
          // Conditional rendering based on the selected view
          if (currentView.value == KitchenView.summary) {
            return const _AggregatedView();
          }

          // --- EXISTING ORDER VIEW LOGIC ---
          final List<KitchenOrderModel> newOrders = [];
          final List<KitchenOrderModel> preparingOrders = [];
          final List<KitchenOrderModel> readyOrders = [];

          for (final order in orders) {
            final pendingItems = order.items
                .where((item) => item.status == OrderItemStatus.pending)
                .toList();
            final preparingItems = order.items
                .where((item) => item.status == OrderItemStatus.preparing)
                .toList();
            final readyAndServedItems = order.items
                .where(
                  (item) =>
                      item.status == OrderItemStatus.ready ||
                      item.status == OrderItemStatus.served,
                )
                .toList();

            if (pendingItems.isNotEmpty) {
              newOrders.add(order.copyWith(items: pendingItems));
            }
            if (preparingItems.isNotEmpty) {
              preparingOrders.add(order.copyWith(items: preparingItems));
            }
            if (readyAndServedItems.isNotEmpty) {
              readyOrders.add(order.copyWith(items: readyAndServedItems));
            }
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              const wideScreenBreakpoint = 600;
              final isWideScreen = constraints.maxWidth > wideScreenBreakpoint;

              if (isWideScreen) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _OrderColumn(
                        title: UIStrings.newOrders,
                        orders: newOrders,
                        showTitle: true,
                      ),
                    ),
                    Expanded(
                      child: _OrderColumn(
                        title: UIStrings.preparing,
                        orders: preparingOrders,
                        showTitle: true,
                      ),
                    ),
                    Expanded(
                      child: _OrderColumn(
                        title: UIStrings.ready,
                        orders: readyOrders,
                        showTitle: true,
                      ),
                    ),
                  ],
                );
              } else {
                return DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(
                            text:
                                '${UIStrings.newOrders} (${newOrders.length})',
                          ),
                          Tab(
                            text:
                                '${UIStrings.preparing} (${preparingOrders.length})',
                          ),
                          Tab(
                            text: '${UIStrings.ready} (${readyOrders.length})',
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _OrderColumn(
                              title: UIStrings.newOrders,
                              orders: newOrders,
                            ),
                            _OrderColumn(
                              title: UIStrings.preparing,
                              orders: preparingOrders,
                            ),
                            _OrderColumn(
                              title: UIStrings.ready,
                              orders: readyOrders,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, st) => Center(child: Text('Error: ${e.toString()}')),
      ),
    );
  }
}

/// A new widget to display the aggregated summary of pending items.
class _AggregatedView extends ConsumerWidget {
  const _AggregatedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregatedItems = ref.watch(aggregatedItemsProvider);
    final controller = ref.read(kitchenControllerProvider.notifier);
    final theme = Theme.of(context);

    if (aggregatedItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.grey, size: 60),
            SizedBox(height: 16),
            Text(UIStrings.allCaughtUp, style: TextStyle(fontSize: 20)),
            Text(UIStrings.noNewItems, style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: aggregatedItems.length,
      itemBuilder: (context, index) {
        final item = aggregatedItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${item.totalQuantity}x',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(item.menuName, style: theme.textTheme.titleLarge),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  // Override the theme's minimumSize for this specific button
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(150, 48),
                  ),
                  onPressed: () =>
                      controller.startPreparingAggregatedItems(item),
                  child: const Text(UIStrings.startPreparing),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderColumn extends StatelessWidget {
  final String title;
  final List<KitchenOrderModel> orders;
  final bool showTitle;

  const _OrderColumn({
    required this.title,
    required this.orders,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(128),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          if (showTitle)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                '$title (${orders.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          if (showTitle) const Divider(height: 1),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text(UIStrings.noOrdersInStage))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 8.0,
                    ),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return OrderTicket(order: orders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
