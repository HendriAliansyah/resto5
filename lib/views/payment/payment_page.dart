// lib/views/payment/payment_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/models/payment_model.dart';
import 'package:resto2/providers/payment_provider.dart';
import 'package:resto2/utils/snackbar.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';

class PaymentPage extends HookConsumerWidget {
  final OrderModel order;
  const PaymentPage({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedPaymentMethod = useState(PaymentMethod.cash);
    final amountTenderedController = useTextEditingController();
    final tipController = useTextEditingController();

    // State for amounts
    final tipAmount = useState(0.0);
    final amountTendered = useState(0.0);
    final paymentState = ref.watch(paymentControllerProvider);
    final isLoading = paymentState.status == PaymentStatus.loading;

    // Perform all currency calculations in cents to avoid floating-point errors.
    final grandTotalInCents = (order.grandTotal * 100).round();
    final tipInCents = (tipAmount.value * 100).round();
    final finalTotalInCents = grandTotalInCents + tipInCents;
    final amountTenderedInCents = (amountTendered.value * 100).round();
    final changeDueInCents = amountTenderedInCents - finalTotalInCents;

    // Convert back to dollars only for display and final recording
    final finalTotal = finalTotalInCents / 100.0;
    final changeDue = changeDueInCents / 100.0;

    ref.listen<PaymentState>(paymentControllerProvider, (prev, next) {
      if (next.status == PaymentStatus.success) {
        showSnackBar(context, 'Payment successful!');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      if (next.status == PaymentStatus.error) {
        showSnackBar(
          context,
          next.errorMessage ?? 'An error occurred',
          isError: true,
        );
      }
    });

    void finalize() {
      if (isLoading) return;

      if (selectedPaymentMethod.value == PaymentMethod.cash &&
          amountTendered.value < finalTotal) {
        showSnackBar(
          context,
          'Cash tendered is less than the total amount due.',
          isError: true,
        );
        return;
      }

      ref
          .read(paymentControllerProvider.notifier)
          .finalizePayment(
            order: order,
            amountPaid: finalTotal,
            method: selectedPaymentMethod.value,
            tip: tipAmount.value > 0 ? tipAmount.value : null,
          );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text('Payment for ${order.tableName}')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Summary Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const Divider(height: 24),
                      ...order.items.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${item.quantity}x ${item.menuName}'),
                          trailing: Text(
                            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                      const Divider(height: 24),
                      _buildChargeRow('Subtotal', order.subtotal, theme),
                      // Display the detailed charge breakdown
                      ...order.appliedCharges.map(
                        (charge) =>
                            _buildChargeRow(charge.name, charge.amount, theme),
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
              const SizedBox(height: 24),

              // Payment Method
              Text('Payment Method', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              SegmentedButton<PaymentMethod>(
                segments: const [
                  ButtonSegment(
                    value: PaymentMethod.cash,
                    label: Text('Cash'),
                    icon: Icon(Icons.money_outlined),
                  ),
                  ButtonSegment(
                    value: PaymentMethod.card,
                    label: Text('Card'),
                    icon: Icon(Icons.credit_card_outlined),
                  ),
                  ButtonSegment(
                    value: PaymentMethod.other,
                    label: Text('Other'),
                    icon: Icon(Icons.wallet_outlined),
                  ),
                ],
                selected: {selectedPaymentMethod.value},
                onSelectionChanged: (newSelection) {
                  selectedPaymentMethod.value = newSelection.first;
                },
              ),
              const SizedBox(height: 24),

              // Tip, Final Total, and Change Due
              TextFormField(
                controller: tipController,
                decoration: const InputDecoration(
                  labelText: 'Add Tip (Optional)',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  tipAmount.value = double.tryParse(value) ?? 0.0;
                },
              ),
              const SizedBox(height: 16),

              _buildChargeRow('Final Total', finalTotal, theme, isTotal: true),
              const Divider(height: 24),

              if (selectedPaymentMethod.value == PaymentMethod.cash) ...[
                TextFormField(
                  controller: amountTenderedController,
                  decoration: const InputDecoration(
                    labelText: 'Amount Tendered',
                    prefixText: '\$',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: (value) {
                    amountTendered.value = double.tryParse(value) ?? 0.0;
                  },
                ),
                const SizedBox(height: 16),
                _buildChargeRow(
                  'Change Due',
                  changeDue < 0 ? 0.0 : changeDue,
                  theme,
                  isChange: true,
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: isLoading ? null : finalize,
            child: isLoading
                ? const LoadingIndicator()
                : const Text('Finalize Payment'),
          ),
        ),
      ),
    );
  }

  Widget _buildChargeRow(
    String label,
    double amount,
    ThemeData theme, {
    bool isTotal = false,
    bool isChange = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal || isChange
                ? theme.textTheme.titleLarge
                : theme.textTheme.bodyLarge,
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style:
                (isTotal || isChange
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.bodyLarge)
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isTotal
                          ? theme.colorScheme.primary
                          : (isChange ? Colors.green : null),
                    ),
          ),
        ],
      ),
    );
  }
}
