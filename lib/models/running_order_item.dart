class RunningOrderItem {
  final String id;
  final String time; // HH:MM 24h
  final String phase; // 'Getting Ready' | 'Church' | 'Reception'
  final String description;
  final String notes;
  final int rowNumber;

  const RunningOrderItem({
    required this.id,
    required this.time,
    required this.phase,
    required this.description,
    required this.notes,
    required this.rowNumber,
  });

  factory RunningOrderItem.fromSheetRow(List<String> row, int rowNumber) {
    return RunningOrderItem(
      id: _cell(row, 0),
      time: _cell(row, 1),
      phase: _cell(row, 2),
      description: _cell(row, 3),
      notes: _cell(row, 4),
      rowNumber: rowNumber,
    );
  }

  List<Object> toSheetRow() => [id, time, phase, description, notes];

  RunningOrderItem copyWith({
    String? time,
    String? phase,
    String? description,
    String? notes,
  }) =>
      RunningOrderItem(
        id: id,
        time: time ?? this.time,
        phase: phase ?? this.phase,
        description: description ?? this.description,
        notes: notes ?? this.notes,
        rowNumber: rowNumber,
      );

  // Sort key: numeric HH*60+MM for time ordering within a phase
  int get minuteOfDay {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  static String _cell(List<String> row, int index) =>
      index < row.length ? row[index].trim() : '';
}
