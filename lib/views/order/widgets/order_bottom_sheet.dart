// lib/views/order/widgets/order_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/menu_model.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/models/order_type_model.dart';
import 'package:resto2/models/table_model.dart';
import 'package:resto2/providers/course_provider.dart';
import 'package:resto2/providers/menu_filter_provider.dart';
import 'package:resto2/providers/menu_provider.dart';
import 'package:resto2/providers/order_provider.dart';
import 'package:resto2/providers/staff_filter_provider.dart';
import 'package:resto2/utils/snackbar.dart';
import 'package:resto2/views/order/widgets/order_confirmation_dialog.dart';
import 'package:resto2/views/widgets/filter_expansion_tile.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';
import 'package:resto2/views/widgets/sort_order_toggle.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:uuid/uuid.dart';
import 'package:resto2/utils/constants.dart';

//... (OrderBottomSheet class remains the same)
class OrderBottomSheet extends HookConsumerWidget {
  final TableModel table;
  final OrderType orderType;

  const OrderBottomSheet({
    super.key,
    required this.table,
    required this.orderType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderedItems = useState<List<OrderItemModel>>([]);
    final orderNote = useState<String?>(null);
    final orderState = ref.watch(orderControllerProvider);
    final isLoading = orderState.status == OrderActionStatus.loading;

    ref.listen<OrderState>(orderControllerProvider, (prev, next) {
      if (next.status == OrderActionStatus.success) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        showSnackBar(context, UIMessages.orderPlaced);
      }
      if (next.status == OrderActionStatus.error) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        showSnackBar(
          context,
          next.errorMessage ?? UIMessages.errorOccurred,
          isError: true,
        );
      }
    });

    void handlePlaceOrder() {
      ref
          .read(orderControllerProvider.notifier)
          .placeOrder(
            table: table,
            orderType: orderType,
            items: orderedItems.value,
            orderNote: orderNote.value,
          );
    }

    void showConfirmationDialog() {
      showDialog(
        context: context,
        builder: (_) => OrderConfirmationDialog(
          items: orderedItems.value,
          orderType: orderType,
          orderNote: orderNote.value,
          onSubmit: handlePlaceOrder,
          isLoading: isLoading,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                UIStrings.newOrderTitle
                    .replaceFirst('{tableName}', table.name)
                    .replaceFirst('{orderType}', orderType.name),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _MenuList(orderedItems: orderedItems)),
            if (orderedItems.value.isNotEmpty)
              _OrderSummary(
                orderedItems: orderedItems.value,
                orderNote: orderNote,
                onPlaceOrder: showConfirmationDialog,
                isLoading: isLoading,
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuList extends HookConsumerWidget {
  final ValueNotifier<List<OrderItemModel>> orderedItems;

  const _MenuList({required this.orderedItems});

  void _showNoteDialog(
    BuildContext context,
    OrderItemModel item,
    Function(String) onSave,
  ) {
    final noteController = TextEditingController(text: item.note);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            UIStrings.noteFor.replaceFirst('{itemName}', item.menuName),
          ),
          content: TextField(
            controller: noteController,
            autofocus: true,
            decoration: const InputDecoration(hintText: UIStrings.noteHint),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(UIStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                onSave(noteController.text);
                Navigator.pop(context);
              },
              child: const Text(UIStrings.save),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusAsync = ref.watch(menusStreamProvider);
    final coursesAsync = ref.watch(coursesStreamProvider);

    // Hooks for local state management of filters
    final searchQuery = useState('');
    final selectedCourseId = useState<String?>(null);
    final sortOption = useState(MenuSortOption.byName);
    final sortOrder = useState(SortOrder.asc);

    void updateQuantity(MenuModel item, int newQuantity) {
      final newList = List<OrderItemModel>.from(orderedItems.value);
      final index = newList.indexWhere((i) => i.menuId == item.id);

      if (index != -1) {
        if (newQuantity <= 0) {
          newList.removeAt(index);
        } else {
          newList[index] = newList[index].copyWith(quantity: newQuantity);
        }
      } else if (newQuantity > 0) {
        final itemTax = item.isTaxFixed
            ? item.itemTaxPercentage
            : item.price * (item.itemTaxPercentage / 100);
        newList.add(
          OrderItemModel(
            id: const Uuid().v4(),
            menuId: item.id,
            menuName: item.name,
            quantity: newQuantity,
            price: item.price,
            itemTax: itemTax,
          ),
        );
      }
      orderedItems.value = newList;
    }

    void updateNote(String menuId, String note) {
      final newList = List<OrderItemModel>.from(orderedItems.value);
      final index = newList.indexWhere((i) => i.menuId == menuId);
      if (index != -1) {
        newList[index] = newList[index].copyWith(note: note);
        orderedItems.value = newList;
      }
    }

    return menusAsync.when(
      data: (menus) {
        if (menus.isEmpty) {
          return const Center(child: Text(UIStrings.noMenuItemsAvailable));
        }

        final courses = coursesAsync.asData?.value ?? [];

        // Apply filtering
        final filteredMenus = menus.where((menu) {
          final searchMatch = menu.name.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          );
          final courseMatch =
              selectedCourseId.value == null ||
              menu.courseId == selectedCourseId.value;
          return searchMatch && courseMatch;
        }).toList();

        // Apply sorting
        filteredMenus.sort((a, b) {
          int comparison;
          switch (sortOption.value) {
            case MenuSortOption.byName:
              comparison = a.name.compareTo(b.name);
              break;
            case MenuSortOption.byPrice:
              comparison = a.price.compareTo(b.price);
              break;
          }
          return sortOrder.value == SortOrder.asc ? comparison : -comparison;
        });

        return Column(
          children: [
            FilterExpansionTile(
              title: UIStrings.filterAndSortMenu,
              children: [
                TextField(
                  onChanged: (value) => searchQuery.value = value,
                  decoration: InputDecoration(
                    labelText: UIStrings.searchMenu,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField2<String?>(
                  value: selectedCourseId.value,
                  onChanged: (value) => selectedCourseId.value = value,
                  decoration: const InputDecoration(
                    labelText: UIStrings.filterByCourse,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.zero,
                  ),
                  buttonStyleData: const ButtonStyleData(height: 50),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text(UIStrings.allCourses),
                    ),
                    ...courses.map(
                      (course) => DropdownMenuItem(
                        value: course.id,
                        child: Text(course.name),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField2<MenuSortOption>(
                        value: sortOption.value,
                        onChanged: (value) {
                          if (value != null) sortOption.value = value;
                        },
                        decoration: const InputDecoration(
                          labelText: UIStrings.sortBy,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.zero,
                        ),
                        buttonStyleData: const ButtonStyleData(height: 50),
                        items: const [
                          DropdownMenuItem(
                            value: MenuSortOption.byName,
                            child: Text(UIStrings.name),
                          ),
                          DropdownMenuItem(
                            value: MenuSortOption.byPrice,
                            child: Text(UIStrings.price),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SortOrderToggle(
                      currentOrder: sortOrder.value,
                      onOrderChanged: (order) => sortOrder.value = order,
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: filteredMenus.length,
                itemBuilder: (context, index) {
                  final menu = filteredMenus[index];
                  final orderedItem = orderedItems.value.firstWhere(
                    (item) => item.menuId == menu.id,
                    orElse: () => OrderItemModel(
                      id: '',
                      menuId: '',
                      menuName: '',
                      quantity: 0,
                      price: 0,
                    ),
                  );
                  final currentQuantity = orderedItem.quantity;

                  return ListTile(
                    title: Text(menu.name),
                    subtitle: Text('\$${menu.price.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.note_add_outlined,
                            color:
                                orderedItem.note != null &&
                                    orderedItem.note!.isNotEmpty
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          onPressed: currentQuantity > 0
                              ? () => _showNoteDialog(
                                  context,
                                  orderedItem,
                                  (note) => updateNote(menu.id, note),
                                )
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: currentQuantity > 0
                              ? () => updateQuantity(menu, currentQuantity - 1)
                              : null,
                        ),
                        Text(
                          currentQuantity.toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () =>
                              updateQuantity(menu, currentQuantity + 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, st) => Center(child: Text('Error: ${e.toString()}')),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final List<OrderItemModel> orderedItems;
  final ValueNotifier<String?> orderNote;
  final VoidCallback onPlaceOrder;
  final bool isLoading;

  const _OrderSummary({
    required this.orderedItems,
    required this.orderNote,
    required this.onPlaceOrder,
    required this.isLoading,
  });

  void _showOrderNoteDialog(BuildContext context) {
    final noteController = TextEditingController(text: orderNote.value);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(UIStrings.addNoteToOrder),
          content: TextField(
            controller: noteController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: UIStrings.orderNoteHint,
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(UIStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                orderNote.value = noteController.text;
                Navigator.pop(context);
              },
              child: const Text(UIStrings.save),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = orderedItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                UIStrings.totalLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : onPlaceOrder,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text(UIStrings.placeOrder),
                ),
              ),
              const SizedBox(width: 16),
              IconButton.filled(
                icon: const Icon(Icons.note_add),
                tooltip: UIStrings.addNoteToOrder,
                onPressed: () => _showOrderNoteDialog(context),
                style: IconButton.styleFrom(
                  backgroundColor:
                      orderNote.value != null && orderNote.value!.isNotEmpty
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
