// lib/models/charge_tax_rule_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum RuleType { serviceCharge, tax }

enum ValueType { percentage, fixed }

enum ConditionType { none, equalTo, between, lessThan, moreThan }

class ChargeTaxRuleModel {
  final String id;
  final String name;
  final RuleType ruleType;
  final ValueType valueType;
  final double value;
  final ConditionType conditionType;
  final double conditionValue1;
  final double? conditionValue2; // Used for 'between'
  final List<String> applyToOrderTypeIds; // Empty list means all

  ChargeTaxRuleModel({
    required this.id,
    required this.name,
    required this.ruleType,
    required this.valueType,
    required this.value,
    this.conditionType = ConditionType.none,
    this.conditionValue1 = 0.0,
    this.conditionValue2,
    this.applyToOrderTypeIds = const [],
  });

  factory ChargeTaxRuleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChargeTaxRuleModel(
      id: doc.id,
      name: data['name'] ?? '',
      ruleType: RuleType.values.firstWhere(
        (e) => e.name == data['ruleType'],
        orElse: () => RuleType.tax,
      ),
      valueType: ValueType.values.firstWhere(
        (e) => e.name == data['valueType'],
        orElse: () => ValueType.percentage,
      ),
      value: (data['value'] ?? 0.0).toDouble(),
      conditionType: ConditionType.values.firstWhere(
        (e) => e.name == data['conditionType'],
        orElse: () => ConditionType.none,
      ),
      conditionValue1: (data['conditionValue1'] ?? 0.0).toDouble(),
      conditionValue2: (data['conditionValue2'] as num?)?.toDouble(),
      applyToOrderTypeIds: List<String>.from(data['applyToOrderTypeIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ruleType': ruleType.name,
      'valueType': valueType.name,
      'value': value,
      'conditionType': conditionType.name,
      'conditionValue1': conditionValue1,
      'conditionValue2': conditionValue2,
      'applyToOrderTypeIds': applyToOrderTypeIds,
    };
  }
}
