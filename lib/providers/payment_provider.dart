// lib/providers/payment_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/models/payment_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/order_provider.dart';
import 'package:resto2/providers/table_provider.dart';
import 'package:resto2/services/payment_service.dart';
import 'package:uuid/uuid.dart';

// State & Status
enum PaymentStatus { initial, loading, success, error }

class PaymentState {
  final PaymentStatus status;
  final String? errorMessage;

  PaymentState({this.status = PaymentStatus.initial, this.errorMessage});
}

// Service Provider
final paymentServiceProvider = Provider((ref) => PaymentService());

// Controller Provider
final paymentControllerProvider =
    StateNotifierProvider.autoDispose<PaymentController, PaymentState>(
      (ref) => PaymentController(ref),
    );

// Controller
class PaymentController extends StateNotifier<PaymentState> {
  final Ref _ref;
  PaymentController(this._ref) : super(PaymentState());

  Future<void> finalizePayment({
    required OrderModel order,
    required double amountPaid,
    required PaymentMethod method,
    double? tip,
  }) async {
    state = PaymentState(status: PaymentStatus.loading);
    final user = _ref.read(currentUserProvider).asData?.value;

    if (user == null) {
      state = PaymentState(
        status: PaymentStatus.error,
        errorMessage: 'User not authenticated.',
      );
      return;
    }

    try {
      final newPayment = PaymentModel(
        id: const Uuid().v4(),
        restaurantId: order.restaurantId,
        orderId: order.id,
        staffId: user.uid,
        amount: amountPaid,
        tip: tip,
        paymentMethod: method,
        createdAt: Timestamp.now(),
      );

      // Use a batch write to ensure atomicity
      final batch = _ref.read(firestoreProvider).batch();

      // 1. Record the payment
      final paymentRef = _ref
          .read(firestoreProvider)
          .collection('payments')
          .doc();
      batch.set(paymentRef, newPayment.toJson());

      // 2. Update the order status to 'paid'
      final orderRef = _ref
          .read(firestoreProvider)
          .collection('orders')
          .doc(order.id);
      // THE FIX IS HERE: Set the final status to 'paid'
      batch.update(orderRef, {'status': OrderStatus.paid.name});

      // 3. Update the table status to 'not occupied'
      final tableRef = _ref
          .read(firestoreProvider)
          .collection('tables')
          .doc(order.tableId);
      batch.update(tableRef, {'isOccupied': false});

      // Commit all changes at once
      await batch.commit();

      state = PaymentState(status: PaymentStatus.success);
    } catch (e) {
      state = PaymentState(
        status: PaymentStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
