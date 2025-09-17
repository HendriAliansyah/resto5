// lib/views/restaurant/charges_and_taxes_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/charge_tax_rule_model.dart';
import 'package:resto2/providers/charge_tax_rule_provider.dart';
import 'package:resto2/views/restaurant/widgets/charge_tax_rule_dialog.dart';
import 'package:resto2/views/widgets/app_drawer.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';
import 'package:resto2/utils/constants.dart';

class ChargesAndTaxesPage extends ConsumerWidget {
  const ChargesAndTaxesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(chargeTaxRulesStreamProvider);

    void showRuleDialog({ChargeTaxRuleModel? rule}) {
      showDialog(
        context: context,
        builder: (_) => ChargeTaxRuleDialog(rule: rule),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(UIStrings.chargesAndTaxes)),
      drawer: const AppDrawer(),
      body: rulesAsync.when(
        data: (rules) {
          final serviceCharges = rules
              .where((r) => r.ruleType == RuleType.serviceCharge)
              .toList();
          final taxes = rules.where((r) => r.ruleType == RuleType.tax).toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _RuleSection(
                title: UIStrings.serviceCharges,
                rules: serviceCharges,
                onAdd: () => showRuleDialog(rule: null),
                onTap: (rule) => showRuleDialog(rule: rule),
              ),
              const Divider(height: 32),
              _RuleSection(
                title: UIStrings.taxes,
                rules: taxes,
                onAdd: () => showRuleDialog(rule: null),
                onTap: (rule) => showRuleDialog(rule: rule),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, st) => Center(child: Text('Error: ${e.toString()}')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showRuleDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  final String title;
  final List<ChargeTaxRuleModel> rules;
  final VoidCallback onAdd;
  final ValueChanged<ChargeTaxRuleModel> onTap;

  const _RuleSection({
    required this.title,
    required this.rules,
    required this.onAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (rules.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: Text(UIStrings.noRulesDefined)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(rule.name),
                  subtitle: Text(_buildRuleSubtitle(rule)),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => onTap(rule),
                ),
              );
            },
          ),
      ],
    );
  }

  String _buildRuleSubtitle(ChargeTaxRuleModel rule) {
    final valueString = rule.valueType == ValueType.percentage
        ? '${rule.value}%'
        : '\$${rule.value.toStringAsFixed(2)}';
    String conditionString = '';
    switch (rule.conditionType) {
      case ConditionType.equalTo:
        conditionString = UIStrings.subtotalConditionEqual.replaceFirst(
          '{value}',
          rule.conditionValue1.toString(),
        );
        break;
      case ConditionType.between:
        conditionString = UIStrings.subtotalConditionBetween
            .replaceFirst('{from}', rule.conditionValue1.toString())
            .replaceFirst('{to}', rule.conditionValue2.toString());
        break;
      case ConditionType.lessThan:
        conditionString = UIStrings.subtotalConditionLessThan.replaceFirst(
          '{value}',
          rule.conditionValue1.toString(),
        );
        break;
      case ConditionType.moreThan:
        conditionString = UIStrings.subtotalConditionMoreThan.replaceFirst(
          '{value}',
          rule.conditionValue1.toString(),
        );
        break;
      case ConditionType.none:
        break;
    }
    return '$valueString$conditionString';
  }
}
