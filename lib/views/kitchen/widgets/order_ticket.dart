// lib/views/kitchen/widgets/order_ticket.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/kitchen_order_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/providers/kitchen_provider.dart';
import 'package:resto2/utils/snackbar.dart';
import 'package:resto2/views/kitchen/widgets/item_countdown_timer.dart';
import 'package:resto2/views/kitchen/widgets/reset_approval_dialog.dart';

class OrderTicket extends HookConsumerWidget {
  final KitchenOrderModel order;
  const OrderTicket({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(kitchenControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          showSnackBar(context, error.toString(), isError: true);
        },
      );
    });

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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: getBorderColor(), width: 2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                if (order.note != null && order.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Note: ${order.note}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 2),
          ...order.items.map((item) => _buildItemRow(context, ref, item)),
        ],
      ),
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    WidgetRef ref,
    KitchenOrderItemModel item,
  ) {
    final theme = Theme.of(context);
    final controller = ref.read(kitchenControllerProvider.notifier);
    final itemStatus = item.status;
    final itemKey = '${order.orderId}-${item.id}';
    final isProcessing = ref.watch(processingItemsProvider).contains(itemKey);

    OrderItemStatus? nextStatus;
    switch (itemStatus) {
      case OrderItemStatus.pending:
        nextStatus = OrderItemStatus.preparing;
        break;
      case OrderItemStatus.preparing:
        nextStatus = OrderItemStatus.ready;
        break;
      case OrderItemStatus.ready:
        nextStatus = OrderItemStatus.served;
        break;
      case OrderItemStatus.served:
        nextStatus = null;
        break;
    }

    void showResetDialog() {
      showDialog(
        context: context,
        builder: (_) => ResetApprovalDialog(
          onApproved: (wasWasted) {
            controller.resetOrderItemStatus(
              orderId: order.orderId,
              itemId: item.id,
              wasWasted: wasWasted,
            );
          },
        ),
      );
    }

    return Material(
      color: itemStatus == OrderItemStatus.preparing
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : (itemStatus == OrderItemStatus.ready
                ? Colors.green.withOpacity(0.15)
                : Colors.transparent),
      child: InkWell(
        onTap: (isProcessing || nextStatus == null)
            ? null
            : () {
                controller.updateOrderItemStatus(
                  orderId: order.orderId,
                  itemId: item.id,
                  newStatus: nextStatus!,
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity}x ${item.menuName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: itemStatus == OrderItemStatus.served
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: itemStatus == OrderItemStatus.served
                            ? Colors.grey
                            : null,
                      ),
                    ),
                    if (item.note != null && item.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "↳ Note: ${item.note}",
                          // THE FIX IS HERE: Changed the color for better contrast.
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ItemCountdownTimer(
                      preparationTime: Duration(minutes: item.preparationTime),
                      orderCreatedAt: order.createdAt,
                    ),
                  ],
                ),
              ),
              if (isProcessing)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'reset') {
                      showResetDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        if (itemStatus != OrderItemStatus.pending)
                          const PopupMenuItem<String>(
                            value: 'reset',
                            child: Text('Reset Status'),
                          ),
                      ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
