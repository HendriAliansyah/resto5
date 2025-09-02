// lib/models/kitchen_order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resto2/models/order_model.dart';

enum KitchenOrderItemStatus { pending, preparing, ready }

// A model representing a single item within a kitchen order, with its own status.
class KitchenOrderItemModel {
  final String id; // Unique ID for this specific line item in the order
  final String menuId;
  final String menuName;
  final int quantity;
  final int preparationTime; // in minutes
  final KitchenOrderItemStatus status;

  KitchenOrderItemModel({
    required this.id,
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.preparationTime,
    this.status = KitchenOrderItemStatus.pending,
  });

  factory KitchenOrderItemModel.fromOrderItem(
    String id,
    OrderItemModel item,
    int prepTime,
  ) {
    return KitchenOrderItemModel(
      id: id,
      menuId: item.menuId,
      menuName: item.menuName,
      quantity: item.quantity,
      preparationTime: prepTime,
    );
  }
}

// The main model for an order as it appears on the KDS.
class KitchenOrderModel {
  final String orderId;
  final String tableName;
  final String orderTypeName;
  final Timestamp createdAt;
  final List<KitchenOrderItemModel> items;
  final OrderStatus overallStatus;

  KitchenOrderModel({
    required this.orderId,
    required this.tableName,
    required this.orderTypeName,
    required this.createdAt,
    required this.items,
    required this.overallStatus,
  });

  factory KitchenOrderModel.fromOrderModel(
    OrderModel order,
    List<KitchenOrderItemModel> kitchenItems,
  ) {
    return KitchenOrderModel(
      orderId: order.id,
      tableName: order.tableName,
      orderTypeName: order.orderTypeName,
      createdAt: order.createdAt,
      items: kitchenItems,
      overallStatus: order.status,
    );
  }
}
