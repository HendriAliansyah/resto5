// lib/providers/kitchen_provider.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/kitchen_order_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/menu_provider.dart';
import 'package:resto2/providers/order_provider.dart';
import 'package:flutter/material.dart'; // Import for ScaffoldMessenger

// THE FIX IS HERE: New provider to track the IDs of items being processed.
final processingItemsProvider = StateProvider<Set<String>>((ref) => {});

// Provider to get a stream of all active orders for the kitchen
final activeOrdersStreamProvider =
    StreamProvider.autoDispose<List<KitchenOrderModel>>((ref) {
      final restaurantId = ref
          .watch(currentUserProvider)
          .asData
          ?.value
          ?.restaurantId;
      if (restaurantId == null) {
        return Stream.value([]);
      }

      final ordersStream = ref
          .watch(orderServiceProvider)
          .getActiveOrdersStream(restaurantId);
      final allMenus = ref.watch(menusStreamProvider).asData?.value ?? [];
      final menuMap = {for (var menu in allMenus) menu.id: menu};

      return ordersStream.map((orders) {
        return orders.map((order) {
          final kitchenItems = order.items.map((item) {
            final prepTime = menuMap[item.menuId]?.preparationTime ?? 0;
            return KitchenOrderItemModel.fromOrderItem(item, prepTime);
          }).toList();
          return KitchenOrderModel.fromOrderModel(order, kitchenItems);
        }).toList();
      });
    });

// THE FIX IS HERE: The controller is now a simple class, not a StateNotifier.
final kitchenControllerProvider = Provider.autoDispose((ref) {
  return KitchenController(ref);
});

class KitchenController {
  final Ref _ref;
  KitchenController(this._ref);

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final processingNotifier = _ref.read(processingItemsProvider.notifier);
    processingNotifier.update((state) => {...state, orderId});

    try {
      await _ref
          .read(orderServiceProvider)
          .updateOrderStatus(orderId, newStatus);
    } catch (e) {
      // You can handle errors here, e.g., by showing a SnackBar
      debugPrint("Error updating order status: $e");
    } finally {
      processingNotifier.update((state) => state..remove(orderId));
    }
  }

  Future<void> updateOrderItemStatus({
    required String orderId,
    required String itemId,
    required OrderItemStatus newStatus,
  }) async {
    final processingNotifier = _ref.read(processingItemsProvider.notifier);
    // Use a unique key for the item to track its state
    final itemKey = '$orderId-$itemId';
    processingNotifier.update((state) => {...state, itemKey});

    try {
      await _ref
          .read(orderServiceProvider)
          .updateOrderItemStatus(
            orderId: orderId,
            itemId: itemId,
            newStatus: newStatus,
          );
    } catch (e) {
      debugPrint("Error updating item status: $e");
    } finally {
      processingNotifier.update((state) => state..remove(itemKey));
    }
  }
}
