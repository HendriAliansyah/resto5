// lib/views/order_type/order_type_management_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/order_type_model.dart';
import 'package:resto2/providers/order_type_provider.dart';
import 'package:resto2/views/order_type/widgets/order_type_dialog.dart';
import 'package:resto2/utils/constants.dart';
import 'package:resto2/views/widgets/shared/entity_management_page.dart';

class OrderTypeManagementPage extends ConsumerWidget {
  const OrderTypeManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderTypesAsync = ref.watch(orderTypesStreamProvider);
    final controller = ref.read(orderTypeControllerProvider.notifier);

    void showOrderTypeDialog({OrderType? orderType}) {
      showDialog(
        context: context,
        builder: (_) => OrderTypeDialog(orderType: orderType),
      );
    }

    return EntityManagementPage<OrderType>(
      title: UIStrings.orderTypeMaster,
      noItemsFoundText: "No order types found.",
      items: orderTypesAsync.asData?.value ?? [],
      onAdd: () => showOrderTypeDialog(),
      filterTile: const SizedBox.shrink(),
      itemBuilder: (context, type) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(type.name),
            subtitle: Text(
              UIStrings.accessibleBy.replaceFirst(
                '{value}',
                type.accessibility.name.replaceFirst(
                  type.accessibility.name[0],
                  type.accessibility.name[0].toUpperCase(),
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => showOrderTypeDialog(orderType: type),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => controller.deleteOrderType(type.id),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
