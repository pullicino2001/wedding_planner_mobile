import 'dart:convert';

class TeamDuty {
  final String phase; // 'Church' | 'Venue' | 'General'
  final String description;

  const TeamDuty({required this.phase, required this.description});

  Map<String, dynamic> toJson() => {'phase': phase, 'desc': description};

  factory TeamDuty.fromJson(Map<String, dynamic> json) => TeamDuty(
        phase: (json['phase'] as String?) ?? 'General',
        description: (json['desc'] as String?) ?? '',
      );
}

class TeamMember {
  final String id;
  final String name;
  final String phone;
  final String roleTitle;
  final List<TeamDuty> duties;
  final String linkedVendorCategory; // empty = none
  final bool pullsDietary;
  final int rowNumber;

  const TeamMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.roleTitle,
    required this.duties,
    required this.linkedVendorCategory,
    required this.pullsDietary,
    required this.rowNumber,
  });

  List<TeamDuty> dutiesForPhase(String phase) =>
      duties.where((d) => d.phase == phase).toList();

  factory TeamMember.fromSheetRow(List<String> row, int rowNumber) {
    List<TeamDuty> duties = [];
    final raw = _cell(row, 4);
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        duties = decoded
            .map((e) => TeamDuty.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return TeamMember(
      id: _cell(row, 0),
      name: _cell(row, 1),
      phone: _cell(row, 2),
      roleTitle: _cell(row, 3),
      duties: duties,
      linkedVendorCategory: _cell(row, 5),
      pullsDietary: _cell(row, 6).toLowerCase() == 'true',
      rowNumber: rowNumber,
    );
  }

  List<Object> toSheetRow() => [
        id,
        name,
        phone,
        roleTitle,
        duties.isEmpty ? '' : jsonEncode(duties.map((d) => d.toJson()).toList()),
        linkedVendorCategory,
        pullsDietary ? 'true' : 'false',
      ];

  TeamMember copyWith({
    String? name,
    String? phone,
    String? roleTitle,
    List<TeamDuty>? duties,
    String? linkedVendorCategory,
    bool? pullsDietary,
  }) =>
      TeamMember(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        roleTitle: roleTitle ?? this.roleTitle,
        duties: duties ?? this.duties,
        linkedVendorCategory:
            linkedVendorCategory ?? this.linkedVendorCategory,
        pullsDietary: pullsDietary ?? this.pullsDietary,
        rowNumber: rowNumber,
      );

  static String _cell(List<String> row, int index) =>
      index < row.length ? row[index].trim() : '';
}
