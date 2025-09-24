// lib/views/table_type/table_type_management_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/table_type_model.dart';
import 'package:resto2/providers/table_type_provider.dart';
import 'package:resto2/views/table_type/widgets/table_type_dialog.dart';
import 'package:resto2/utils/constants.dart';
import 'package:resto2/views/widgets/shared/entity_management_page.dart';

class TableTypeManagementPage extends ConsumerWidget {
  const TableTypeManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableTypesAsync = ref.watch(tableTypesStreamProvider);
    final controller = ref.read(tableTypeControllerProvider.notifier);

    void showTableTypeDialog({TableType? tableType}) {
      showDialog(
        context: context,
        builder: (_) => TableTypeDialog(tableType: tableType),
      );
    }

    return EntityManagementPage<TableType>(
      title: UIStrings.tableTypeMaster,
      noItemsFoundText: UIStrings.noTableTypesFound,
      items: tableTypesAsync.asData?.value ?? [],
      onAdd: () => showTableTypeDialog(),
      filterTile: const SizedBox.shrink(), // No filter for this page
      itemBuilder: (context, type) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(
              type.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => showTableTypeDialog(tableType: type),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => controller.deleteTableType(type.id),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
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
