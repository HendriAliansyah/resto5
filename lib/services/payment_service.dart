// lib/services/payment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resto2/models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionPath = 'payments';

  Future<void> recordPayment(PaymentModel payment) async {
    await _db.collection(_collectionPath).add(payment.toJson());
  }
}
