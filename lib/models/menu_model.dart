// lib/models/menu_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String restaurantId;
  final String courseId;
  final String orderTypeId;
  final List<String> menuItems;
  final List<String> inventoryItems;
  final int preparationTime;
  final double itemTaxPercentage;
  final bool isTaxFixed;

  MenuModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.restaurantId,
    required this.courseId,
    required this.orderTypeId,
    this.menuItems = const [],
    this.inventoryItems = const [],
    this.preparationTime = 0,
    this.itemTaxPercentage = 0.0,
    this.isTaxFixed = false,
  });

  factory MenuModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      restaurantId: data['restaurantId'] ?? '',
      courseId: data['courseId'] ?? '',
      orderTypeId: data['orderTypeId'] ?? '',
      menuItems: List<String>.from(data['menuItems'] ?? []),
      inventoryItems: List<String>.from(data['inventoryItems'] ?? []),
      preparationTime: data['preparationTime'] ?? 0,
      itemTaxPercentage: (data['itemTaxPercentage'] ?? 0.0).toDouble(),
      isTaxFixed: data['isTaxFixed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'restaurantId': restaurantId,
      'courseId': courseId,
      'orderTypeId': orderTypeId,
      'menuItems': menuItems,
      'inventoryItems': inventoryItems,
      'preparationTime': preparationTime,
      'itemTaxPercentage': itemTaxPercentage,
      'isTaxFixed': isTaxFixed,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
