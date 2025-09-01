// lib/providers/order_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/models/table_model.dart';
import 'package:resto2/models/order_type_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/table_provider.dart';
import 'package:resto2/services/order_service.dart';

// Helper class to pass multiple arguments to the provider family
class TableOrderArgs {
  final String tableId;
  final String restaurantId;
  TableOrderArgs({required this.tableId, required this.restaurantId});
}

enum OrderActionStatus { initial, loading, success, error }

class OrderState {
  final OrderActionStatus status;
  final String? errorMessage;

  OrderState({this.status = OrderActionStatus.initial, this.errorMessage});
}

final orderServiceProvider = Provider((ref) => OrderService());

final activeOrderProvider = FutureProvider.autoDispose
    .family<OrderModel?, TableOrderArgs>((ref, args) {
      return ref
          .watch(orderServiceProvider)
          .getActiveOrderByTableId(
            restaurantId: args.restaurantId,
            tableId: args.tableId,
          );
    });

final orderControllerProvider =
    StateNotifierProvider.autoDispose<OrderController, OrderState>(
      (ref) => OrderController(ref),
    );

class OrderController extends StateNotifier<OrderState> {
  final Ref _ref;
  OrderController(this._ref) : super(OrderState());

  Future<void> placeOrder({
    required TableModel table,
    required OrderType orderType,
    required List<OrderItemModel> items,
  }) async {
    state = OrderState(status: OrderActionStatus.loading);
    final user = _ref.read(currentUserProvider).asData?.value;
    if (user == null || user.restaurantId == null) {
      state = OrderState(
        status: OrderActionStatus.error,
        errorMessage: "User not authenticated or not in a restaurant.",
      );
      return;
    }

    if (items.isEmpty) {
      state = OrderState(
        status: OrderActionStatus.error,
        errorMessage: "Cannot place an empty order.",
      );
      return;
    }

    try {
      final totalPrice = items.fold(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      final newOrder = OrderModel(
        id: '',
        restaurantId: user.restaurantId!,
        tableId: table.id,
        tableName: table.name,
        orderTypeId: orderType.id,
        orderTypeName: orderType.name,
        staffId: user.uid,
        staffName: user.displayName ?? 'Unknown',
        items: items,
        totalPrice: totalPrice,
        createdAt: Timestamp.now(),
      );

      await _ref.read(orderServiceProvider).createOrder(newOrder);
      await _ref.read(tableServiceProvider).updateTable(table.id, {
        'isOccupied': true,
      });

      state = OrderState(status: OrderActionStatus.success);
    } catch (e) {
      state = OrderState(
        status: OrderActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
