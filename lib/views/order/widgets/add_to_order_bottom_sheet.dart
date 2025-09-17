// lib/views/order/widgets/add_to_order_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/menu_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/providers/menu_provider.dart';
import 'package:resto2/providers/order_provider.dart';
import 'package:resto2/utils/snackbar.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';
import 'package:uuid/uuid.dart';
import 'package:resto2/utils/constants.dart';

class AddToOrderBottomSheet extends HookConsumerWidget {
  final OrderModel order;

  const AddToOrderBottomSheet({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newItems = useState<List<OrderItemModel>>([]);
    final orderState = ref.watch(orderControllerProvider);
    final isLoading = orderState.status == OrderActionStatus.loading;

    ref.listen<OrderState>(orderControllerProvider, (prev, next) {
      if (next.status == OrderActionStatus.success) {
        Navigator.of(context).pop(); // Close this bottom sheet
        showSnackBar(context, UIMessages.itemsAddedToOrder);
      }
      if (next.status == OrderActionStatus.error) {
        showSnackBar(
          context,
          next.errorMessage ?? UIMessages.errorOccurred,
          isError: true,
        );
      }
    });

    void handleAddItems() {
      if (newItems.value.isEmpty) {
        showSnackBar(context, UIMessages.pleaseSelectItemsToAdd, isError: true);
        return;
      }
      ref
          .read(orderControllerProvider.notifier)
          .addItemsToOrder(order: order, newItems: newItems.value);
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              UIStrings.addToOrderTitle.replaceFirst(
                '{tableName}',
                order.tableName,
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _MenuList(orderedItems: newItems)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: isLoading ? null : handleAddItems,
              child: isLoading
                  ? const LoadingIndicator()
                  : const Text(UIStrings.confirmAndAddItems),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Menu List Widget
class _MenuList extends HookConsumerWidget {
  final ValueNotifier<List<OrderItemModel>> orderedItems;

  const _MenuList({required this.orderedItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusAsync = ref.watch(menusStreamProvider);

    void updateQuantity(MenuModel item, int newQuantity) {
      final newList = List<OrderItemModel>.from(orderedItems.value);
      final index = newList.indexWhere((i) => i.menuId == item.id);

      if (index != -1) {
        if (newQuantity <= 0) {
          newList.removeAt(index);
        } else {
          newList[index] = newList[index].copyWith(quantity: newQuantity);
        }
      } else if (newQuantity > 0) {
        final itemTax = item.isTaxFixed
            ? item.itemTaxPercentage
            : item.price * (item.itemTaxPercentage / 100);
        newList.add(
          OrderItemModel(
            id: const Uuid().v4(),
            menuId: item.id,
            menuName: item.name,
            quantity: newQuantity,
            price: item.price,
            itemTax: itemTax,
          ),
        );
      }
      orderedItems.value = newList;
    }

    return menusAsync.when(
      data: (menus) => ListView.builder(
        itemCount: menus.length,
        itemBuilder: (context, index) {
          final menu = menus[index];
          final currentQuantity = orderedItems.value
              .firstWhere(
                (item) => item.menuId == menu.id,
                orElse: () => OrderItemModel(
                  id: '',
                  menuId: '',
                  menuName: '',
                  quantity: 0,
                  price: 0,
                ),
              )
              .quantity;

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
                Text(currentQuantity.toString()),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => updateQuantity(menu, currentQuantity + 1),
                ),
              ],
            ),
          );
        },
      ),
      loading: () => const LoadingIndicator(),
      error: (e, st) => Center(child: Text('Error: ${e.toString()}')),
    );
  }
}
