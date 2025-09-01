// lib/services/order_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resto2/models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionPath = 'orders';

  Future<void> createOrder(OrderModel order) async {
    await _db.collection(_collectionPath).add(order.toJson());
  }

  Future<OrderModel?> getActiveOrderByTableId({
    required String restaurantId,
    required String tableId,
  }) async {
    final query = await _db
        .collection(_collectionPath)
        .where('restaurantId', isEqualTo: restaurantId) // This line is crucial
        .where('tableId', isEqualTo: tableId)
        .where(
          'status',
          whereIn: [
            OrderStatus.pending.name,
            OrderStatus.preparing.name,
            OrderStatus.ready.name,
          ],
        )
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return OrderModel.fromFirestore(query.docs.first);
    }
    return null;
  }
}
