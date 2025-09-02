// lib/views/order/widgets/order_confirmation_dialog.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/charge_tax_rule_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/models/order_type_model.dart';
import 'package:resto2/providers/charge_tax_rule_provider.dart';

class OrderConfirmationDialog extends ConsumerWidget {
  final List<OrderItemModel> items;
  final OrderType orderType;
  final VoidCallback onSubmit;
  final bool isLoading;

  const OrderConfirmationDialog({
    super.key,
    required this.items,
    required this.orderType,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rules = ref.watch(chargeTaxRulesStreamProvider).asData?.value ?? [];

    final subtotal = items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final itemSpecificTaxes = items.fold(
      0.0,
      (sum, item) => sum + item.itemTax,
    );

    final List<Widget> chargeWidgets = [];
    double totalServiceCharge = 0.0;
    final serviceChargeRules = rules
        .where((r) => r.ruleType == RuleType.serviceCharge)
        .toList();
    for (var rule in serviceChargeRules) {
      if (_isRuleApplicable(rule, subtotal, orderType.id)) {
        final amount = _calculateRuleAmount(rule, subtotal);
        totalServiceCharge += amount;
        chargeWidgets.add(_buildChargeRow('Service: ${rule.name}', amount));
      }
    }

    double totalGeneralTax = 0.0;
    final taxRules = rules.where((r) => r.ruleType == RuleType.tax).toList();
    for (var rule in taxRules) {
      if (_isRuleApplicable(rule, subtotal, orderType.id)) {
        final baseAmountForTax = rule.valueType == ValueType.percentage
            ? subtotal + totalServiceCharge
            : subtotal;
        final amount = _calculateRuleAmount(rule, baseAmountForTax);
        totalGeneralTax += amount;
        chargeWidgets.add(_buildChargeRow('Tax: ${rule.name}', amount));
      }
    }

    if (itemSpecificTaxes > 0) {
      chargeWidgets.add(
        _buildChargeRow('Item-Specific Taxes', itemSpecificTaxes),
      );
    }

    final grandTotal =
        subtotal + totalServiceCharge + itemSpecificTaxes + totalGeneralTax;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Confirm Order'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // This Flexible/Expanded structure is the definitive fix.
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.menuName,
                                style: theme.textTheme.bodyLarge,
                              ),
                              Text(
                                '${item.quantity} x \$${item.price.toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '\$${(item.quantity * item.price).toStringAsFixed(2)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 24),
            _buildChargeRow('Subtotal', subtotal),
            ...chargeWidgets,
            const Divider(height: 16),
            _buildChargeRow(
              'Grand Total',
              grandTotal,
              isBold: true,
              isTotal: true,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChargeRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
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
    return baseAmount * (rule.value / 100);
  }
}
