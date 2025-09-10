// lib/models/aggregated_kitchen_item_model.dart

/// A simple class to hold the source of an item (which order and item ID it came from).
class OrderItemSource {
  final String orderId;
  final String itemId;

  OrderItemSource({required this.orderId, required this.itemId});
}

/// Represents a grouping of the same menu item from multiple orders.
class AggregatedKitchenItem {
  final String menuId;
  final String menuName;
  final int totalQuantity;

  /// A list of all original items that make up this aggregation.
  final List<OrderItemSource> sources;

  AggregatedKitchenItem({
    required this.menuId,
    required this.menuName,
    required this.totalQuantity,
    required this.sources,
  });
}
