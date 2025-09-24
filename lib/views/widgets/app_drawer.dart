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

    // Helper to create a navigation list tile
    Widget buildTile(
      BuildContext context,
      String title,
      IconData icon,
      String route,
    ) {
      return ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
      );
    }

    // Custom header widget that replaces UserAccountsDrawerHeader
    Widget buildDrawerHeader() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.surface,
              backgroundImage: getBackgroundImage(),
              child: getBackgroundImage() == null
                  ? Text(
                      currentUser.displayName?.substring(0, 1).toUpperCase() ??
                          'U',
                      style: const TextStyle(fontSize: 32.0),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              currentUser.displayName ?? UIStrings.defaultUserName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentUser.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            buildDrawerHeader(), // Using the new custom header
            buildTile(
              context,
              UIStrings.home,
              Icons.home_outlined,
              AppRoutes.home,
            ),
            // --- Operations Group ---
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Operations",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (canAccess(PagePermission.accessOrderPage))
              buildTile(
                context,
                UIStrings.posNewOrder,
                Icons.point_of_sale_outlined,
                AppRoutes.order,
              ),
            if (canAccess(PagePermission.accessKitchenPage))
              buildTile(
                context,
                UIStrings.kitchenDisplaySystem,
                Icons.kitchen_outlined,
                AppRoutes.kitchen,
              ),
            if (canAccess(PagePermission.accessOrderSummary))
              buildTile(
                context,
                UIStrings.orderSummary,
                Icons.summarize_outlined,
                AppRoutes.orderSummary,
              ),

            // --- Management Group (Collapsible) ---
            const Divider(),
            ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              title: const Text(
                "Management",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.settings_applications_outlined),
              children: [
                if (canAccess(PagePermission.accessMasterRestaurant))
                  buildTile(
                    context,
                    UIStrings.manageRestaurantTitle,
                    Icons.storefront_outlined,
                    AppRoutes.manageRestaurant,
                  ),
                if (canAccess(PagePermission.accessChargesAndTaxes))
                  buildTile(
                    context,
                    UIStrings.chargesAndTaxes,
                    Icons.receipt_long_outlined,
                    AppRoutes.chargesAndTaxes,
                  ),
                if (canAccess(PagePermission.accessStaffManagement))
                  buildTile(
                    context,
                    UIStrings.staffManagement,
                    Icons.people_outline,
                    AppRoutes.manageStaff,
                  ),
                if (canAccess(PagePermission.accessMenuMaster))
                  buildTile(
                    context,
                    UIStrings.menuMaster,
                    Icons.restaurant_menu_outlined,
                    AppRoutes.manageMenu,
                  ),
                if (canAccess(PagePermission.accessCourseMaster))
                  buildTile(
                    context,
                    UIStrings.courseMaster,
                    Icons.book_outlined,
                    AppRoutes.manageCourses,
                  ),
                if (canAccess(PagePermission.accessTableMaster))
                  buildTile(
                    context,
                    UIStrings.tableManagement,
                    Icons.table_restaurant_outlined,
                    AppRoutes.manageTables,
                  ),
                if (canAccess(PagePermission.accessTableTypeMaster))
                  buildTile(
                    context,
                    UIStrings.tableTypeMaster,
                    Icons.category_outlined,
                    AppRoutes.manageTableTypes,
                  ),
                if (canAccess(PagePermission.accessOrderTypeMaster))
                  buildTile(
                    context,
                    UIStrings.orderTypeMaster,
                    Icons.receipt_long_outlined,
                    AppRoutes.manageOrderTypes,
                  ),
              ],
            ),

            // --- Inventory Group (Collapsible) ---
            const Divider(),
            ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              title: const Text(
                "Inventory",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.inventory_2_outlined),
              children: [
                if (canAccess(PagePermission.accessInventoryMaster))
                  buildTile(
                    context,
                    UIStrings.inventoryAndStock,
                    Icons.inventory_2_outlined,
                    AppRoutes.manageInventory,
                  ),
                if (canAccess(PagePermission.accessPurchasePage))
                  buildTile(
                    context,
                    UIStrings.receivingInventory,
                    Icons.inventory_outlined,
                    AppRoutes.receivingInventory,
                  ),
                if (canAccess(PagePermission.accessPurchaseHistory))
                  buildTile(
                    context,
                    UIStrings.purchaseHistory,
                    Icons.history_outlined,
                    AppRoutes.purchaseHistory,
                  ),
                if (canAccess(PagePermission.accessStockEdit))
                  buildTile(
                    context,
                    UIStrings.editStock,
                    Icons.edit_note,
                    AppRoutes.editStock,
                  ),
                if (canAccess(PagePermission.accessStockMovementHistory))
                  buildTile(
                    context,
                    UIStrings.stockMovementHistory,
                    Icons.sync_alt,
                    AppRoutes.stockMovementHistory,
                  ),
              ],
            ),

            // --- App Settings & Logout ---
            const Divider(),
            buildTile(
              context,
              UIStrings.settings,
              Icons.settings_outlined,
              AppRoutes.settings,
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
      ),
    );
  }
}
