// lib/providers/charge_tax_rule_provider.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/charge_tax_rule_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/restaurant_provider.dart';
import 'package:resto2/services/restaurant_service.dart';

enum ChargeTaxRuleActionStatus { initial, loading, success, error }

class ChargeTaxRuleState {
  final ChargeTaxRuleActionStatus status;
  final String? errorMessage;

  ChargeTaxRuleState({
    this.status = ChargeTaxRuleActionStatus.initial,
    this.errorMessage,
  });
}

// Provider to get a stream of all rules for the current restaurant
final chargeTaxRulesStreamProvider =
    StreamProvider.autoDispose<List<ChargeTaxRuleModel>>((ref) {
      final restaurantId = ref
          .watch(currentUserProvider)
          .asData
          ?.value
          ?.restaurantId;
      if (restaurantId == null) {
        return Stream.value([]);
      }
      return ref
          .watch(restaurantServiceProvider)
          .getChargeTaxRulesStream(restaurantId);
    });

// Provider for the controller that manages rule actions (add, update, delete)
final chargeTaxRuleControllerProvider =
    StateNotifierProvider.autoDispose<
      ChargeTaxRuleController,
      ChargeTaxRuleState
    >((ref) {
      return ChargeTaxRuleController(ref);
    });

class ChargeTaxRuleController extends StateNotifier<ChargeTaxRuleState> {
  final Ref _ref;
  ChargeTaxRuleController(this._ref) : super(ChargeTaxRuleState());

  Future<void> saveRule(ChargeTaxRuleModel rule) async {
    state = ChargeTaxRuleState(status: ChargeTaxRuleActionStatus.loading);
    final restaurantId = _ref
        .read(currentUserProvider)
        .asData
        ?.value
        ?.restaurantId;
    if (restaurantId == null) {
      state = ChargeTaxRuleState(
        status: ChargeTaxRuleActionStatus.error,
        errorMessage: 'User is not in a restaurant.',
      );
      return;
    }

    try {
      await _ref
          .read(restaurantServiceProvider)
          .saveChargeTaxRule(restaurantId, rule);
      state = ChargeTaxRuleState(status: ChargeTaxRuleActionStatus.success);
    } catch (e) {
      state = ChargeTaxRuleState(
        status: ChargeTaxRuleActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deleteRule(String ruleId) async {
    state = ChargeTaxRuleState(status: ChargeTaxRuleActionStatus.loading);
    final restaurantId = _ref
        .read(currentUserProvider)
        .asData
        ?.value
        ?.restaurantId;
    if (restaurantId == null) {
      state = ChargeTaxRuleState(
        status: ChargeTaxRuleActionStatus.error,
        errorMessage: 'User is not in a restaurant.',
      );
      return;
    }

    try {
      await _ref
          .read(restaurantServiceProvider)
          .deleteChargeTaxRule(restaurantId, ruleId);
      state = ChargeTaxRuleState(status: ChargeTaxRuleActionStatus.success);
    } catch (e) {
      state = ChargeTaxRuleState(
        status: ChargeTaxRuleActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
