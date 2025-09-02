// lib/views/order/widgets/occupied_table_dialog.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:resto2/models/order_model.dart';

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Placed by: ${order.staffName}'),
            Text('Time: $formattedDate'),
            const Divider(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: ListView.builder(
                shrinkWrap: true,
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
            ),
            const Divider(height: 24),
            // Display full breakdown
            _buildChargeRow('Subtotal', order.subtotal, theme: theme),
            if (order.serviceCharge > 0)
              _buildChargeRow(
                'Service Charge',
                order.serviceCharge,
                theme: theme,
              ),
            if (order.itemSpecificTaxes > 0)
              _buildChargeRow(
                'Item Taxes',
                order.itemSpecificTaxes,
                theme: theme,
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
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement Add to Order functionality
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Order'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement Print Bill functionality
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print Bill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
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
