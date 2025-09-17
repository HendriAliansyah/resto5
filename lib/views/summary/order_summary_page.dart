// lib/views/summary/order_summary_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/providers/order_provider.dart';
import 'package:resto2/providers/order_summary_filter_provider.dart';
import 'package:resto2/utils/constants.dart';
import 'package:resto2/views/widgets/app_drawer.dart';
import 'package:resto2/views/widgets/custom_app_bar.dart';
import 'package:resto2/views/widgets/filter_expansion_tile.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';
import 'package:resto2/views/widgets/sort_order_toggle.dart';

class OrderSummaryPage extends ConsumerWidget {
  const OrderSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(completedOrdersStreamProvider);
    final filterState = ref.watch(orderSummaryFilterProvider);
    final filterNotifier = ref.read(orderSummaryFilterProvider.notifier);
    final filteredOrders = ref.watch(sortedAndFilteredOrdersProvider);

    Future<void> selectDateRange(BuildContext context) async {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        initialDateRange: filterState.dateRange,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      );
      if (picked != null) {
        filterNotifier.setDateRange(picked);
      }
    }

    final double totalSales = filteredOrders.fold(
      0.0,
      (sum, order) => sum + order.grandTotal,
    );

    return Scaffold(
      appBar: const CustomAppBar(title: Text(UIStrings.orderAndPaymentSummary)),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          FilterExpansionTile(
            children: [
              DropdownButtonFormField2<OrderStatus?>(
                value: filterState.status,
                decoration: const InputDecoration(
                  labelText: UIStrings.filterByStatus,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.zero,
                ),
                buttonStyleData: const ButtonStyleData(
                  height: 50,
                  padding: EdgeInsets.only(right: 10),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(UIStrings.allStatuses),
                  ),
                  ...OrderStatus.values.map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.name),
                    ),
                  ),
                ],
                onChanged: (status) => filterNotifier.setStatusFilter(status),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField2<OrderSortOption>(
                      value: filterState.sortOption,
                      decoration: const InputDecoration(
                        labelText: UIStrings.sortBy,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.zero,
                      ),
                      buttonStyleData: const ButtonStyleData(
                        height: 50,
                        padding: EdgeInsets.only(right: 10),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: OrderSortOption.byDate,
                          child: Text(UIStrings.date),
                        ),
                        DropdownMenuItem(
                          value: OrderSortOption.byTotal,
                          child: Text(UIStrings.totalFilter),
                        ),
                      ],
                      onChanged: (option) {
                        if (option != null) {
                          filterNotifier.setSortOption(option);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  SortOrderToggle(
                    currentOrder: filterState.sortOrder,
                    onOrderChanged: (order) =>
                        filterNotifier.setSortOrder(order),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => selectDateRange(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: UIStrings.dateRange,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        filterState.dateRange == null
                            ? UIStrings.allTime
                            : '${DateFormat.yMd().format(filterState.dateRange!.start)} - ${DateFormat.yMd().format(filterState.dateRange!.end)}',
                      ),
                      if (filterState.dateRange != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => filterNotifier.setDateRange(null),
                        )
                      else
                        const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (filteredOrders.isEmpty) {
                  return const Center(
                    child: Text(UIStrings.noOrdersForCriteria),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: ListTile(
                        onTap: () =>
                            context.push(AppRoutes.orderDetail, extra: order),
                        title: Text(
                          UIStrings.orderId.replaceFirst(
                            '{id}',
                            order.id.substring(0, 8),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          UIStrings.tableLabel.replaceFirst(
                                '{name}',
                                order.tableName,
                              ) +
                              UIStrings.timeLabel.replaceFirst(
                                '{time}',
                                DateFormat.yMd().add_jm().format(
                                  order.createdAt.toDate(),
                                ),
                              ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${order.grandTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              order.status.name,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  UIStrings.totalSales,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '\$${totalSales.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
