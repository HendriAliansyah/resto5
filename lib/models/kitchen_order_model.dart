// lib/models/kitchen_order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resto2/models/order_model.dart';

class KitchenOrderItemModel {
  final String id;
  final String menuId;
  final String menuName;
  final int quantity;
  final int preparationTime;
  final OrderItemStatus status;

  KitchenOrderItemModel({
    required this.id,
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.preparationTime,
    required this.status,
  });

  factory KitchenOrderItemModel.fromOrderItem(
    OrderItemModel item,
    int prepTime,
  ) {
    return KitchenOrderItemModel(
      id: item.id,
      menuId: item.menuId,
      menuName: item.menuName,
      quantity: item.quantity,
      preparationTime: prepTime,
      status: item.status,
    );
  }
}

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

  // THE FIX IS HERE: The missing copyWith method is added.
  KitchenOrderModel copyWith({
    String? orderId,
    String? tableName,
    String? orderTypeName,
    Timestamp? createdAt,
    List<KitchenOrderItemModel>? items,
    OrderStatus? overallStatus,
  }) {
    return KitchenOrderModel(
      orderId: orderId ?? this.orderId,
      tableName: tableName ?? this.tableName,
      orderTypeName: orderTypeName ?? this.orderTypeName,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      overallStatus: overallStatus ?? this.overallStatus,
    );
  }
}
