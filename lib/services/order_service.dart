// lib/services/order_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resto2/models/inventory_item_model.dart';
import 'package:resto2/models/menu_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/models/stock_movement_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionPath = 'orders';
  final String _inventoriesCollectionPath = 'inventories';
  final String _menusCollectionPath = 'menus';
  final String _stockMovementsCollectionPath = 'stockMovements';

  // ... (existing methods remain the same)
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
    required String userId,
    required String userDisplayName,
  }) async {
    final orderRef = _db.collection(_collectionPath).doc(orderId);
    final List<StockMovementModel> movementsToLog = [];

    await _db.runTransaction((transaction) async {
      // ... (transaction logic remains the same)
      final orderSnapshot = await transaction.get(orderRef);
      if (!orderSnapshot.exists) throw Exception("Order does not exist!");

      final order = OrderModel.fromFirestore(orderSnapshot);
      final itemToUpdate = order.items.firstWhere((item) => item.id == itemId);

      MenuModel? menu;
      final List<DocumentSnapshot> inventorySnapshots = [];

      if (newStatus == OrderItemStatus.preparing &&
          itemToUpdate.status == OrderItemStatus.pending) {
        final menuRef = _db
            .collection(_menusCollectionPath)
            .doc(itemToUpdate.menuId);
        final menuSnapshot = await transaction.get(menuRef);
        if (!menuSnapshot.exists) throw Exception("Menu item does not exist!");

        menu = MenuModel.fromFirestore(menuSnapshot);

        for (final inventoryId in menu.inventoryItems) {
          final inventoryRef = _db
              .collection(_inventoriesCollectionPath)
              .doc(inventoryId);
          inventorySnapshots.add(await transaction.get(inventoryRef));
        }
      }

      // --- STAGE 2: PERFORM ALL WRITES ---
      if (newStatus == OrderItemStatus.preparing &&
          itemToUpdate.status == OrderItemStatus.pending) {
        for (final inventorySnapshot in inventorySnapshots) {
          if (!inventorySnapshot.exists) continue;

          final inventoryItem = InventoryItem.fromFirestore(inventorySnapshot);
          final newQuantity = inventoryItem.quantityInStock - 1;

          transaction.update(inventorySnapshot.reference, {
            'quantityInStock': newQuantity,
          });

          movementsToLog.add(
            StockMovementModel(
              id: '',
              inventoryItemId: inventoryItem.id,
              userId: userId,
              userDisplayName: userDisplayName,
              type: StockMovementType.sale,
              quantityBefore: inventoryItem.quantityInStock,
              quantityAfter: newQuantity,
              reason: 'Order: ${order.tableName} - Item: ${menu!.name}',
              createdAt: Timestamp.now(),
              restaurantId: order.restaurantId,
            ),
          );
        }
      }

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

      final allItemsServed = updatedItems.every(
        (item) => item.status == OrderItemStatus.served,
      );

      OrderStatus newOverallStatus = order.status;
      if (allItemsServed) {
        newOverallStatus = OrderStatus.completed;
      } else {
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

    if (movementsToLog.isNotEmpty) {
      final batch = _db.batch();
      for (final movement in movementsToLog) {
        final movementRef = _db.collection(_stockMovementsCollectionPath).doc();
        batch.set(movementRef, movement.toJson());
      }
      await batch.commit();
    }
  }

  // THE FIX IS HERE: New method specifically for resetting an item.
  Future<void> resetOrderItem({
    required String orderId,
    required String itemId,
    required bool wasWasted,
    required String userId,
    required String userDisplayName,
  }) async {
    final orderRef = _db.collection(_collectionPath).doc(orderId);
    final List<StockMovementModel> movementsToLog = [];

    await _db.runTransaction((transaction) async {
      // --- STAGE 1: READ ALL DOCUMENTS ---
      final orderSnapshot = await transaction.get(orderRef);
      if (!orderSnapshot.exists) throw Exception("Order does not exist!");

      final order = OrderModel.fromFirestore(orderSnapshot);
      final itemToReset = order.items.firstWhere((item) => item.id == itemId);

      // Only proceed if the item was actually in a state where stock was taken
      if (itemToReset.status != OrderItemStatus.pending) {
        final menuRef = _db
            .collection(_menusCollectionPath)
            .doc(itemToReset.menuId);
        final menuSnapshot = await transaction.get(menuRef);
        if (!menuSnapshot.exists) throw Exception("Menu item does not exist!");

        final menu = MenuModel.fromFirestore(menuSnapshot);
        final List<DocumentSnapshot> inventorySnapshots = [];
        for (final invId in menu.inventoryItems) {
          inventorySnapshots.add(
            await transaction.get(
              _db.collection(_inventoriesCollectionPath).doc(invId),
            ),
          );
        }

        // --- STAGE 2: PERFORM ALL WRITES ---
        for (final invSnapshot in inventorySnapshots) {
          if (!invSnapshot.exists) continue;

          final inventoryItem = InventoryItem.fromFirestore(invSnapshot);
          final movementReason = 'Reset: ${order.tableName} - ${menu.name}';

          if (wasWasted) {
            // Log waste, but don't change the quantity
            movementsToLog.add(
              StockMovementModel(
                id: '',
                inventoryItemId: inventoryItem.id,
                userId: userId,
                userDisplayName: userDisplayName,
                type: StockMovementType.waste,
                quantityBefore: inventoryItem.quantityInStock,
                quantityAfter: inventoryItem.quantityInStock, // No change
                reason: movementReason,
                createdAt: Timestamp.now(),
                restaurantId: order.restaurantId,
              ),
            );
          } else {
            // Return stock to inventory
            final newQuantity = inventoryItem.quantityInStock + 1;
            transaction.update(invSnapshot.reference, {
              'quantityInStock': newQuantity,
            });
            movementsToLog.add(
              StockMovementModel(
                id: '',
                inventoryItemId: inventoryItem.id,
                userId: userId,
                userDisplayName: userDisplayName,
                type: StockMovementType.reset,
                quantityBefore: inventoryItem.quantityInStock,
                quantityAfter: newQuantity,
                reason: movementReason,
                createdAt: Timestamp.now(),
                restaurantId: order.restaurantId,
              ),
            );
          }
        }
      }

      // Finally, update the item's status back to pending
      final updatedItems = order.items.map((item) {
        if (item.id == itemId) {
          return OrderItemModel(
            id: item.id,
            menuId: item.menuId,
            menuName: item.menuName,
            quantity: item.quantity,
            price: item.price,
            itemTax: item.itemTax,
            status: OrderItemStatus.pending,
          );
        }
        return item;
      }).toList();

      // Recalculate overall status
      final allItemsServed = updatedItems.every(
        (item) => item.status == OrderItemStatus.served,
      );
      OrderStatus newOverallStatus;
      if (allItemsServed) {
        newOverallStatus = OrderStatus.completed;
      } else {
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

    // Log all movements after the transaction
    if (movementsToLog.isNotEmpty) {
      final batch = _db.batch();
      for (final movement in movementsToLog) {
        final movementRef = _db.collection(_stockMovementsCollectionPath).doc();
        batch.set(movementRef, movement.toJson());
      }
      await batch.commit();
    }
  }
}
