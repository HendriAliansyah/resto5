// lib/views/order/widgets/order_bottom_sheet.dart
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/menu_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/models/order_type_model.dart';
import 'package:resto2/models/table_model.dart';
import 'package:resto2/providers/course_provider.dart';
import 'package:resto2/providers/menu_filter_provider.dart';
import 'package:resto2/providers/menu_provider.dart';
import 'package:resto2/providers/order_provider.dart';
import 'package:resto2/providers/staff_filter_provider.dart';
import 'package:resto2/utils/snackbar.dart';
import 'package:resto2/views/order/widgets/order_confirmation_dialog.dart';
import 'package:resto2/views/widgets/filter_expansion_tile.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';
import 'package:resto2/views/widgets/sort_order_toggle.dart';

class OrderBottomSheet extends HookConsumerWidget {
  final TableModel table;
  final OrderType orderType;

  const OrderBottomSheet({
    super.key,
    required this.table,
    required this.orderType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderedItems = useState<Map<MenuModel, int>>({});
    final orderState = ref.watch(orderControllerProvider);
    final isLoading = orderState.status == OrderActionStatus.loading;

    ref.listen<OrderState>(orderControllerProvider, (prev, next) {
      if (next.status == OrderActionStatus.success) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        showSnackBar(context, 'Order placed successfully!');
      }
      if (next.status == OrderActionStatus.error) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        showSnackBar(
          context,
          next.errorMessage ?? 'An error occurred.',
          isError: true,
        );
      }
    });

    void handlePlaceOrder() {
      final items = orderedItems.value.entries.map((entry) {
        return OrderItemModel(
          menuId: entry.key.id,
          menuName: entry.key.name,
          quantity: entry.value,
          price: entry.key.price,
        );
      }).toList();

      ref
          .read(orderControllerProvider.notifier)
          .placeOrder(table: table, orderType: orderType, items: items);
    }

    void showConfirmationDialog() {
      final items = orderedItems.value.entries.map((entry) {
        return OrderItemModel(
          menuId: entry.key.id,
          menuName: entry.key.name,
          quantity: entry.value,
          price: entry.key.price,
        );
      }).toList();

      showDialog(
        context: context,
        builder: (_) => OrderConfirmationDialog(
          items: items,
          onSubmit: handlePlaceOrder,
          isLoading: isLoading,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'New Order: ${table.name} (${orderType.name})',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _MenuList(orderedItems: orderedItems)),
            if (orderedItems.value.isNotEmpty)
              _OrderSummary(
                orderedItems: orderedItems.value,
                onPlaceOrder: showConfirmationDialog,
                isLoading: isLoading,
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuList extends HookConsumerWidget {
  final ValueNotifier<Map<MenuModel, int>> orderedItems;

  const _MenuList({required this.orderedItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusAsync = ref.watch(menusStreamProvider);
    final coursesAsync = ref.watch(coursesStreamProvider);

    // Hooks for local state management of filters
    final searchQuery = useState('');
    final selectedCourseId = useState<String?>(null);
    final sortOption = useState(MenuSortOption.byName);
    final sortOrder = useState(SortOrder.asc);

    void updateQuantity(MenuModel item, int newQuantity) {
      final newMap = Map<MenuModel, int>.from(orderedItems.value);
      if (newQuantity <= 0) {
        newMap.remove(item);
      } else {
        newMap[item] = newQuantity;
      }
      orderedItems.value = newMap;
    }

    return menusAsync.when(
      data: (menus) {
        if (menus.isEmpty) {
          return const Center(child: Text('No menu items available.'));
        }

        final courses = coursesAsync.asData?.value ?? [];

        // Apply filtering
        final filteredMenus = menus.where((menu) {
          final searchMatch = menu.name.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          );
          final courseMatch =
              selectedCourseId.value == null ||
              menu.courseId == selectedCourseId.value;
          return searchMatch && courseMatch;
        }).toList();

        // Apply sorting
        filteredMenus.sort((a, b) {
          int comparison;
          switch (sortOption.value) {
            case MenuSortOption.byName:
              comparison = a.name.compareTo(b.name);
              break;
            case MenuSortOption.byPrice:
              comparison = a.price.compareTo(b.price);
              break;
          }
          return sortOrder.value == SortOrder.asc ? comparison : -comparison;
        });

        return Column(
          children: [
            FilterExpansionTile(
              title: 'Filter & Sort Menu',
              children: [
                TextField(
                  onChanged: (value) => searchQuery.value = value,
                  decoration: InputDecoration(
                    labelText: 'Search Menu',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField2<String?>(
                  value: selectedCourseId.value,
                  onChanged: (value) => selectedCourseId.value = value,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Course',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.zero,
                  ),
                  buttonStyleData: const ButtonStyleData(height: 50),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Courses'),
                    ),
                    ...courses.map(
                      (course) => DropdownMenuItem(
                        value: course.id,
                        child: Text(course.name),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField2<MenuSortOption>(
                        value: sortOption.value,
                        onChanged: (value) {
                          if (value != null) sortOption.value = value;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.zero,
                        ),
                        buttonStyleData: const ButtonStyleData(height: 50),
                        items: const [
                          DropdownMenuItem(
                            value: MenuSortOption.byName,
                            child: Text('Name'),
                          ),
                          DropdownMenuItem(
                            value: MenuSortOption.byPrice,
                            child: Text('Price'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SortOrderToggle(
                      currentOrder: sortOrder.value,
                      onOrderChanged: (order) => sortOrder.value = order,
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: filteredMenus.length,
                itemBuilder: (context, index) {
                  final menu = filteredMenus[index];
                  final currentQuantity = orderedItems.value[menu] ?? 0;

                  return ListTile(
                    title: Text(menu.name),
                    subtitle: Text('\$${menu.price.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: currentQuantity > 0
                              ? () => updateQuantity(menu, currentQuantity - 1)
                              : null,
                        ),
                        Text(
                          currentQuantity.toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () =>
                              updateQuantity(menu, currentQuantity + 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, st) => Center(child: Text('Error: ${e.toString()}')),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final Map<MenuModel, int> orderedItems;
  final VoidCallback onPlaceOrder;
  final bool isLoading;

  const _OrderSummary({
    required this.orderedItems,
    required this.onPlaceOrder,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = orderedItems.entries.fold(
      0.0,
      (sum, item) => sum + (item.key.price * item.value),
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: Theme.of(context).textTheme.titleLarge),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : onPlaceOrder,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : const Text('Place Order'),
          ),
        ],
      ),
    );
  }
}
