// lib/services/order_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resto2/models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionPath = 'orders';

  Future<void> createOrder(OrderModel order) {
    final itemsWithIds = order.items.map((item) {
      return OrderItemModel(
        id: item.id,
        menuId: item.menuId,
        menuName: item.menuName,
        quantity: item.quantity,
        price: item.price,
        itemTax: item.itemTax,
        status: item.status,
      );
    }).toList();
    final newOrder = OrderModel(
      id: order.id,
      restaurantId: order.restaurantId,
      tableId: order.tableId,
      tableName: order.tableName,
      orderTypeId: order.orderTypeId,
      orderTypeName: order.orderTypeName,
      staffId: order.staffId,
      staffName: order.staffName,
      items: itemsWithIds,
      subtotal: order.subtotal,
      serviceCharge: order.serviceCharge,
      itemSpecificTaxes: order.itemSpecificTaxes,
      grandTotal: order.grandTotal,
      createdAt: order.createdAt,
    );

    return _db.collection(_collectionPath).add(newOrder.toJson());
  }

  Future<OrderModel?> getActiveOrderByTableId({
    required String restaurantId,
    required String tableId,
  }) async {
    final query = await _db
        .collection(_collectionPath)
        .where('restaurantId', isEqualTo: restaurantId)
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

  Stream<List<OrderModel>> getActiveOrdersStream(String restaurantId) {
    return _db
        .collection(_collectionPath)
        .where('restaurantId', isEqualTo: restaurantId)
        .where(
          'status',
          whereIn: [
            OrderStatus.pending.name,
            OrderStatus.preparing.name,
            OrderStatus.ready.name,
          ],
        )
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) {
    return _db.collection(_collectionPath).doc(orderId).update({
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOrderItemStatus({
    required String orderId,
    required String itemId,
    required OrderItemStatus newStatus,
  }) async {
    final orderRef = _db.collection(_collectionPath).doc(orderId);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);
      if (!snapshot.exists) {
        throw Exception("Order does not exist!");
      }

      final order = OrderModel.fromFirestore(snapshot);
      final updatedItems = order.items.map((item) {
        if (item.id == itemId) {
          return OrderItemModel(
            id: item.id,
            menuId: item.menuId,
            menuName: item.menuName,
            quantity: item.quantity,
            price: item.price,
            itemTax: item.itemTax,
            status: newStatus,
          );
        }
        return item;
      }).toList();

      // THE FIX IS HERE: The overall status logic is now corrected.
      final allItemsServed = updatedItems.every(
        (item) => item.status == OrderItemStatus.served,
      );

      OrderStatus newOverallStatus = order.status;

      if (allItemsServed) {
        // Only complete the order when every single item is served.
        newOverallStatus = OrderStatus.completed;
      } else {
        // Otherwise, determine if it's ready, preparing, or still pending.
        final allItemsReadyOrServed = updatedItems.every(
          (item) =>
              item.status == OrderItemStatus.ready ||
              item.status == OrderItemStatus.served,
        );
        final anyItemPreparing = updatedItems.any(
          (item) => item.status == OrderItemStatus.preparing,
        );

        if (allItemsReadyOrServed) {
          newOverallStatus = OrderStatus.ready;
        } else if (anyItemPreparing) {
          newOverallStatus = OrderStatus.preparing;
        } else {
          newOverallStatus = OrderStatus.pending;
        }
      }

      transaction.update(orderRef, {
        'items': updatedItems.map((item) => item.toJson()).toList(),
        'status': newOverallStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
