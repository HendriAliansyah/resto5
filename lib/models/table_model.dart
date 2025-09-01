// lib/models/table_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TableModel {
  final String id;
  final String name;
  final String tableTypeId;
  final int capacity;
  final String restaurantId;
  final String? orderTypeId;
  final bool isOccupied; // Added

  TableModel({
    required this.id,
    required this.name,
    required this.tableTypeId,
    required this.capacity,
    required this.restaurantId,
    this.orderTypeId,
    this.isOccupied = false, // Added
  });

  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableModel(
      id: doc.id,
      name: data['name'] ?? '',
      tableTypeId: data['tableTypeId'] ?? '',
      capacity: data['capacity'] ?? 0,
      restaurantId: data['restaurantId'] ?? '',
      orderTypeId: data['orderTypeId'],
      isOccupied: data['isOccupied'] ?? false, // Added
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tableTypeId': tableTypeId,
      'capacity': capacity,
      'restaurantId': restaurantId,
      'orderTypeId': orderTypeId,
      'isOccupied': isOccupied, // Added
    };
  }
}
