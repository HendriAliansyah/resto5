// lib/views/kitchen/widgets/order_ticket.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/kitchen_order_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/providers/kitchen_provider.dart';
import 'package:resto2/views/kitchen/widgets/item_countdown_timer.dart';

class OrderTicket extends HookConsumerWidget {
  final KitchenOrderModel order;
  const OrderTicket({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeSinceOrder = useState(Duration.zero);
    final theme = Theme.of(context);

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        timeSinceOrder.value = DateTime.now().difference(
          order.createdAt.toDate(),
        );
      });
      return timer.cancel;
    }, [order.createdAt]);

    Color getBorderColor() {
      if (timeSinceOrder.value.inMinutes >= 10) return Colors.red;
      if (timeSinceOrder.value.inMinutes >= 5) return Colors.yellow;
      return theme.colorScheme.primary;
    }

    String formatDuration(Duration d) {
      return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }

    // Determine button text and next status based on current status
    String buttonText;
    OrderStatus? nextStatus;
    switch (order.overallStatus) {
      case OrderStatus.pending:
        buttonText = 'Start Preparing';
        nextStatus = OrderStatus.preparing;
        break;
      case OrderStatus.preparing:
        buttonText = 'Mark as Ready';
        nextStatus = OrderStatus.ready;
        break;
      case OrderStatus.ready:
        buttonText = 'Complete Order';
        nextStatus = OrderStatus.completed;
        break;
      default:
        buttonText = '...';
        nextStatus = null;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: getBorderColor(), width: 2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.tableName.isNotEmpty
                        ? order.tableName
                        : order.orderTypeName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatDuration(timeSinceOrder.value),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 2),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.menuName}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  ItemCountdownTimer(
                    preparationTime: Duration(minutes: item.preparationTime),
                    orderCreatedAt: order.createdAt,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: nextStatus == null
                  ? null
                  : () {
                      ref
                          .read(kitchenControllerProvider.notifier)
                          .updateOrderStatus(order.orderId, nextStatus!);
                    },
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}
