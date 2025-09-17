// lib/views/restaurant/widgets/charge_tax_rule_dialog.dart
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/charge_tax_rule_model.dart';
import 'package:resto2/models/order_type_model.dart';
import 'package:resto2/providers/charge_tax_rule_provider.dart';
import 'package:resto2/providers/order_type_provider.dart';
import 'package:resto2/utils/snackbar.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';
import 'package:resto2/views/widgets/multi_select_form_field.dart';
import 'package:uuid/uuid.dart';
import 'package:resto2/utils/constants.dart';

class ChargeTaxRuleDialog extends HookConsumerWidget {
  final ChargeTaxRuleModel? rule;
  const ChargeTaxRuleDialog({super.key, this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = rule != null;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final allOrderTypes =
        ref.watch(orderTypesStreamProvider).asData?.value ?? [];

    // Form state hooks
    final nameController = useTextEditingController(text: rule?.name);
    final ruleType = useState(rule?.ruleType ?? RuleType.tax);
    final valueType = useState(rule?.valueType ?? ValueType.percentage);
    final valueController = useTextEditingController(
      text: rule?.value.toString(),
    );
    final conditionType = useState(rule?.conditionType ?? ConditionType.none);
    final conditionValue1Controller = useTextEditingController(
      text: rule?.conditionValue1.toString(),
    );
    final conditionValue2Controller = useTextEditingController(
      text: rule?.conditionValue2.toString(),
    );
    final selectedOrderTypeIds = useState(rule?.applyToOrderTypeIds ?? []);

    final isLoading =
        ref.watch(chargeTaxRuleControllerProvider).status ==
        ChargeTaxRuleActionStatus.loading;

    ref.listen<ChargeTaxRuleState>(chargeTaxRuleControllerProvider, (
      prev,
      next,
    ) {
      if (next.status == ChargeTaxRuleActionStatus.success) {
        if (context.mounted) Navigator.of(context).pop();
        showSnackBar(context, UIMessages.ruleSaved);
      }
      if (next.status == ChargeTaxRuleActionStatus.error) {
        showSnackBar(
          context,
          next.errorMessage ?? UIMessages.errorOccurred,
          isError: true,
        );
      }
    });

    void handleSubmit() {
      if (formKey.currentState?.validate() ?? false) {
        final newRule = ChargeTaxRuleModel(
          id: rule?.id ?? const Uuid().v4(),
          name: nameController.text,
          ruleType: ruleType.value,
          valueType: valueType.value,
          value: double.tryParse(valueController.text) ?? 0.0,
          conditionType: conditionType.value,
          conditionValue1:
              double.tryParse(conditionValue1Controller.text) ?? 0.0,
          conditionValue2: double.tryParse(conditionValue2Controller.text),
          applyToOrderTypeIds: selectedOrderTypeIds.value,
        );
        ref.read(chargeTaxRuleControllerProvider.notifier).saveRule(newRule);
      }
    }

    return AlertDialog(
      title: Text(isEditing ? UIStrings.editRule : UIStrings.addRule),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: UIStrings.ruleName,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? UIMessages.nameIsRequired : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField2<RuleType>(
                  value: ruleType.value,
                  onChanged: (v) => ruleType.value = v!,
                  decoration: const InputDecoration(
                    labelText: UIStrings.ruleType,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.zero,
                  ),
                  buttonStyleData: const ButtonStyleData(
                    height: 50,
                    padding: EdgeInsets.only(right: 10),
                  ),
                  items: RuleType.values
                      .map(
                        (rt) =>
                            DropdownMenuItem(value: rt, child: Text(rt.name)),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField2<ValueType>(
                  value: valueType.value,
                  onChanged: (v) => valueType.value = v!,
                  decoration: const InputDecoration(
                    labelText: UIStrings.valueType,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.zero,
                  ),
                  buttonStyleData: const ButtonStyleData(
                    height: 50,
                    padding: EdgeInsets.only(right: 10),
                  ),
                  items: ValueType.values
                      .map(
                        (vt) =>
                            DropdownMenuItem(value: vt, child: Text(vt.name)),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valueController,
                  decoration: const InputDecoration(
                    labelText: UIStrings.value,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) =>
                      v!.isEmpty ? UIMessages.valueIsRequired : null,
                ),
                const SizedBox(height: 16),
                MultiSelectBottomSheetField<OrderType>(
                  items: allOrderTypes,
                  initialValue: allOrderTypes
                      .where((ot) => selectedOrderTypeIds.value.contains(ot.id))
                      .toList(),
                  dialogTitle: UIStrings.applyToOrderTypes,
                  searchHint: UIStrings.searchOrderTypes,
                  chipLabelBuilder: (ot) => Text(ot.name),
                  tileLabelBuilder: (ot) => Text(ot.name),
                  onSaved: (selected) {
                    selectedOrderTypeIds.value =
                        selected?.map((ot) => ot.id).toList() ?? [];
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField2<ConditionType>(
                  value: conditionType.value,
                  onChanged: (v) => conditionType.value = v!,
                  decoration: const InputDecoration(
                    labelText: UIStrings.conditionOnSubtotal,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.zero,
                  ),
                  buttonStyleData: const ButtonStyleData(
                    height: 50,
                    padding: EdgeInsets.only(right: 10),
                  ),
                  items: ConditionType.values
                      .map(
                        (ct) =>
                            DropdownMenuItem(value: ct, child: Text(ct.name)),
                      )
                      .toList(),
                ),
                if (conditionType.value != ConditionType.none) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: conditionValue1Controller,
                    decoration: InputDecoration(
                      labelText: conditionType.value == ConditionType.between
                          ? UIStrings.fromValue
                          : UIStrings.valueAmount,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        v!.isEmpty ? UIMessages.conditionValueIsRequired : null,
                  ),
                ],
                if (conditionType.value == ConditionType.between) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: conditionValue2Controller,
                    decoration: const InputDecoration(
                      labelText: UIStrings.toValue,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        v!.isEmpty ? UIMessages.toValueIsRequired : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(UIStrings.cancel),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : handleSubmit,
          child: isLoading
              ? const LoadingIndicator()
              : const Text(UIStrings.saveRule),
        ),
      ],
    );
  }
}
