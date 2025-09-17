// lib/views/order/widgets/order_confirmation_dialog.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/charge_tax_rule_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/models/order_type_model.dart';
import 'package:resto2/providers/charge_tax_rule_provider.dart';
import 'package:resto2/utils/constants.dart';

class OrderConfirmationDialog extends ConsumerWidget {
  final List<OrderItemModel> items;
  final OrderType orderType;
  final String? orderNote;
  final VoidCallback onSubmit;
  final bool isLoading;

  const OrderConfirmationDialog({
    super.key,
    required this.items,
    required this.orderType,
    this.orderNote,
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
        chargeWidgets.add(
          _buildChargeRow(
            '${UIStrings.serviceChargePrefix}${rule.name}',
            amount,
          ),
        );
      }
    }

    double totalGeneralTax = 0.0;
    final taxRules = rules.where((r) => r.ruleType == RuleType.tax).toList();
    for (var rule in taxRules) {
      if (_isRuleApplicable(rule, subtotal, orderType.id)) {
        final baseAmountForTax = subtotal;
        final amount = _calculateRuleAmount(rule, baseAmountForTax);
        totalGeneralTax += amount;
        chargeWidgets.add(
          _buildChargeRow('${UIStrings.taxPrefix}${rule.name}', amount),
        );
      }
    }

    if (itemSpecificTaxes > 0) {
      chargeWidgets.add(
        _buildChargeRow(UIStrings.itemSpecificTaxes, itemSpecificTaxes),
      );
    }

    final grandTotal =
        subtotal + totalServiceCharge + itemSpecificTaxes + totalGeneralTax;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text(UIStrings.confirmOrder),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (orderNote != null && orderNote!.isNotEmpty) ...[
                Text(UIStrings.orderNote, style: theme.textTheme.titleSmall),
                Text(orderNote!),
                const Divider(height: 24),
              ],
              ...items.map((item) {
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
                            if (item.note != null && item.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${UIStrings.orderNotePrefix}${item.note}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
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
              }),
              const Divider(height: 24),
              _buildChargeRow(UIStrings.subtotal, subtotal),
              ...chargeWidgets,
              const Divider(height: 16),
              _buildChargeRow(
                UIStrings.grandTotal,
                grandTotal,
                isBold: true,
                isTotal: true,
              ),
            ],
          ),
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
                  : const Text(UIStrings.submit),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text(UIStrings.cancel),
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
