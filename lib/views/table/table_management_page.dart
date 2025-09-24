// lib/views/table/table_management_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:resto2/models/order_type_model.dart';
import 'package:resto2/models/table_model.dart';
import 'package:resto2/models/table_type_model.dart';
import 'package:resto2/providers/order_type_provider.dart';
import 'package:resto2/providers/table_filter_provider.dart';
import 'package:resto2/providers/table_provider.dart';
import 'package:resto2/providers/table_type_provider.dart';
import 'package:resto2/utils/snackbar.dart';
import 'package:resto2/views/table/widgets/table_dialog.dart';
import 'package:resto2/views/widgets/filter_expansion_tile.dart';
import 'package:resto2/views/widgets/shared/entity_management_page.dart';
import 'package:resto2/views/widgets/sort_order_toggle.dart';
import 'package:resto2/utils/constants.dart';

class TableManagementPage extends ConsumerWidget {
  const TableManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(sortedTablesProvider);
    final tableTypesAsync = ref.watch(tableTypesStreamProvider);
    final orderTypesAsync = ref.watch(orderTypesStreamProvider);
    final filter = ref.watch(tableFilterProvider);
    final filterNotifier = ref.read(tableFilterProvider.notifier);

    ref.listen<TableState>(tableControllerProvider, (previous, next) {
      if (next.status == TableActionStatus.success) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        showSnackBar(context, UIMessages.tableSaved);
      }
      if (next.status == TableActionStatus.error) {
        showSnackBar(
          context,
          next.errorMessage ?? UIMessages.errorOccurred,
          isError: true,
        );
      }
    });

    void showTableDialog({TableModel? table}) {
      showDialog(
        context: context,
        builder: (_) => TableDialog(table: table),
      );
    }

    return EntityManagementPage<TableModel>(
      title: UIStrings.tableManagement,
      noItemsFoundText: "No tables found.",
      items: tables,
      onAdd: () => showTableDialog(),
      filterTile: FilterExpansionTile(
        children: [
          TextFormField(
            initialValue: filter.searchQuery,
            decoration: const InputDecoration(
              labelText: UIStrings.searchByName,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => filterNotifier.setSearchQuery(value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField2<String?>(
            value: filter.tableTypeId,
            decoration: const InputDecoration(
              labelText: UIStrings.filterByType,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.zero,
            ),
            buttonStyleData: const ButtonStyleData(
              height: 50,
              padding: EdgeInsets.only(right: 10),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text(UIStrings.allTypes),
              ),
              ...tableTypesAsync.asData?.value.map(
                    (type) => DropdownMenuItem(
                      value: type.id,
                      child: Text(type.name),
                    ),
                  ) ??
                  [],
            ],
            onChanged: (value) => filterNotifier.setTableTypeFilter(value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField2<TableSortOption>(
                  value: filter.sortOption,
                  decoration: const InputDecoration(
                    labelText: UIStrings.sortBy,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.zero,
                  ),
                  buttonStyleData: const ButtonStyleData(
                    height: 50,
                    padding: EdgeInsets.only(right: 10),
                  ),
                  items: TableSortOption.values
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(
                            '${UIStrings.by}${option.name.substring(2)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      filterNotifier.setSortOption(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              SortOrderToggle(
                currentOrder: filter.sortOrder,
                onOrderChanged: (order) {
                  filterNotifier.setSortOrder(order);
                },
              ),
            ],
          ),
        ],
      ),
      itemBuilder: (context, table) {
        final tableTypesList = tableTypesAsync.asData?.value;
        final orderTypesList = orderTypesAsync.asData?.value;

        String tableTypeName = UIStrings.notAvailable;
        if (tableTypesList != null) {
          tableTypeName = tableTypesList
              .firstWhere(
                (element) => element.id == table.tableTypeId,
                orElse: () => TableType(
                  id: '',
                  name: UIStrings.notAvailable,
                  restaurantId: '',
                ),
              )
              .name;
        }

        String orderTypeName = UIStrings.all;
        if (orderTypesList != null) {
          orderTypeName = orderTypesList
              .firstWhere(
                (element) => element.id == table.orderTypeId,
                orElse: () => OrderType(
                  id: '',
                  name: UIStrings.all,
                  restaurantId: '',
                  accessibility: OrderTypeAccessibility.all,
                ),
              )
              .name;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(
              table.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$tableTypeName${UIStrings.tableCapacity.replaceFirst('{value}', table.capacity.toString())}'
              '${UIStrings.tableOrderType.replaceFirst('{value}', orderTypeName)}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showTableDialog(table: table),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () async {
                    try {
                      await ref
                          .read(tableControllerProvider.notifier)
                          .deleteTable(table.id);
                      if (context.mounted) {
                        showSnackBar(context, UIMessages.tableDeleted);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showSnackBar(
                          context,
                          UIMessages.failedToDeleteTable.replaceFirst(
                            '{error}',
                            e.toString(),
                          ),
                          isError: true,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
