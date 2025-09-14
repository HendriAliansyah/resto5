// lib/providers/order_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/models/table_model.dart';
import 'package:resto2/models/order_type_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/charge_tax_rule_provider.dart';
import 'package:resto2/providers/table_provider.dart';
import 'package:resto2/services/order_calculation_service.dart';
import 'package:resto2/services/order_service.dart';

// THE FIX IS HERE: The helper class is now correctly defined in this file.
class TableOrderArgs {
  final String tableId;
  final String restaurantId;
  TableOrderArgs({required this.tableId, required this.restaurantId});

  // Add equals and hashCode for the provider to correctly cache results.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableOrderArgs &&
          runtimeType == other.runtimeType &&
          tableId == other.tableId &&
          restaurantId == other.restaurantId;

  @override
  int get hashCode => tableId.hashCode ^ restaurantId.hashCode;
}

// Service Providers
final orderServiceProvider = Provider((ref) => OrderService());
final orderCalculationServiceProvider = Provider(
  (ref) => OrderCalculationService(),
);

// State & Status
enum OrderActionStatus { initial, loading, success, error }

class OrderState {
  final OrderActionStatus status;
  final String? errorMessage;

  OrderState({this.status = OrderActionStatus.initial, this.errorMessage});
}

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

// Controller
class OrderController extends StateNotifier<OrderState> {
  final Ref _ref;
  OrderController(this._ref) : super(OrderState());

  Future<void> placeOrder({
    required TableModel table,
    required OrderType orderType,
    required List<OrderItemModel> items,
    String? orderNote,
  }) async {
    state = OrderState(status: OrderActionStatus.loading);
    final user = _ref.read(currentUserProvider).asData?.value;
    final rules = _ref.read(chargeTaxRulesStreamProvider).asData?.value ?? [];

    if (user == null || user.restaurantId == null) {
      state = OrderState(
        status: OrderActionStatus.error,
        errorMessage: "User not authenticated or not in a restaurant.",
      );
      return;
    }

    try {
      // Use the calculation service
      final calcResult = _ref
          .read(orderCalculationServiceProvider)
          .calculateTotals(
            items: items,
            rules: rules,
            orderTypeId: orderType.id,
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
        subtotal: calcResult.subtotal,
        grandTotal: calcResult.grandTotal,
        appliedCharges: calcResult.appliedCharges,
        createdAt: Timestamp.now(),
        note: orderNote,
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

  // New method to add items and recalculate totals
  Future<void> addItemsToOrder({
    required OrderModel order,
    required List<OrderItemModel> newItems,
  }) async {
    state = OrderState(status: OrderActionStatus.loading);
    final rules = _ref.read(chargeTaxRulesStreamProvider).asData?.value ?? [];

    try {
      final combinedItems = List<OrderItemModel>.from(order.items)
        ..addAll(newItems);

      final calcResult = _ref
          .read(orderCalculationServiceProvider)
          .calculateTotals(
            items: combinedItems,
            rules: rules,
            orderTypeId: order.orderTypeId,
          );

      final updateData = {
        'items': combinedItems.map((item) => item.toJson()).toList(),
        'subtotal': calcResult.subtotal,
        'grandTotal': calcResult.grandTotal,
        'appliedCharges': calcResult.appliedCharges
            .map((c) => c.toJson())
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _ref.read(orderServiceProvider).updateOrder(order.id, updateData);

      state = OrderState(status: OrderActionStatus.success);
    } catch (e) {
      state = OrderState(
        status: OrderActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
