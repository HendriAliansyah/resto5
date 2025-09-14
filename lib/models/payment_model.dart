// lib/models/payment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { cash, card, other }

class PaymentModel {
  final String id;
  final String restaurantId;
  final String orderId;
  final String staffId;
  final double amount;
  final double? tip;
  final PaymentMethod paymentMethod;
  final Timestamp createdAt;

  PaymentModel({
    required this.id,
    required this.restaurantId,
    required this.orderId,
    required this.staffId,
    required this.amount,
    this.tip,
    required this.paymentMethod,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'orderId': orderId,
      'staffId': staffId,
      'amount': amount,
      'tip': tip,
      'paymentMethod': paymentMethod.name,
      'createdAt': createdAt,
    };
  }
}
