// lib/views/kitchen/kitchen_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/kitchen_order_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/providers/kitchen_provider.dart';
import 'package:resto2/views/kitchen/widgets/order_ticket.dart';
import 'package:resto2/views/widgets/app_drawer.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';

class KitchenPage extends ConsumerWidget {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrdersAsync = ref.watch(activeOrdersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kitchen Display System')),
      drawer: const AppDrawer(),
      body: activeOrdersAsync.when(
        data: (orders) {
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
            // THE FIX IS HERE: The "Ready" column now includes both ready AND served items.
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
                        title: 'New',
                        orders: newOrders,
                        showTitle: true,
                      ),
                    ),
                    Expanded(
                      child: _OrderColumn(
                        title: 'Preparing',
                        orders: preparingOrders,
                        showTitle: true,
                      ),
                    ),
                    Expanded(
                      child: _OrderColumn(
                        title: 'Ready',
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
                          Tab(text: 'New (${newOrders.length})'),
                          Tab(text: 'Preparing (${preparingOrders.length})'),
                          Tab(text: 'Ready (${readyOrders.length})'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _OrderColumn(title: 'New', orders: newOrders),
                            _OrderColumn(
                              title: 'Preparing',
                              orders: preparingOrders,
                            ),
                            _OrderColumn(title: 'Ready', orders: readyOrders),
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
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
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
                ? const Center(child: Text('No orders in this stage.'))
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
