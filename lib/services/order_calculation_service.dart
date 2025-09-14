// lib/services/order_calculation_service.dart
import 'package:resto2/models/charge_tax_rule_model.dart';
import 'package:resto2/models/order_model.dart';

class CalculationResult {
  final double subtotal;
  final double grandTotal;
  final List<AppliedCharge> appliedCharges;

  CalculationResult({
    required this.subtotal,
    required this.grandTotal,
    required this.appliedCharges,
  });
}

class OrderCalculationService {
  CalculationResult calculateTotals({
    required List<OrderItemModel> items,
    required List<ChargeTaxRuleModel> rules,
    required String orderTypeId,
  }) {
    // 1. Calculate Subtotal and Item-Specific Taxes
    double subtotal = 0.0;
    double totalItemTaxes = 0.0;
    for (var item in items) {
      subtotal += item.price * item.quantity;
      totalItemTaxes += item.itemTax * item.quantity;
    }

    final List<AppliedCharge> appliedCharges = [];
    double totalServiceCharge = 0.0;
    double totalGeneralTax = 0.0;

    // Add item-specific taxes first if they exist
    if (totalItemTaxes > 0) {
      appliedCharges.add(
        AppliedCharge(name: 'Item-Specific Taxes', amount: totalItemTaxes),
      );
    }

    // 2. Apply Service Charges (based on subtotal)
    final serviceChargeRules = rules
        .where((r) => r.ruleType == RuleType.serviceCharge)
        .toList();
    for (var rule in serviceChargeRules) {
      if (_isRuleApplicable(rule, subtotal, orderTypeId)) {
        final amount = _calculateRuleAmount(rule, subtotal);
        totalServiceCharge += amount;
        appliedCharges.add(AppliedCharge(name: rule.name, amount: amount));
      }
    }

    // 3. Apply General Taxes (based on subtotal only)
    // THE FIX IS HERE: The base amount for tax is now correctly set to the subtotal.
    final taxBaseAmount = subtotal;
    final taxRules = rules.where((r) => r.ruleType == RuleType.tax).toList();
    for (var rule in taxRules) {
      if (_isRuleApplicable(rule, subtotal, orderTypeId)) {
        final amount = _calculateRuleAmount(rule, taxBaseAmount);
        totalGeneralTax += amount;
        appliedCharges.add(AppliedCharge(name: rule.name, amount: amount));
      }
    }

    // 4. Calculate Grand Total
    final grandTotal =
        subtotal + totalItemTaxes + totalServiceCharge + totalGeneralTax;

    return CalculationResult(
      subtotal: subtotal,
      grandTotal: grandTotal,
      appliedCharges: appliedCharges,
    );
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
    return (baseAmount * (rule.value / 100));
  }
}
