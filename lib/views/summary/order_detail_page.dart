// lib/views/summary/order_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resto2/models/order_model.dart';

class OrderDetailPage extends StatelessWidget {
  final OrderModel order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id.substring(0, 8)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Details', style: theme.textTheme.headlineSmall),
                const Divider(height: 24),
                _buildDetailRow('Table:', order.tableName, theme),
                _buildDetailRow(
                  'Date:',
                  DateFormat.yMd().add_jm().format(order.createdAt.toDate()),
                  theme,
                ),
                _buildDetailRow('Served By:', order.staffName, theme),
                const Divider(height: 24),
                Text('Items', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item.quantity}x ${item.menuName}'),
                    trailing:
                        Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
                  ),
                ),
                const Divider(height: 24),
                _buildChargeRow('Subtotal', order.subtotal, theme),
                ...order.appliedCharges.map(
                  (charge) => _buildChargeRow(charge.name, charge.amount, theme),
                ),
                const Divider(height: 16),
                _buildChargeRow(
                  'Grand Total',
                  order.grandTotal,
                  theme,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.titleMedium),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildChargeRow(
    String label,
    double amount,
    ThemeData theme, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal ? theme.textTheme.titleLarge : theme.textTheme.bodyLarge,
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: (isTotal ? theme.textTheme.titleLarge : theme.textTheme.bodyLarge)
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
