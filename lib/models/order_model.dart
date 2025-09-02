// lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, preparing, ready, completed, cancelled }

class OrderItemModel {
  final String menuId;
  final String menuName;
  final int quantity;
  final double price;
  final double itemTax; // Added to store calculated tax for this item line

  OrderItemModel({
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.price,
    this.itemTax = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'menuId': menuId,
      'menuName': menuName,
      'quantity': quantity,
      'price': price,
      'itemTax': itemTax,
    };
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      menuId: json['menuId'],
      menuName: json['menuName'],
      quantity: json['quantity'],
      price: (json['price'] ?? 0.0).toDouble(),
      itemTax: (json['itemTax'] ?? 0.0).toDouble(),
    );
  }
}

class OrderModel {
  final String id;
  final String restaurantId;
  final String tableId;
  final String tableName;
  final String orderTypeId;
  final String orderTypeName;
  final String staffId;
  final String staffName;
  final List<OrderItemModel> items;
  final double subtotal;
  final double serviceCharge;
  final double itemSpecificTaxes; // Sum of all item-specific taxes
  final double grandTotal;
  final OrderStatus status;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  OrderModel({
    required this.id,
    required this.restaurantId,
    required this.tableId,
    required this.tableName,
    required this.orderTypeId,
    required this.orderTypeName,
    required this.staffId,
    required this.staffName,
    required this.items,
    required this.subtotal,
    required this.serviceCharge,
    required this.itemSpecificTaxes,
    required this.grandTotal,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'tableId': tableId,
      'tableName': tableName,
      'orderTypeId': orderTypeId,
      'orderTypeName': orderTypeName,
      'staffId': staffId,
      'staffName': staffName,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'serviceCharge': serviceCharge,
      'itemSpecificTaxes': itemSpecificTaxes,
      'grandTotal': grandTotal,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      restaurantId: data['restaurantId'],
      tableId: data['tableId'],
      tableName: data['tableName'],
      orderTypeId: data['orderTypeId'],
      orderTypeName: data['orderTypeName'],
      staffId: data['staffId'],
      staffName: data['staffName'],
      items: (data['items'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      serviceCharge: (data['serviceCharge'] ?? 0.0).toDouble(),
      itemSpecificTaxes: (data['itemSpecificTaxes'] ?? 0.0).toDouble(),
      grandTotal: (data['grandTotal'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }
}
