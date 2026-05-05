class AppConstants {
  AppConstants._();

  static const String appName = 'Wedding Planner';

  // Google Sheets tab names — must match exactly what is created in setup
  static const String sheetBudget = 'Budget';
  static const String sheetGuests = 'Guests';
  static const String sheetVendors = 'Vendors';
  static const String sheetTasks = 'Tasks';
  static const String sheetSettings = 'Settings';

  // SharedPreferences keys
  static const String prefSpreadsheetId = 'spreadsheet_id';
  static const String prefSpreadsheetUrl = 'spreadsheet_url';
  static const String prefWeddingDate = 'wedding_date';
  static const String prefCoupleNames = 'couple_names';
  static const String prefUserRole = 'user_role'; // 'Bride', 'Groom', ''
  static const String prefSetupComplete = 'setup_complete';
  // Guest sheet — separate from the main planner sheet
  static const String prefGuestSheetId = 'guest_sheet_id';
  static const String prefGuestSheetUrl = 'guest_sheet_url';
  // Legacy keys kept only for migration
  static const String prefSheetSource = 'sheet_source';
  static const String prefCustomSpreadsheetId = 'custom_spreadsheet_id';
  static const String prefCustomSpreadsheetUrl = 'custom_spreadsheet_url';
  static const String sheetSourceCustom = 'custom';

  // RSVP statuses
  static const String rsvpPending = 'pending';
  static const String rsvpConfirmed = 'confirmed';
  static const String rsvpDeclined = 'declined';

  // Task priorities
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';

  // Task assignees
  static const List<String> taskAssignees = ['Bride', 'Groom', 'Both'];

  // Budget categories
  static const List<String> budgetCategories = [
    'Venue',
    'Catering',
    'Photography',
    'Videography',
    'Flowers & Décor',
    'Music & Entertainment',
    'Cake',
    'Attire & Beauty',
    'Stationery',
    'Transport',
    'Accommodation',
    'Gifts & Favours',
    'Other',
  ];

  // Vendor categories
  static const List<String> vendorCategories = [
    'Venue',
    'Caterer',
    'Photographer',
    'Videographer',
    'Florist',
    'Band / DJ',
    'Baker',
    'Hair & Makeup',
    'Celebrant',
    'Transport',
    'Stationery',
    'Accommodation',
    'Other',
  ];

  // Task categories
  static const List<String> taskCategories = [
    'Venue',
    'Catering',
    'Photography',
    'Flowers & Décor',
    'Attire',
    'Guests',
    'Admin & Legal',
    'Honeymoon',
    'Day Of',
    'Other',
  ];

  // Guest relation categories (built-in; custom ones live in customRelationsProvider)
  static const List<String> guestRelations = [];

  // Dietary restriction options
  static const List<String> mealChoices = [
    'Standard',
    'Vegetarian',
    'Vegan',
    'Gluten Free',
    'Children\'s',
    'Not Attending',
  ];
}
