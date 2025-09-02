// lib/views/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/role_permission_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/utils/constants.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final authController = ref.read(authControllerProvider.notifier);

    if (currentUser == null) {
      return const Drawer(); // Return an empty drawer if user is not loaded
    }

    final userRole = currentUser.role;

    // Helper function to check permissions
    bool canAccess(PagePermission permission) {
      return userRole != null
          ? rolePermissions[userRole]?.contains(permission) ?? false
          : false;
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              currentUser.displayName ?? 'No Name',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(currentUser.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Text(
                currentUser.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 40.0),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRoutes.home);
            },
          ),
          if (canAccess(PagePermission.accessOrderPage))
            ListTile(
              leading: const Icon(Icons.point_of_sale_outlined),
              title: const Text('POS / New Order'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.order);
              },
            ),
          if (canAccess(PagePermission.accessKitchenPage))
            ListTile(
              leading: const Icon(Icons.kitchen_outlined),
              title: const Text('Kitchen Display'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.kitchen);
              },
            ),
          if (canAccess(PagePermission.accessMasterRestaurant))
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Manage Restaurant'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageRestaurant);
              },
            ),
          if (canAccess(PagePermission.accessChargesAndTaxes)) // Added
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Charges & Taxes'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.chargesAndTaxes);
              },
            ),
          if (canAccess(PagePermission.accessStaffManagement))
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Manage Staff'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageStaff);
              },
            ),
          if (canAccess(PagePermission.accessCourseMaster))
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: const Text('Course Master'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageCourses);
              },
            ),
          if (canAccess(PagePermission.accessTableTypeMaster))
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Table Type Master'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageTableTypes);
              },
            ),
          if (canAccess(PagePermission.accessTableMaster))
            ListTile(
              leading: const Icon(Icons.table_restaurant_outlined),
              title: const Text('Table Master'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageTables);
              },
            ),
          if (canAccess(PagePermission.accessOrderTypeMaster))
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Order Type Master'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageOrderTypes);
              },
            ),
          if (canAccess(PagePermission.accessMenuMaster))
            ListTile(
              leading: const Icon(Icons.restaurant_menu_outlined),
              title: const Text('Menu Master'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageMenu);
              },
            ),
          if (canAccess(PagePermission.accessInventoryMaster))
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Inventory & Stock'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageInventory);
              },
            ),
          if (canAccess(PagePermission.accessPurchasePage))
            ListTile(
              leading: const Icon(Icons.inventory_outlined),
              title: const Text('Receiving Inventory'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.receivingInventory);
              },
            ),
          if (canAccess(PagePermission.accessPurchaseHistory))
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('Purchase History'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.purchaseHistory);
              },
            ),
          if (canAccess(PagePermission.accessStockEdit))
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Edit Stock'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.editStock);
              },
            ),
          if (canAccess(PagePermission.accessStockMovementHistory))
            ListTile(
              leading: const Icon(Icons.sync_alt),
              title: const Text('Stock Movement History'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.stockMovementHistory);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              Navigator.pop(context);
              authController.signOut();
            },
          ),
        ],
      ),
    );
  }
}
