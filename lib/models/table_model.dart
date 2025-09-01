// lib/models/table_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TableModel {
  final String id;
  final String name;
  final String tableTypeId;
  final int capacity;
  final String restaurantId;
  final String? orderTypeId; // Added

  TableModel({
    required this.id,
    required this.name,
    required this.tableTypeId,
    required this.capacity,
    required this.restaurantId,
    this.orderTypeId, // Added
  });

  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableModel(
      id: doc.id,
      name: data['name'] ?? '',
      tableTypeId: data['tableTypeId'] ?? '',
      capacity: data['capacity'] ?? 0,
      restaurantId: data['restaurantId'] ?? '',
      orderTypeId: data['orderTypeId'], // Added
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tableTypeId': tableTypeId,
      'capacity': capacity,
      'restaurantId': restaurantId,
      'orderTypeId': orderTypeId, // Added
    };
  }
}
