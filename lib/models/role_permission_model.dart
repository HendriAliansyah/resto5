// lib/models/role_permission_model.dart
enum UserRole { owner, admin, manager, cashier }

enum PagePermission {
  accessMasterRestaurant,
  accessStaffManagement,
  accessCourseMaster,
  accessTableTypeMaster,
  accessTableMaster,
  accessOrderTypeMaster,
  accessMenuMaster,
  accessInventoryMaster,
  accessPurchasePage,
  accessPurchaseHistory,
  accessStockEdit,
  accessStockMovementHistory,
  accessOrderPage,
  accessChargesAndTaxes,
  accessKitchenPage, // Added
}

const Map<UserRole, List<PagePermission>> rolePermissions = {
  UserRole.owner: [
    PagePermission.accessMasterRestaurant,
    PagePermission.accessStaffManagement,
    PagePermission.accessCourseMaster,
    PagePermission.accessTableTypeMaster,
    PagePermission.accessTableMaster,
    PagePermission.accessOrderTypeMaster,
    PagePermission.accessMenuMaster,
    PagePermission.accessInventoryMaster,
    PagePermission.accessPurchasePage,
    PagePermission.accessPurchaseHistory,
    PagePermission.accessStockEdit,
    PagePermission.accessStockMovementHistory,
    PagePermission.accessOrderPage,
    PagePermission.accessChargesAndTaxes,
    PagePermission.accessKitchenPage, // Added
  ],
  UserRole.admin: [
    PagePermission.accessStaffManagement,
    PagePermission.accessCourseMaster,
    PagePermission.accessTableTypeMaster,
    PagePermission.accessTableMaster,
    PagePermission.accessOrderTypeMaster,
    PagePermission.accessMenuMaster,
    PagePermission.accessInventoryMaster,
    PagePermission.accessPurchasePage,
    PagePermission.accessPurchaseHistory,
    PagePermission.accessStockEdit,
    PagePermission.accessStockMovementHistory,
    PagePermission.accessOrderPage,
    PagePermission.accessChargesAndTaxes,
    PagePermission.accessKitchenPage, // Added
  ],
  UserRole.manager: [
    PagePermission.accessTableTypeMaster,
    PagePermission.accessTableMaster,
    PagePermission.accessInventoryMaster,
    PagePermission.accessPurchasePage,
    PagePermission.accessPurchaseHistory,
    PagePermission.accessStockEdit,
    PagePermission.accessStockMovementHistory,
    PagePermission.accessOrderPage,
    PagePermission.accessKitchenPage, // Added
  ],
  UserRole.cashier: [PagePermission.accessOrderPage],
};
