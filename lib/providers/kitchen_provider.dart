// lib/providers/kitchen_provider.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/aggregated_kitchen_item_model.dart';
import 'package:resto2/models/kitchen_order_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/menu_provider.dart';
import 'package:resto2/providers/order_provider.dart';

final processingItemsProvider = StateProvider<Set<String>>((ref) => {});

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
            // THE FIX IS HERE: Ensure item notes are passed through
            return KitchenOrderItemModel.fromOrderItem(item, prepTime);
          }).toList();
          // THE FIX IS HERE: Pass the overall order note to the factory
          return KitchenOrderModel.fromOrderModel(order, kitchenItems);
        }).toList();
      });
    });

/// A new provider that transforms the active orders stream into a list of
/// aggregated items that are ready to be cooked.
final aggregatedItemsProvider =
    Provider.autoDispose<List<AggregatedKitchenItem>>((ref) {
      // Watch the original stream of orders
      final activeOrders =
          ref.watch(activeOrdersStreamProvider).asData?.value ?? [];

      // Use a map to aggregate items by their menuId
      final Map<String, AggregatedKitchenItem> itemMap = {};

      // Loop through each order
      for (final order in activeOrders) {
        // Loop through each item in the order
        for (final item in order.items) {
          // We only want to aggregate items that are 'pending'
          if (item.status == OrderItemStatus.pending) {
            // If we've seen this menu item before, update it
            if (itemMap.containsKey(item.menuId)) {
              final existing = itemMap[item.menuId]!;
              itemMap[item.menuId] = AggregatedKitchenItem(
                menuId: existing.menuId,
                menuName: existing.menuName,
                totalQuantity: existing.totalQuantity + item.quantity,
                sources: [
                  ...existing.sources,
                  OrderItemSource(orderId: order.orderId, itemId: item.id),
                ],
              );
            } else {
              // Otherwise, add a new entry to the map
              itemMap[item.menuId] = AggregatedKitchenItem(
                menuId: item.menuId,
                menuName: item.menuName,
                totalQuantity: item.quantity,
                sources: [
                  OrderItemSource(orderId: order.orderId, itemId: item.id),
                ],
              );
            }
          }
        }
      }

      // Return the aggregated values from the map as a list, sorted by name
      return itemMap.values.toList()
        ..sort((a, b) => a.menuName.compareTo(b.menuName));
    });

// THE FIX: Changed from .autoDispose to a regular StateNotifierProvider
// This ties the controller's lifecycle to the page, not the widget.
final kitchenControllerProvider =
    StateNotifierProvider<KitchenController, AsyncValue<void>>((ref) {
      return KitchenController(ref);
    });

class KitchenController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  KitchenController(this._ref) : super(const AsyncData(null));

  /// Updates all items in a group to "Preparing" status in a single batch.
  Future<void> startPreparingAggregatedItems(
    AggregatedKitchenItem aggregatedItem,
  ) async {
    state = const AsyncLoading();
    final user = _ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      if (mounted) {
        state = AsyncError(Exception("User not found"), StackTrace.current);
      }
      return;
    }

    try {
      // Use the batch update method from OrderService for efficiency
      await _ref
          .read(orderServiceProvider)
          .batchUpdateOrderItemStatus(
            sources: aggregatedItem.sources,
            newStatus: OrderItemStatus.preparing,
            userId: user.uid,
            userDisplayName: user.displayName ?? 'Unknown',
          );

      if (mounted) {
        state = const AsyncData(null);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> updateOrderItemStatus({
    required String orderId,
    required String itemId,
    required OrderItemStatus newStatus,
  }) async {
    final processingNotifier = _ref.read(processingItemsProvider.notifier);
    final itemKey = '$orderId-$itemId';

    state = const AsyncLoading();
    processingNotifier.update((state) => {...state, itemKey});

    try {
      final user = _ref.read(currentUserProvider).asData?.value;
      if (user == null) throw Exception("User not found");

      await _ref
          .read(orderServiceProvider)
          .updateOrderItemStatus(
            orderId: orderId,
            itemId: itemId,
            newStatus: newStatus,
            userId: user.uid,
            userDisplayName: user.displayName ?? 'Unknown',
          );
      if (mounted) {
        state = const AsyncData(null);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncError(e, st);
      }
    } finally {
      if (mounted) {
        processingNotifier.update((state) => state..remove(itemKey));
      }
    }
  }

  Future<void> resetOrderItemStatus({
    required String orderId,
    required String itemId,
    required bool wasWasted,
  }) async {
    final processingNotifier = _ref.read(processingItemsProvider.notifier);
    final itemKey = '$orderId-$itemId';

    state = const AsyncLoading();
    processingNotifier.update((state) => {...state, itemKey});

    try {
      final user = _ref.read(currentUserProvider).asData?.value;
      if (user == null) throw Exception("User not found");

      await _ref
          .read(orderServiceProvider)
          .resetOrderItem(
            orderId: orderId,
            itemId: itemId,
            wasWasted: wasWasted,
            userId: user.uid,
            userDisplayName: user.displayName ?? 'Unknown',
          );
      if (mounted) {
        state = const AsyncData(null);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncError(e, st);
      }
    } finally {
      if (mounted) {
        processingNotifier.update((state) => state..remove(itemKey));
      }
    }
  }
}
