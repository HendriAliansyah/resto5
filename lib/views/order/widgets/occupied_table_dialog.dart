// lib/views/order/widgets/occupied_table_dialog.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/utils/constants.dart';
import 'package:resto2/views/order/widgets/add_to_order_bottom_sheet.dart';

class OccupiedTableDialog extends ConsumerWidget {
  final OrderModel order;
  const OccupiedTableDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat.yMd().add_jm().format(
      order.createdAt.toDate(),
    );

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text('Order Details: ${order.tableName}')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Placed by: ${order.staffName}'),
              Text('Time: $formattedDate'),
              const Divider(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.menuName,
                                style: theme.textTheme.bodyLarge,
                              ),
                              Text(
                                '${item.quantity} x \$${item.price.toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '\$${(item.quantity * item.price).toStringAsFixed(2)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 24),
              _buildChargeRow('Subtotal', order.subtotal, theme: theme),
              ...order.appliedCharges.map(
                (charge) =>
                    _buildChargeRow(charge.name, charge.amount, theme: theme),
              ),
              const Divider(height: 16),
              _buildChargeRow(
                'Grand Total',
                order.grandTotal,
                theme: theme,
                isTotal: true,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog first
                context.push(AppRoutes.payment, extra: order);
              },
              icon: const Icon(Icons.payment_outlined),
              label: const Text('Go to Payment'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => AddToOrderBottomSheet(order: order),
                );
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChargeRow(
    String label,
    double amount, {
    required ThemeData theme,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyLarge,
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style:
                (isTotal
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.bodyLarge)
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isTotal ? theme.colorScheme.primary : null,
                    ),
          ),
        ],
      ),
    );
  }
}
