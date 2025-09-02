// lib/providers/kitchen_provider.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/kitchen_order_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/menu_provider.dart';
import 'package:resto2/providers/order_provider.dart';
import 'package:uuid/uuid.dart';

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

      // Watch the raw orders from the service
      final ordersStream = ref
          .watch(orderServiceProvider)
          .getActiveOrdersStream(restaurantId);
      // Get all menu items to look up preparation times
      final allMenus = ref.watch(menusStreamProvider).asData?.value ?? [];
      final menuMap = {for (var menu in allMenus) menu.id: menu};

      return ordersStream.map((orders) {
        return orders.map((order) {
          final kitchenItems = order.items.map((item) {
            final prepTime = menuMap[item.menuId]?.preparationTime ?? 0;
            return KitchenOrderItemModel.fromOrderItem(
              const Uuid().v4(),
              item,
              prepTime,
            );
          }).toList();
          return KitchenOrderModel.fromOrderModel(order, kitchenItems);
        }).toList();
      });
    });

enum KitchenActionStatus { initial, loading, success, error }

class KitchenState {
  final KitchenActionStatus status;
  final String? errorMessage;

  KitchenState({this.status = KitchenActionStatus.initial, this.errorMessage});
}

final kitchenControllerProvider =
    StateNotifierProvider.autoDispose<KitchenController, KitchenState>((ref) {
      return KitchenController(ref);
    });

class KitchenController extends StateNotifier<KitchenState> {
  final Ref _ref;
  KitchenController(this._ref) : super(KitchenState());

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    state = KitchenState(status: KitchenActionStatus.loading);
    try {
      await _ref
          .read(orderServiceProvider)
          .updateOrderStatus(orderId, newStatus);

      // THE FIX: Check if the controller is still mounted before updating state.
      if (!mounted) return;

      state = KitchenState(status: KitchenActionStatus.success);
    } catch (e) {
      // THE FIX: Also check here in case of an error.
      if (!mounted) return;

      state = KitchenState(
        status: KitchenActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
