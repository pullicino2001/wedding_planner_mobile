import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/wedding_settings.dart';

class SettingsNotifier extends StateNotifier<AsyncValue<WeddingSettings?>> {
  SettingsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final spreadsheetId = prefs.getString(AppConstants.prefSpreadsheetId);
      if (spreadsheetId == null || spreadsheetId.isEmpty) {
        if (mounted) state = const AsyncValue.data(null);
        return;
      }
      final weddingDateStr = prefs.getString(AppConstants.prefWeddingDate) ?? '';

      // Guest sheet — read new key, fall back to legacy key on first run
      String guestSheetId = prefs.getString(AppConstants.prefGuestSheetId) ?? '';
      String guestSheetUrl = prefs.getString(AppConstants.prefGuestSheetUrl) ?? '';
      if (guestSheetId.isEmpty) {
        final legacySource = prefs.getString(AppConstants.prefSheetSource) ?? '';
        if (legacySource == AppConstants.sheetSourceCustom) {
          guestSheetId = prefs.getString(AppConstants.prefCustomSpreadsheetId) ?? '';
          guestSheetUrl = prefs.getString(AppConstants.prefCustomSpreadsheetUrl) ?? '';
        }
      }

      final settings = WeddingSettings(
        spreadsheetId: spreadsheetId,
        spreadsheetUrl: prefs.getString(AppConstants.prefSpreadsheetUrl) ?? '',
        weddingDate: weddingDateStr.isNotEmpty
            ? DateTime.parse(weddingDateStr)
            : DateTime.now().add(const Duration(days: 365)),
        coupleNames: prefs.getString(AppConstants.prefCoupleNames) ?? '',
        userRole: prefs.getString(AppConstants.prefUserRole) ?? '',
        guestSheetId: guestSheetId,
        guestSheetUrl: guestSheetUrl,
      );
      if (mounted) state = AsyncValue.data(settings);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> save({
    required String spreadsheetId,
    required String spreadsheetUrl,
    required DateTime weddingDate,
    required String coupleNames,
    String userRole = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefSpreadsheetId, spreadsheetId);
    await prefs.setString(AppConstants.prefSpreadsheetUrl, spreadsheetUrl);
    await prefs.setString(AppConstants.prefWeddingDate, weddingDate.toIso8601String());
    await prefs.setString(AppConstants.prefCoupleNames, coupleNames);
    await prefs.setString(AppConstants.prefUserRole, userRole);
    await _load();
  }

  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserRole, role);
    await _load();
  }

  Future<void> saveGuestSheet({required String id, required String url}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefGuestSheetId, id);
    await prefs.setString(AppConstants.prefGuestSheetUrl, url);
    await _load();
  }

  Future<void> clearGuestSheet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefGuestSheetId);
    await prefs.remove(AppConstants.prefGuestSheetUrl);
    await _load();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefSpreadsheetId);
    await prefs.remove(AppConstants.prefSpreadsheetUrl);
    await prefs.remove(AppConstants.prefWeddingDate);
    await prefs.remove(AppConstants.prefCoupleNames);
    await prefs.remove(AppConstants.prefUserRole);
    await prefs.remove(AppConstants.prefGuestSheetId);
    await prefs.remove(AppConstants.prefGuestSheetUrl);
    if (mounted) state = const AsyncValue.data(null);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<WeddingSettings?>>(
  (ref) => SettingsNotifier(),
);
