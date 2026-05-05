import '../core/constants/app_constants.dart';

class Guest {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String rsvpStatus; // 'pending', 'confirmed', 'declined'
  final String mealChoice;
  final String dietary;
  final bool hasPlusOne;
  final String relation;
  final int rowNumber;

  const Guest({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.rsvpStatus,
    required this.mealChoice,
    required this.dietary,
    required this.hasPlusOne,
    required this.relation,
    required this.rowNumber,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Guest.fromSheetRow(List<String> row, int rowNumber) {
    return Guest(
      id: _cell(row, 0),
      firstName: _cell(row, 1),
      lastName: _cell(row, 2),
      email: _cell(row, 3),
      phone: _cell(row, 4),
      rsvpStatus: _cell(row, 5).isEmpty ? AppConstants.rsvpPending : _cell(row, 5),
      mealChoice: _cell(row, 6),
      dietary: _cell(row, 7),
      hasPlusOne: _cell(row, 8).toLowerCase() == 'true' || _cell(row, 8).toLowerCase() == 'yes',
      relation: _cell(row, 9),
      rowNumber: rowNumber,
    );
  }

  List<Object> toSheetRow() => [
        id,
        firstName,
        lastName,
        email,
        phone,
        rsvpStatus,
        mealChoice,
        dietary,
        hasPlusOne ? 'Yes' : 'No',
        relation,
      ];

  Guest copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? rsvpStatus,
    String? mealChoice,
    String? dietary,
    bool? hasPlusOne,
    String? relation,
  }) {
    return Guest(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      rsvpStatus: rsvpStatus ?? this.rsvpStatus,
      mealChoice: mealChoice ?? this.mealChoice,
      dietary: dietary ?? this.dietary,
      hasPlusOne: hasPlusOne ?? this.hasPlusOne,
      relation: relation ?? this.relation,
      rowNumber: rowNumber,
    );
  }

  static String _cell(List<String> row, int index) =>
      index < row.length ? row[index].trim() : '';
}

class GuestStats {
  final int total;
  final int confirmed;
  final int declined;
  final int pending;

  const GuestStats({
    required this.total,
    required this.confirmed,
    required this.declined,
    required this.pending,
  });

  double get confirmedProgress =>
      total == 0 ? 0 : (confirmed / total).clamp(0.0, 1.0);

  factory GuestStats.from(List<Guest> guests) {
    return GuestStats(
      total: guests.length,
      confirmed: guests.where((g) => g.rsvpStatus == AppConstants.rsvpConfirmed).length,
      declined: guests.where((g) => g.rsvpStatus == AppConstants.rsvpDeclined).length,
      pending: guests.where((g) => g.rsvpStatus == AppConstants.rsvpPending).length,
    );
  }
}
