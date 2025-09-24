// lib/views/widgets/shared/entity_management_page.dart
import 'package:flutter/material.dart';
import 'package:resto2/views/widgets/app_drawer.dart';
import 'package:resto2/views/widgets/custom_app_bar.dart';

class EntityManagementPage<T> extends StatelessWidget {
  final String title;
  final Widget filterTile;
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final VoidCallback onAdd;
  final String noItemsFoundText;

  const EntityManagementPage({
    super.key,
    required this.title,
    required this.filterTile,
    required this.items,
    required this.itemBuilder,
    required this.onAdd,
    required this.noItemsFoundText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: Text(title)),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          filterTile,
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(noItemsFoundText))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return itemBuilder(context, items[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}
