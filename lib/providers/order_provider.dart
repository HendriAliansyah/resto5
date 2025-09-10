// lib/providers/order_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/charge_tax_rule_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/models/table_model.dart';
import 'package:resto2/models/order_type_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/charge_tax_rule_provider.dart';
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
    String? orderNote, // ADDED
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

    if (items.isEmpty) {
      state = OrderState(
        status: OrderActionStatus.error,
        errorMessage: "Cannot place an empty order.",
      );
      return;
    }

    try {
      final subtotal = items.fold(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );
      double totalServiceCharge = 0.0;
      double totalItemTaxes = items.fold(
        0.0,
        (sum, item) => sum + item.itemTax,
      );

      // Apply service charges
      final serviceChargeRules = rules
          .where((r) => r.ruleType == RuleType.serviceCharge)
          .toList();
      for (var rule in serviceChargeRules) {
        if (_isRuleApplicable(rule, subtotal, orderType.id)) {
          totalServiceCharge += _calculateRuleAmount(rule, subtotal);
        }
      }

      // Apply general taxes
      double totalGeneralTax = 0.0;
      final taxRules = rules.where((r) => r.ruleType == RuleType.tax).toList();
      for (var rule in taxRules) {
        if (_isRuleApplicable(rule, subtotal, orderType.id)) {
          totalGeneralTax += _calculateRuleAmount(
            rule,
            subtotal + totalServiceCharge,
          );
        }
      }

      final grandTotal =
          subtotal + totalServiceCharge + totalItemTaxes + totalGeneralTax;

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
        subtotal: subtotal,
        serviceCharge: totalServiceCharge,
        itemSpecificTaxes: totalItemTaxes,
        grandTotal: grandTotal,
        createdAt: Timestamp.now(),
        note: orderNote, // ADDED
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

  bool _isRuleApplicable(
    ChargeTaxRuleModel rule,
    double subtotal,
    String orderTypeId,
  ) {
    if (rule.applyToOrderTypeIds.isNotEmpty &&
        !rule.applyToOrderTypeIds.contains(orderTypeId)) {
      return false;
    }
    switch (rule.conditionType) {
      case ConditionType.equalTo:
        return subtotal == rule.conditionValue1;
      case ConditionType.between:
        return subtotal >= rule.conditionValue1 &&
            subtotal <= (rule.conditionValue2 ?? double.infinity);
      case ConditionType.lessThan:
        return subtotal < rule.conditionValue1;
      case ConditionType.moreThan:
        return subtotal > rule.conditionValue1;
      case ConditionType.none:
        return true;
    }
  }

  double _calculateRuleAmount(ChargeTaxRuleModel rule, double baseAmount) {
    if (rule.valueType == ValueType.fixed) {
      return rule.value;
    }
    return baseAmount * (rule.value / 100);
  }
}
