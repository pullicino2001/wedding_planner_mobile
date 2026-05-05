class ChecklistItem {
  final String id;
  final String item;
  final String destination; // 'church' | 'venue'
  final String personName;
  final bool inHand;
  final bool packed;
  final String notes;
  final int rowNumber;

  const ChecklistItem({
    required this.id,
    required this.item,
    required this.destination,
    required this.personName,
    required this.inHand,
    required this.packed,
    required this.notes,
    required this.rowNumber,
  });

  factory ChecklistItem.fromSheetRow(List<String> row, int rowNumber) {
    return ChecklistItem(
      id: _cell(row, 0),
      item: _cell(row, 1),
      destination: _cell(row, 2),
      personName: _cell(row, 3),
      inHand: _cell(row, 4).toLowerCase() == 'true',
      packed: _cell(row, 5).toLowerCase() == 'true',
      notes: _cell(row, 6),
      rowNumber: rowNumber,
    );
  }

  List<Object> toSheetRow() => [
        id,
        item,
        destination,
        personName,
        inHand ? 'true' : 'false',
        packed ? 'true' : 'false',
        notes,
      ];

  ChecklistItem copyWith({
    String? item,
    String? destination,
    String? personName,
    bool? inHand,
    bool? packed,
    String? notes,
  }) =>
      ChecklistItem(
        id: id,
        item: item ?? this.item,
        destination: destination ?? this.destination,
        personName: personName ?? this.personName,
        inHand: inHand ?? this.inHand,
        packed: packed ?? this.packed,
        notes: notes ?? this.notes,
        rowNumber: rowNumber,
      );

  static String _cell(List<String> row, int index) =>
      index < row.length ? row[index].trim() : '';
}
