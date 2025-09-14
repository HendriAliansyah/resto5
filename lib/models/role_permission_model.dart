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
  accessKitchenPage,
  accessPaymentPage, // ADD THIS
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
    PagePermission.accessKitchenPage,
    PagePermission.accessPaymentPage, // ADD THIS
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
    PagePermission.accessKitchenPage,
    PagePermission.accessPaymentPage, // ADD THIS
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
    PagePermission.accessKitchenPage,
    PagePermission.accessPaymentPage, // ADD THIS
  ],
  UserRole.cashier: [
    PagePermission.accessOrderPage,
    PagePermission.accessPaymentPage, // ADD THIS
  ],
};
