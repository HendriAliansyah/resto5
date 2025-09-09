// lib/providers/kitchen_provider.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
            return KitchenOrderItemModel.fromOrderItem(item, prepTime);
          }).toList();
          return KitchenOrderModel.fromOrderModel(order, kitchenItems);
        }).toList();
      });
    });

final kitchenControllerProvider =
    StateNotifierProvider.autoDispose<KitchenController, AsyncValue<void>>((
      ref,
    ) {
      return KitchenController(ref);
    });

class KitchenController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  KitchenController(this._ref) : super(const AsyncData(null));

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
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      processingNotifier.update((state) => state..remove(itemKey));
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

      // THE FIX IS HERE: This now calls the new, dedicated reset method
      // in the OrderService, which contains the stock return logic.
      await _ref
          .read(orderServiceProvider)
          .resetOrderItem(
            orderId: orderId,
            itemId: itemId,
            wasWasted: wasWasted,
            userId: user.uid,
            userDisplayName: user.displayName ?? 'Unknown',
          );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      processingNotifier.update((state) => state..remove(itemKey));
    }
  }
}
