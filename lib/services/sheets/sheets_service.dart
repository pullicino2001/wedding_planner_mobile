import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/googleapis_auth.dart' show AuthClient;
import '../../models/budget_item.dart';
import '../../models/guest.dart';
import '../../models/vendor.dart';
import '../../models/task_item.dart';

class SheetsService {
  final SheetsApi _api;
  final String spreadsheetId;

  SheetsService(AuthClient client, this.spreadsheetId)
      : _api = SheetsApi(client);

  // ─────────────────────────── SETUP ───────────────────────────

  /// Creates the wedding planner spreadsheet and returns its ID + URL.
  static Future<({String id, String url})> createSpreadsheet(
    AuthClient client,
    String coupleNames,
  ) async {
    final api = SheetsApi(client);

    final spreadsheet = await api.spreadsheets.create(
      Spreadsheet(
        properties: SpreadsheetProperties(
          title: '$coupleNames Wedding Planner',
        ),
        sheets: [
          Sheet(properties: SheetProperties(title: 'Budget', sheetId: 0)),
          Sheet(properties: SheetProperties(title: 'Guests', sheetId: 1)),
          Sheet(properties: SheetProperties(title: 'Vendors', sheetId: 2)),
          Sheet(properties: SheetProperties(title: 'Tasks', sheetId: 3)),
          Sheet(properties: SheetProperties(title: 'Settings', sheetId: 4)),
        ],
      ),
    );

    final id = spreadsheet.spreadsheetId!;
    final url = spreadsheet.spreadsheetUrl ?? 'https://docs.google.com/spreadsheets/d/$id';

    // Write column headers
    await api.spreadsheets.values.batchUpdate(
      BatchUpdateValuesRequest(
        valueInputOption: 'USER_ENTERED',
        data: [
          ValueRange(
            range: 'Budget!A1:G1',
            values: [
              ['ID', 'Category', 'Item', 'Estimated', 'Actual', 'Paid', 'Notes']
            ],
          ),
          ValueRange(
            range: 'Guests!A1:J1',
            values: [
              ['ID', 'First Name', 'Last Name', 'Email', 'Phone', 'RSVP', 'Dietary Restriction', 'Dietary Notes', 'Plus One', 'Relation']
            ],
          ),
          ValueRange(
            range: 'Vendors!A1:M1',
            values: [
              ['ID', 'Name', 'Category', 'Contact', 'Email', 'Phone', 'Total Cost', 'Deposit Paid', 'Deposit Due', 'Balance Due', 'Contract File', 'Notes', 'Installments']
            ],
          ),
          ValueRange(
            range: 'Tasks!A1:J1',
            values: [
              ['ID', 'Title', 'Category', 'Due Date', 'Done', 'Priority', 'Calendar Event', 'Notes', 'Due Time', 'Assigned To']
            ],
          ),
          ValueRange(
            range: 'Settings!A1:B1',
            values: [
              ['Key', 'Value']
            ],
          ),
        ],
      ),
      id,
    );

    return (id: id, url: url);
  }

  /// Creates a standalone guest-list spreadsheet and returns its ID + URL.
  /// The sheet uses a Name/Surname column-pair format; RSVP is set via cell
  /// background colour (green = confirmed, red = declined, white = pending).
  static Future<({String id, String url})> createGuestSheet(
    AuthClient client,
    String coupleNames,
  ) async {
    final api = SheetsApi(client);

    final spreadsheet = await api.spreadsheets.create(
      Spreadsheet(
        properties: SpreadsheetProperties(
          title: '$coupleNames Guest List',
        ),
        sheets: [
          Sheet(properties: SheetProperties(title: 'Guests', sheetId: 0)),
        ],
      ),
    );

    final id = spreadsheet.spreadsheetId!;
    final url = spreadsheet.spreadsheetUrl ??
        'https://docs.google.com/spreadsheets/d/$id';

    await api.spreadsheets.values.update(
      ValueRange(values: [
        ['Name', 'Surname', 'Name 2', 'Surname 2', 'Name 3', 'Surname 3']
      ]),
      id,
      'Guests!A1:F1',
      valueInputOption: 'USER_ENTERED',
    );

    return (id: id, url: url);
  }

  // ─────────────────────────── INTERNAL HELPERS ───────────────────────────

  Future<List<List<String>>> _readRange(String range) async {
    final response = await _api.spreadsheets.values.get(spreadsheetId, range);
    return (response.values ?? [])
        .map((row) => row.map((cell) => cell.toString()).toList())
        .toList();
  }

  Future<void> _appendRow(String sheet, List<Object> row) async {
    await _api.spreadsheets.values.append(
      ValueRange(values: [row]),
      spreadsheetId,
      '$sheet!A:A',
      valueInputOption: 'USER_ENTERED',
    );
  }

  Future<void> _updateRow(String sheet, int rowNumber, List<Object> row) async {
    await _api.spreadsheets.values.update(
      ValueRange(values: [row]),
      spreadsheetId,
      '$sheet!A$rowNumber',
      valueInputOption: 'USER_ENTERED',
    );
  }

  Future<void> _deleteRow(String sheet, int rowNumber) async {
    final ss = await _api.spreadsheets.get(spreadsheetId);
    final sheetObj = ss.sheets!.firstWhere(
      (s) => s.properties?.title == sheet,
    );
    final sheetId = sheetObj.properties!.sheetId!;

    await _api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(requests: [
        Request(
          deleteDimension: DeleteDimensionRequest(
            range: DimensionRange(
              sheetId: sheetId,
              dimension: 'ROWS',
              startIndex: rowNumber - 1,
              endIndex: rowNumber,
            ),
          ),
        ),
      ]),
      spreadsheetId,
    );
  }

  // ─────────────────────────── BUDGET ───────────────────────────

  Future<List<BudgetItem>> getBudgetItems() async {
    final rows = await _readRange('Budget!A2:G');
    return rows
        .asMap()
        .entries
        .where((e) => e.value.length > 2 && e.value[2].isNotEmpty)
        .map((e) => BudgetItem.fromSheetRow(e.value, e.key + 2))
        .toList();
  }

  Future<void> addBudgetItem(BudgetItem item) =>
      _appendRow('Budget', item.toSheetRow());

  Future<void> updateBudgetItem(BudgetItem item) =>
      _updateRow('Budget', item.rowNumber, item.toSheetRow());

  Future<void> deleteBudgetItem(int rowNumber) =>
      _deleteRow('Budget', rowNumber);

  // ─────────────────────────── GUESTS ───────────────────────────

  Future<List<Guest>> getGuests() async {
    final rows = await _readRange('Guests!A2:J');
    return rows
        .asMap()
        .entries
        .where((e) => e.value.length > 2 && (e.value[1].isNotEmpty || e.value[2].isNotEmpty))
        .map((e) => Guest.fromSheetRow(e.value, e.key + 2))
        .toList();
  }

  /// Reads a custom sheet in the "Name 1 / Surname 1 / Name 2 / Surname 2 / Name 3 / Surname 3"
  /// group format. Each row expands into up to 3 individual Guest objects.
  /// Uses the full spreadsheet endpoint so cell background colours are available
  /// (green = confirmed, red = declined, no colour = pending).
  /// Reads a guest sheet where each row holds up to 3 people as name/surname
  /// column pairs (A/B = person 1, C/D = person 2, E/F = person 3).
  /// Optional extra columns: G/H/I = dietary intolerances per person, J = email.
  /// Cell background colours drive RSVP status (green = confirmed, red = declined).
  Future<List<Guest>> getGuestsCustom() async {
    final spreadsheet = await _api.spreadsheets.get(
      spreadsheetId,
      includeGridData: true,
      ranges: ['A1:J'],
      $fields:
          'sheets(data(rowData(values(formattedValue,effectiveFormat/backgroundColor))))',
    );

    final rowData =
        spreadsheet.sheets?.firstOrNull?.data?.firstOrNull?.rowData;
    if (rowData == null || rowData.isEmpty) return [];

    String cell(List cells, int col) =>
        col < cells.length ? (cells[col].formattedValue ?? '').trim() : '';

    final guests = <Guest>[];
    for (var i = 1; i < rowData.length; i++) {
      final cells = rowData[i].values ?? [];
      final rowNum = i + 1;
      final rowEmail = cell(cells, 9);

      void addIfPresent(int nameCol, int surnameCol, int dietaryCol, int slot) {
        final first = cell(cells, nameCol);
        final last = cell(cells, surnameCol);
        if (first.isEmpty && last.isEmpty) return;

        final bg = nameCol < cells.length
            ? cells[nameCol].effectiveFormat?.backgroundColor
            : null;

        guests.add(Guest(
          id: 'custom_${rowNum}_$slot',
          firstName: first,
          lastName: last,
          email: slot == 1 ? rowEmail : '',
          phone: '',
          rsvpStatus: _cellColorToRsvp(bg),
          mealChoice: '',
          dietary: cell(cells, dietaryCol),
          hasPlusOne: false,
          relation: '',
          rowNumber: rowNum,
        ));
      }

      addIfPresent(0, 1, 6, 1);
      addIfPresent(2, 3, 7, 2);
      addIfPresent(4, 5, 8, 3);
    }
    return guests;
  }

  /// Maps a Google Sheets cell background colour to an RSVP status string.
  /// Green dominant → confirmed, red dominant → declined, white/none → pending.
  static String _cellColorToRsvp(Color? color) {
    if (color == null) return 'pending';
    final r = color.red ?? 1.0;
    final g = color.green ?? 1.0;
    final b = color.blue ?? 1.0;
    // Near-white means no colour has been set
    if (r > 0.9 && g > 0.9 && b > 0.9) return 'pending';
    // Green channel dominates → coming
    if (g > r && g > b && g > 0.35) return 'confirmed';
    // Red channel dominates → not coming
    if (r > g && r > b && r > 0.35) return 'declined';
    return 'pending';
  }

  Future<void> addGuest(Guest guest) =>
      _appendRow('Guests', guest.toSheetRow());

  Future<void> updateGuest(Guest guest) =>
      _updateRow('Guests', guest.rowNumber, guest.toSheetRow());

  Future<void> deleteGuest(int rowNumber) =>
      _deleteRow('Guests', rowNumber);

  // ─────────────────────────── VENDORS ───────────────────────────

  Future<List<Vendor>> getVendors() async {
    final rows = await _readRange('Vendors!A2:M');
    return rows
        .asMap()
        .entries
        .where((e) => e.value.length > 1 && e.value[1].isNotEmpty)
        .map((e) => Vendor.fromSheetRow(e.value, e.key + 2))
        .toList();
  }

  Future<void> addVendor(Vendor vendor) =>
      _appendRow('Vendors', vendor.toSheetRow());

  Future<void> updateVendor(Vendor vendor) =>
      _updateRow('Vendors', vendor.rowNumber, vendor.toSheetRow());

  Future<void> deleteVendor(int rowNumber) =>
      _deleteRow('Vendors', rowNumber);

  // ─────────────────────────── TASKS ───────────────────────────

  Future<List<TaskItem>> getTasks() async {
    final rows = await _readRange('Tasks!A2:J');
    return rows
        .asMap()
        .entries
        .where((e) => e.value.length > 1 && e.value[1].isNotEmpty)
        .map((e) => TaskItem.fromSheetRow(e.value, e.key + 2))
        .toList();
  }

  Future<void> addTask(TaskItem task) =>
      _appendRow('Tasks', task.toSheetRow());

  Future<void> updateTask(TaskItem task) =>
      _updateRow('Tasks', task.rowNumber, task.toSheetRow());

  Future<void> deleteTask(int rowNumber) =>
      _deleteRow('Tasks', rowNumber);
}
