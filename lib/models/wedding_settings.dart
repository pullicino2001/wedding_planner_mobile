class WeddingSettings {
  final String spreadsheetId;
  final String spreadsheetUrl;
  final DateTime weddingDate;
  final String coupleNames;
  final String userRole;
  final String guestSheetId;
  final String guestSheetUrl;

  const WeddingSettings({
    required this.spreadsheetId,
    required this.spreadsheetUrl,
    required this.weddingDate,
    required this.coupleNames,
    this.userRole = '',
    this.guestSheetId = '',
    this.guestSheetUrl = '',
  });

  bool get hasGuestSheet => guestSheetId.isNotEmpty;

  bool get isComplete => spreadsheetId.isNotEmpty && coupleNames.isNotEmpty;

  int get daysUntilWedding {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final wedding =
        DateTime(weddingDate.year, weddingDate.month, weddingDate.day);
    return wedding.difference(today).inDays;
  }

  WeddingSettings copyWith({
    String? guestSheetId,
    String? guestSheetUrl,
    String? userRole,
  }) =>
      WeddingSettings(
        spreadsheetId: spreadsheetId,
        spreadsheetUrl: spreadsheetUrl,
        weddingDate: weddingDate,
        coupleNames: coupleNames,
        userRole: userRole ?? this.userRole,
        guestSheetId: guestSheetId ?? this.guestSheetId,
        guestSheetUrl: guestSheetUrl ?? this.guestSheetUrl,
      );
}
