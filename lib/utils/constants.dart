// lib/utils/constants.dart
import 'package:flutter/material.dart';

// Route Constants
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String onboarding = '/onboarding';
  static const String notifications = '/notifications';
  static const String manageRestaurant = '/manage-restaurant';
  static const String manageStaff = '/manage-staff';
  static const String editStaff = '/edit-staff';
  static const String settings = '/settings';
  static const String manageCourses = '/manage-courses';
  static const String manageTableTypes = '/manage-table-types';
  static const String manageTables = '/manage-tables';
  static const String manageOrderTypes = '/manage-order-types';
  static const String manageMenu = '/manage-menu';
  static const String manageInventory = '/manage-inventory';
  static const String receivingInventory = '/receiving-inventory';
  static const String purchaseHistory = '/purchase-history';
  static const String editStock = '/edit-stock';
  static const String stockMovementHistory = '/stock-movement-history';
  static const String order = '/order';
  static const String chargesAndTaxes = '/charges-and-taxes';
  static const String kitchen = '/kitchen';
  static const String payment = '/payment';
  static const String orderSummary = '/order-summary';
  static const String orderDetail = '/order-detail';
}

// UI String Constants
class UIStrings {
  // General
  static const String appTitle = 'Restaurant App';
  static const String home = 'Home';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String close = 'Close';
  static const String requiredField = 'Required';
  static const String by = 'By ';
  static const String all = 'All';
  static const String confirm = 'Confirm';
  static const String itemsSelectedSuffix = 'items selected';
  static const String editStock = 'Edit Stock';

  // Auth Screens
  static const String loginTitle = 'Login';
  static const String logoutTitle = 'Logout';
  static const String registerTitle = 'Register';
  static const String forgotPasswordTitle = 'Forgot Password';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String displayNameLabel = 'Display Name';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String loginButton = 'Login';
  static const String registerButton = 'Register';
  static const String resetButton = 'Reset Password';
  static const String dontHaveAccount = 'Don\'t have an account? Register';
  static const String alreadyHaveAccount = 'Already have an account? Login';
  static const String forgotPasswordPrompt = 'Forgot Password?';
  static const String welcomeBack = 'Welcome Back';
  static const String signInToDashboard = 'Sign in to your POS dashboard';
  static const String createAccount = 'Create Account';
  static const String startYourJourney = 'Start your journey with us';
  static const String receiveResetLink = 'Receive a reset link';
  static const String receiveResetLinkMessage =
      'Enter your account email below to receive a password reset link.';

  // Onboarding Screen
  static const String welcome = 'Welcome!';
  static const String welcomeUser = 'Welcome, {name}! 👋';
  static const String createNewRestaurant = 'Create a New Restaurant';
  static const String or = 'or';
  static const String joinExistingRestaurant =
      'Join an existing restaurant by entering its ID:';
  static const String restaurantId = 'Restaurant ID';
  static const String restaurantIdHint =
      'Enter the ID provided by your manager';
  static const String sendJoinRequest = 'Send Join Request';

  // Notifications
  static const String notificationsTitle = 'Notifications';
  static const String noNotifications = 'No Notifications Yet';
  static const String noNotificationsMessage =
      'Important updates and requests from your restaurant will appear here.';
  static const String newJoinRequestTitle = 'New Join Request';
  static const String joinRequestMessage =
      'A user has requested to join your restaurant.';
  static const String requestApproved =
      'Your request to join the restaurant was approved.';
  static const String requestRejected =
      'Your request to join the restaurant was rejected.';
  static const String newNotification = 'You have a new notification.';
  static const String requestApprovedTitle = 'Request Approved!';
  static const String requestRejectedTitle = 'Request Rejected';

  // Restaurant Management
  static const String createRestaurantTitle = 'Create Your Restaurant';
  static const String manageRestaurantTitle = 'Manage Restaurant';
  static const String restaurantName = 'Restaurant Name';
  static const String address = 'Address';
  static const String phoneNumber = 'Phone Number';
  static const String phoneNumberHint = '08123654789';
  static const String saveChanges = 'Save Changes';
  static const String saving = 'Saving...';

  // Staff Management
  static const String staffManagement = 'Staff Management';
  static const String currentStaff = 'Current Staff';
  static const String joinRequests = 'Join Requests';
  static const String noPendingRequests = 'No Pending Requests';
  static const String noPendingRequestsMessage =
      'When a new user requests to join your restaurant, you will see their request here.';
  static const String assignRole = 'Assign a Role';
  static const String assign = 'Assign';
  static const String searchByNameOrEmail = 'Search by Name or Email';
  static const String filterByRole = 'Filter by Role';
  static const String allRoles = 'All Roles';
  static const String noStaffMembersFound = 'No staff members found.';
  static const String role = 'Role';
  static const String staffEmail = 'Email: {email}';
  static const String staffName = 'Name: {name}';
  static const String editStaff = 'Edit Staff';

  // Course Management
  static const String courseMaster = 'Course Master';
  static const String noCoursesFound =
      'No courses found. Add one to get started!';
  static const String editCourse = 'Edit Course';
  static const String addCourse = 'Add New Course';
  static const String courseName = 'Course Name';
  static const String courseNameHint = 'e.g., Appetizers, Main Courses';
  static const String description = 'Description';
  static const String courseDescriptionHint =
      'e.g., Delicious starters to begin your meal.';

  // Home Screen
  static const String welcomeMessage = 'Welcome, {name}! 👋';
  static const String yourRole = 'Your role: {role}';
  static const String defaultUserName = 'User';

  // Inventory Management
  static const String inventoryAndStock = 'Inventory & Stock';
  static const String searchByName = 'Search by Name';
  static const String sortByName = 'Sort by Name:';
  static const String noInventoryItems = 'No inventory items found.';
  static const String stockLabel = 'Stock: {value}';
  static const String avgCostLabel = 'Avg Cost: \${value}';
  static const String editItem = 'Edit Item';
  static const String addItem = 'Add New Item';
  static const String tapToAddImage = 'Tap to add image';
  static const String itemName = 'Item Name';
  static const String itemDescriptionHint =
      'Description (e.g., from Supplier X)';
  static const String manualStockAdjustment = 'Manual Stock Adjustment';
  static const String adjustItemStock = 'Adjust Item Stock';
  static const String currentQuantity = 'Current Quantity';
  static const String newQuantity = 'New Quantity';
  static const String reasonForChange = 'Reason for Change';
  static const String reasonHint =
      'e.g., Stock count correction, damaged goods';
  static const String confirmAdjustment = 'Confirm Adjustment';
  static const String stockMovementHistory = 'Stock Movement History';
  static const String selectAnItem = 'Select an Item';
  static const String selectAnItemToViewHistory =
      'Choose an inventory item above to see its movement history.';
  static const String noHistoryFound = 'No History Found';
  static const String noHistoryMessage =
      'There are no recorded stock movements for this item.';
  static const String byUser = 'By: {name}';
  static const String change = 'Change';
  static const String reasonLabel = 'Reason: {reason}';

  // Kitchen
  static const String kitchenDisplaySystem = 'Kitchen Display System';
  static const String orders = 'Orders';
  static const String summary = 'Summary';
  static const String newOrders = 'New';
  static const String preparing = 'Preparing';
  static const String ready = 'Ready';
  static const String allCaughtUp = 'All Caught Up!';
  static const String noNewItems = 'No new items to prepare.';
  static const String startPreparing = 'Start Preparing';
  static const String noOrdersInStage = 'No orders in this stage.';
  static const String orderNotePrefix = 'Note: ';
  static const String itemNotePrefix = '↳ Note: ';
  static const String resetStatus = 'Reset Status';
  static const String managerApprovalRequired = 'Manager Approval Required';
  static const String managerOwnerEmail = 'Manager/Owner Email';
  static const String ingredientsWasted = 'Ingredients were wasted?';
  static const String approve = 'Approve';

  // Menu Management
  static const String menuMaster = 'Menu Master';
  static const String filterAndSortMenu = 'Filter & Sort Menu';
  static const String filterByCourse = 'Filter by Course';
  static const String allCourses = 'All Courses';
  static const String sortBy = 'Sort by';
  static const String name = 'Name';
  static const String price = 'Price';
  static const String noMenuItemsFound = 'No menu items found.';
  static const String prepTimeSuffix = ' min';
  static const String editMenu = 'Edit Menu';
  static const String addMenu = 'Add New Menu';
  static const String preparationTime = 'Preparation Time (minutes)';
  static const String itemSpecificTax = 'Item-Specific Tax';
  static const String taxFixedValue = 'Tax Fixed Value (\$)';
  static const String taxPercentage = 'Tax Percentage (%)';
  static const String isTaxFixed = 'Is Tax a Fixed Value?';
  static const String course = 'Course';
  static const String orderType = 'Order Type';
  static const String inventoryItems = 'Inventory Items';
  static const String searchInventoryItems = 'Search for inventory items';

  // Order
  static const String posNewOrder = 'POS / New Order';
  static const String createOrderTypeMessage =
      'Please create at least one Order Type in the Master settings.';
  static const String noTablesForOrderType =
      'No tables available for this order type.';
  static const String capacity = 'Capacity: {value}';
  static const String addToOrder = 'Add to Order';
  static const String addToOrderTitle = 'Add to Order: {tableName}';
  static const String confirmAndAddItems = 'Confirm & Add Items';
  static const String orderDetailsTitle = 'Order Details: {tableName}';
  static const String placedBy = 'Placed by: {name}';
  static const String time = 'Time: {time}';
  static const String subtotal = 'Subtotal';
  static const String grandTotal = 'Grand Total';
  static const String goToPayment = 'Go to Payment';
  static const String newOrderTitle = 'New Order: {tableName} ({orderType})';
  static const String searchMenu = 'Search Menu';
  static const String noMenuItemsAvailable = 'No menu items available.';
  static const String noteFor = 'Note for {itemName}';
  static const String noteHint = 'e.g., Extra spicy';
  static const String totalLabel = 'Total:';
  static const String placeOrder = 'Place Order';
  static const String addNoteToOrder = 'Add Note to Order';
  static const String orderNoteHint = 'e.g., Allergy alert';
  static const String confirmOrder = 'Confirm Order';
  static const String orderNote = 'Order Note:';
  static const String serviceChargePrefix = 'Service: ';
  static const String taxPrefix = 'Tax: ';
  static const String itemSpecificTaxes = 'Item-Specific Taxes';
  static const String submit = 'Submit';

  // Order Type
  static const String orderTypeMaster = 'Order Type Master';
  static const String accessibleBy = 'Accessible by: {value}';
  static const String editOrderType = 'Edit Order Type';
  static const String addOrderType = 'Add Order Type';
  static const String orderTypeName = 'Order Type Name';
  static const String orderTypeNameHint = 'e.g., Dine-In, Takeaway';
  static const String accessibility = 'Accessibility';
  static const String allUsers = 'All Users';
  static const String staffOnly = 'Staff Only';

  // Payment
  static const String paymentFor = 'Payment for {tableName}';
  static const String orderSummary = 'Order Summary';
  static const String paymentMethod = 'Payment Method';
  static const String cash = 'Cash';
  static const String card = 'Card';
  static const String other = 'Other';
  static const String addTip = 'Add Tip (Optional)';
  static const String finalTotal = 'Final Total';
  static const String amountTendered = 'Amount Tendered';
  static const String changeDue = 'Change Due';
  static const String finalizePayment = 'Finalize Payment';

  // Purchase
  static const String purchaseHistory = 'Purchase History';
  static const String noPurchaseRecords = 'No purchase records found.';
  static const String unknownItem = 'Unknown Item';
  static const String dateLabel = 'Date: {date}';
  static const String notesLabel = '\nNotes: {notes}';
  static const String notAvailable = 'N/A';
  static const String quantityLabel = 'Qty: {value}';
  static const String receivingInventory = 'Receiving Inventory';
  static const String noInventoryToReceive =
      'There are no inventory items to receive. Please add an item in the "Inventory & Stock" page first.';
  static const String quantityReceived = 'Quantity Received';
  static const String totalCost = 'Total Cost';
  static const String notesHint = 'Notes (e.g., Invoice #)';
  static const String recordStockEntry = 'Record Stock Entry';
  static const String inventoryItem = 'Inventory Item';
  static const String selectAnItemPrompt = 'Select an item';
  static const String selectInventoryItem = 'Select Inventory Item';
  static const String search = 'Search';
  static const String currentStock = 'Current Stock: {value}';

  // Charges and Taxes
  static const String chargesAndTaxes = 'Charges & Taxes';
  static const String serviceCharges = 'Service Charges';
  static const String noRulesDefined = 'No rules defined.';
  static const String taxes = 'Taxes';
  static const String subtotalConditionEqual = ' if subtotal = \${value}';
  static const String subtotalConditionBetween =
      ' if subtotal is between \${from} and \${to}';
  static const String subtotalConditionLessThan = ' if subtotal < \${value}';
  static const String subtotalConditionMoreThan = ' if subtotal > \${value}';
  static const String editRule = 'Edit Rule';
  static const String addRule = 'Add New Rule';
  static const String ruleName = 'Rule Name';
  static const String ruleType = 'Rule Type';
  static const String valueType = 'Value Type';
  static const String value = 'Value';
  static const String applyToOrderTypes = 'Apply To Order Types (Optional)';
  static const String searchOrderTypes = 'Search order types';
  static const String conditionOnSubtotal = 'Condition (based on subtotal)';
  static const String fromValue = 'From (\$)';
  static const String valueAmount = 'Value (\$)';
  static const String toValue = 'To (\$)';
  static const String saveRule = 'Save Rule';

  // Settings
  static const String settings = 'Settings';
  static const String appearance = 'Appearance';
  static const String chooseAppearance = 'Choose how the app looks.';
  static const String system = 'System';
  static const String light = 'Light';
  static const String dark = 'Dark';

  // Summary
  static const String orderAndPaymentSummary = 'Order & Payment Summary';
  static const String filterByStatus = 'Filter by Status';
  static const String allStatuses = 'All Statuses';
  static const String date = 'Date';
  static const String totalFilter = 'Total';
  static const String dateRange = 'Date Range';
  static const String allTime = 'All Time';
  static const String noOrdersForCriteria =
      'No orders found for the selected criteria.';
  static const String orderId = 'Order #{id}';
  static const String tableLabel = 'Table: {name}';
  static const String timeLabel = '\nTime: {time}';
  static const String totalSales = 'Total Sales:';
  static const String orderDetails = 'Order Details';
  static const String servedBy = 'Served By:';
  static const String items = 'Items';
  static const String table = 'Table:';

  // Table Management
  static const String tableManagement = 'Table Management';
  static const String filterByType = 'Filter by Type';
  static const String allTypes = 'All Types';
  static const String tableCapacity = ' • Capacity: {value}';
  static const String tableOrderType = '\nOrder Type: {value}';
  static const String editTable = 'Edit Table';
  static const String addTable = 'Add Table';
  static const String tableName = 'Table Name';
  static const String capacityLabel = 'Capacity';
  static const String tableType = 'Table Type';
  static const String allOrderTypes = 'All Order Types';

  // Table Type Management
  static const String tableTypeMaster = 'Table Type Master';
  static const String noTableTypesFound =
      'No table types found. Add one to get started!';
  static const String editTableType = 'Edit Table Type';
  static const String addTableType = 'Add Table Type';
  static const String typeName = 'Type Name';
}

class UIMessages {
  // Success Messages
  static const String changesSaved = 'Changes saved successfully!';
  static const String courseSaved = 'Course saved successfully!';
  static const String courseDeleted = 'Course deleted.';
  static const String inventoryItemSaved = 'Inventory item saved!';
  static const String menuSaved = 'Menu saved!';
  static const String orderPlaced = 'Order placed successfully!';
  static const String itemsAddedToOrder = 'Items added to order successfully!';
  static const String orderTypeSaved = 'Order Type saved successfully!';
  static const String paymentSuccessful = 'Payment successful!';
  static const String stockUpdated = 'Stock successfully updated!';
  static const String ruleSaved = 'Rule saved successfully!';
  static const String tableSaved = 'Table saved successfully!';
  static const String tableDeleted = 'Table deleted.';
  static const String tableTypeSaved = 'Table Type saved successfully!';
  static const String themePreferenceSaved = 'Theme preference saved!';
  static const String staffMemberAdded = '{name} has been added to your staff.';
  static const String requestRejected =
      'Request from {name} has been rejected.';
  static const String passwordResetLinkSent =
      "A password reset link has been sent to your email. Please check your inbox.";
  static const String registrationSuccessful =
      'Registration successful! Please wait for an admin to assign you a role.';
  static const String stockUpdateSuccessful = 'Stock updated successfully!';
  static const String requestSentSuccessfully =
      'Your request has been sent successfully.';

  // Error Messages
  static const String errorOccurred = 'An error occurred';
  static const String unknownError = 'An unknown error occurred.';
  static const String failedToLoadNotifications =
      'Could not load notifications.';
  static const String invalidNumber = 'Invalid number';
  static const String reasonRequired = 'A reason is required';
  static const String newQuantityRequired = 'A new quantity is required';
  static const String selectItemError = 'Please select an item';
  static const String nameIsRequired = 'Name is required';
  static const String valueIsRequired = 'Value is required';
  static const String conditionValueIsRequired = 'Condition value is required';
  static const String toValueIsRequired = '"To" value is required for between';
  static const String authFailed = 'Authentication failed.';
  static const String userDataNotFound = 'User data not found.';
  static const String insufficientPermissions =
      'Insufficient permissions. Manager approval required.';
  static const String selectCourseAndOrderType =
      'Please select a course and order type.';
  static const String couldNotFindActiveOrder =
      'Could not find an active order for this table.';
  static const String errorLoadingOrder = 'Error loading order: {error}';
  static const String pleaseSelectItemsToAdd = 'Please select items to add.';
  static const String cashTenderedIsLess =
      'Cash tendered is less than the total amount due.';
  static const String enterEmailError = 'Please enter your email address.';
  static const String failedToSendResetLink =
      "Failed to send reset link. Please try again.";
  static const String loginFailed =
      'Failed to log in. Please check your credentials.';
  static const String enterNameError = 'Please enter your name';
  static const String enterEmailPrompt = 'Please enter an email';
  static const String enterValidEmail = 'Please enter a valid email address';
  static const String enterPassword = 'Please enter your password';
  static const String passwordTooShort =
      'Password must be at least 6 characters long';
  static const String passwordMismatch = 'Passwords do not match';
  static const String confirmPasswordError = 'Please confirm your password';
  static const String restaurantNotFound =
      'Restaurant not found. Please check the ID and try again.';
  static const String unexpectedError =
      'An unexpected error occurred. Please try again.';
  static const String failedToDeleteTable = 'Failed to delete table: {error}';
  static const String enterTableName = 'Please enter a name';

  // Validation Messages
  static const String enterPhoneNumber = 'Please enter a phone number';
  static const String enterOnlyNumbers = 'Please enter only numbers';
  static const String enterAddress = 'Please enter an address';
  static const String enterCourseName = 'Please enter a name';
  static const String enterDescription = 'Please enter a description';
  static const String enterItemName = 'Please enter an item name';
}

class DBConstants {
  static const String usersCollection = 'users';
}

// You can also add color and style constants here
class AppColors {
  static const Color primary = Colors.orange;
  static const Color error = Colors.redAccent;
}
