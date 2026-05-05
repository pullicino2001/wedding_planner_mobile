import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis_auth/googleapis_auth.dart' show AuthClient;
import '../services/sheets/sheets_service.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

/// Authenticated HTTP client — null when not signed in.
final authClientProvider = FutureProvider<AuthClient?>((ref) async {
  final account = ref.watch(currentUserProvider);
  if (account == null) return null;
  return ref.read(authServiceProvider).getAuthClient();
});

/// SheetsService for the main planner sheet (Budget, Vendors, Tasks).
/// Null when not signed in or setup not complete.
final sheetsServiceProvider = FutureProvider<SheetsService?>((ref) async {
  final client = await ref.watch(authClientProvider.future);
  if (client == null) return null;

  final settings = ref.watch(settingsProvider).value;
  if (settings == null || !settings.isComplete) return null;

  return SheetsService(client, settings.spreadsheetId);
});

/// SheetsService pointing at the separate guest-list sheet.
/// Null when not signed in or no guest sheet is configured.
final guestSheetsServiceProvider = FutureProvider<SheetsService?>((ref) async {
  final client = await ref.watch(authClientProvider.future);
  if (client == null) return null;

  final settings = ref.watch(settingsProvider).value;
  if (settings == null || !settings.hasGuestSheet) return null;

  return SheetsService(client, settings.guestSheetId);
});
