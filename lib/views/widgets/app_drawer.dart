// lib/views/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/role_permission_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/restaurant_provider.dart';
import 'package:resto2/utils/constants.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final authController = ref.read(authControllerProvider.notifier);
    final restaurant = ref.watch(restaurantStreamProvider).asData?.value;

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

    ImageProvider? getBackgroundImage() {
      if (restaurant?.logoUrl != null) {
        return NetworkImage(restaurant!.logoUrl!);
      }
      return null;
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              currentUser.displayName ?? UIStrings.defaultUserName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(currentUser.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              backgroundImage: getBackgroundImage(),
              child: getBackgroundImage() == null
                  ? Text(
                      currentUser.displayName?.substring(0, 1).toUpperCase() ??
                          'U',
                      style: const TextStyle(fontSize: 40.0),
                    )
                  : null,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text(UIStrings.home),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRoutes.home);
            },
          ),
          if (canAccess(PagePermission.accessOrderPage))
            ListTile(
              leading: const Icon(Icons.point_of_sale_outlined),
              title: const Text(UIStrings.posNewOrder),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.order);
              },
            ),
          if (canAccess(PagePermission.accessKitchenPage))
            ListTile(
              leading: const Icon(Icons.kitchen_outlined),
              title: const Text(UIStrings.kitchenDisplaySystem),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.kitchen);
              },
            ),
          if (canAccess(PagePermission.accessOrderSummary))
            ListTile(
              leading: const Icon(Icons.summarize_outlined),
              title: const Text(UIStrings.orderSummary),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.orderSummary);
              },
            ),
          if (canAccess(PagePermission.accessMasterRestaurant))
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text(UIStrings.manageRestaurantTitle),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageRestaurant);
              },
            ),
          if (canAccess(PagePermission.accessChargesAndTaxes))
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text(UIStrings.chargesAndTaxes),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.chargesAndTaxes);
              },
            ),
          if (canAccess(PagePermission.accessStaffManagement))
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text(UIStrings.staffManagement),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageStaff);
              },
            ),
          if (canAccess(PagePermission.accessCourseMaster))
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: const Text(UIStrings.courseMaster),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageCourses);
              },
            ),
          if (canAccess(PagePermission.accessTableTypeMaster))
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text(UIStrings.tableTypeMaster),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageTableTypes);
              },
            ),
          if (canAccess(PagePermission.accessTableMaster))
            ListTile(
              leading: const Icon(Icons.table_restaurant_outlined),
              title: const Text(UIStrings.tableManagement),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageTables);
              },
            ),
          if (canAccess(PagePermission.accessOrderTypeMaster))
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text(UIStrings.orderTypeMaster),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageOrderTypes);
              },
            ),
          if (canAccess(PagePermission.accessMenuMaster))
            ListTile(
              leading: const Icon(Icons.restaurant_menu_outlined),
              title: const Text(UIStrings.menuMaster),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageMenu);
              },
            ),
          if (canAccess(PagePermission.accessInventoryMaster))
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text(UIStrings.inventoryAndStock),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.manageInventory);
              },
            ),
          if (canAccess(PagePermission.accessPurchasePage))
            ListTile(
              leading: const Icon(Icons.inventory_outlined),
              title: const Text(UIStrings.receivingInventory),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.receivingInventory);
              },
            ),
          if (canAccess(PagePermission.accessPurchaseHistory))
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text(UIStrings.purchaseHistory),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.purchaseHistory);
              },
            ),
          if (canAccess(PagePermission.accessStockEdit))
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text(UIStrings.editStock),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.editStock);
              },
            ),
          if (canAccess(PagePermission.accessStockMovementHistory))
            ListTile(
              leading: const Icon(Icons.sync_alt),
              title: const Text(UIStrings.stockMovementHistory),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.stockMovementHistory);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text(UIStrings.settings),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text(UIStrings.logoutTitle),
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
