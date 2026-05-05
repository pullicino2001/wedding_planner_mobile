import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guest.dart';
import '../core/constants/app_constants.dart';
import 'sheets_service_provider.dart';
import 'settings_provider.dart';

const _kPollInterval = Duration(seconds: 30);

class GuestsNotifier extends StateNotifier<AsyncValue<List<Guest>>> {
  final Ref _ref;
  Timer? _pollTimer;

  GuestsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _silentRefresh());
  }

  Future<List<Guest>> _fetch() async {
    final settings = _ref.read(settingsProvider).value;
    if (settings == null || !settings.hasGuestSheet) return [];
    final service = await _ref.read(guestSheetsServiceProvider.future);
    if (service == null) return [];
    return service.getGuestsCustom();
  }

  Future<void> _load() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final guests = await _fetch();
      if (mounted) state = AsyncValue.data(guests);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final guests = await _fetch();
      if (mounted) state = AsyncValue.data(guests);
    } catch (_) {
      // Silently ignore poll errors — user can pull-to-refresh manually
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // Guest list is always read-only — these are no-ops kept for compile safety.
  Future<void> addGuest({
    required String firstName,
    required String lastName,
    String email = '',
    String phone = '',
    String rsvpStatus = AppConstants.rsvpPending,
    String mealChoice = '',
    String dietary = '',
    bool hasPlusOne = false,
    String relation = '',
  }) async {}

  Future<void> updateGuest(Guest guest) async {}

  Future<void> deleteGuest(Guest guest) async {}
}

final guestsProvider =
    StateNotifierProvider.autoDispose<GuestsNotifier, AsyncValue<List<Guest>>>(
  (ref) => GuestsNotifier(ref),
);

final guestStatsProvider = Provider.autoDispose<GuestStats>((ref) {
  final guests = ref.watch(guestsProvider).value ?? [];
  return GuestStats.from(guests);
});

/// Custom relation categories added by the user during this session.
final customRelationsProvider = StateProvider<List<String>>((ref) => []);
