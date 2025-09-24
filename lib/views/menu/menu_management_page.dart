// lib/views/menu/menu_management_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:resto2/models/course_model.dart';
import 'package:resto2/models/menu_model.dart';
import 'package:resto2/providers/course_provider.dart';
import 'package:resto2/providers/menu_filter_provider.dart';
import 'package:resto2/providers/menu_provider.dart';
import 'package:resto2/views/menu/widgets/menu_bottom_sheet.dart';
import 'package:resto2/views/widgets/filter_expansion_tile.dart';
import 'package:resto2/views/widgets/shared/entity_management_page.dart';
import 'package:resto2/views/widgets/sort_order_toggle.dart';
import 'package:resto2/utils/constants.dart';

class MenuManagementPage extends ConsumerWidget {
  const MenuManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesStreamProvider);
    final sortedMenus = ref.watch(sortedMenusProvider);
    final filterState = ref.watch(menuFilterProvider);

    void showMenuSheet({MenuModel? menu}) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => MenuBottomSheet(menu: menu),
      );
    }

    return EntityManagementPage<MenuModel>(
      title: UIStrings.menuMaster,
      noItemsFoundText: UIStrings.noMenuItemsFound,
      items: sortedMenus,
      onAdd: () => showMenuSheet(),
      filterTile: FilterExpansionTile(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: UIStrings.searchByName,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) =>
                ref.read(menuFilterProvider.notifier).setSearchQuery(value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField2<String>(
            value: filterState.courseId,
            decoration: const InputDecoration(
              labelText: UIStrings.filterByCourse,
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
                child: Text(UIStrings.allCourses),
              ),
              ...coursesAsync.asData?.value.map(
                    (course) => DropdownMenuItem(
                      value: course.id,
                      child: Text(course.name),
                    ),
                  ) ??
                  [],
            ],
            onChanged: (courseId) =>
                ref.read(menuFilterProvider.notifier).setCourseFilter(courseId),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButtonFormField2<MenuSortOption>(
                  value: filterState.sortOption,
                  decoration: const InputDecoration(
                    labelText: UIStrings.sortBy,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.zero,
                  ),
                  buttonStyleData: const ButtonStyleData(
                    height: 50,
                    padding: EdgeInsets.only(right: 10),
                  ),
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
                  onChanged: (option) {
                    if (option != null) {
                      ref
                          .read(menuFilterProvider.notifier)
                          .setSortOption(option);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              SortOrderToggle(
                currentOrder: filterState.sortOrder,
                onOrderChanged: (order) =>
                    ref.read(menuFilterProvider.notifier).setSortOrder(order),
              ),
            ],
          ),
        ],
      ),
      itemBuilder: (context, menu) {
        final courseName =
            coursesAsync.asData?.value
                .firstWhere(
                  (c) => c.id == menu.courseId,
                  orElse: () => Course(
                    id: '',
                    name: UIStrings.notAvailable,
                    description: '',
                    restaurantId: '',
                    createdAt: Timestamp.now(),
                    updatedAt: Timestamp.now(),
                  ),
                )
                .name ??
            UIStrings.notAvailable;
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: ListTile(
            onTap: () => showMenuSheet(menu: menu),
            leading: SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: menu.imageUrl != null
                    ? Image.network(menu.imageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            title: Text(
              menu.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$courseName • ${menu.preparationTime}${UIStrings.prepTimeSuffix}',
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '\$${menu.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
