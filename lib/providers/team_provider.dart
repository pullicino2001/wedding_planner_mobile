import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/team_member.dart';
import 'sheets_service_provider.dart';

const _uuid = Uuid();

class TeamNotifier extends StateNotifier<AsyncValue<List<TeamMember>>> {
  final Ref _ref;

  TeamNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final service = await _ref.read(sheetsServiceProvider.future);
      if (!mounted) return;
      if (service == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final members = await service.getTeamMembers();
      if (mounted) state = AsyncValue.data(members);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> addMember({
    required String name,
    required String phone,
    required String roleTitle,
    List<TeamDuty> duties = const [],
    String linkedVendorCategory = '',
    bool pullsDietary = false,
  }) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    final member = TeamMember(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      roleTitle: roleTitle,
      duties: duties,
      linkedVendorCategory: linkedVendorCategory,
      pullsDietary: pullsDietary,
      rowNumber: 0,
    );
    await service.addTeamMember(member);
    await _load();
  }

  Future<void> updateMember(TeamMember member) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    await service.updateTeamMember(member);
    await _load();
  }

  Future<void> deleteMember(TeamMember member) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    await service.deleteTeamMember(member.rowNumber);
    await _load();
  }
}

final teamProvider =
    StateNotifierProvider.autoDispose<TeamNotifier, AsyncValue<List<TeamMember>>>(
  (ref) => TeamNotifier(ref),
);
