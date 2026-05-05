class BudgetItem {
  final String id;
  final String category;
  final String item;
  final double estimated;
  final double actual;
  final bool paid;
  final String notes;
  final int rowNumber;

  const BudgetItem({
    required this.id,
    required this.category,
    required this.item,
    required this.estimated,
    required this.actual,
    required this.paid,
    required this.notes,
    required this.rowNumber,
  });

  factory BudgetItem.fromSheetRow(List<String> row, int rowNumber) {
    return BudgetItem(
      id: _cell(row, 0),
      category: _cell(row, 1),
      item: _cell(row, 2),
      estimated: double.tryParse(_cell(row, 3)) ?? 0,
      actual: double.tryParse(_cell(row, 4)) ?? 0,
      paid: _cell(row, 5).toLowerCase() == 'true' || _cell(row, 5) == '1' || _cell(row, 5).toLowerCase() == 'yes',
      notes: _cell(row, 6),
      rowNumber: rowNumber,
    );
  }

  List<Object> toSheetRow() =>
      [id, category, item, estimated, actual, paid ? 'Yes' : 'No', notes];

  BudgetItem copyWith({
    String? category,
    String? item,
    double? estimated,
    double? actual,
    bool? paid,
    String? notes,
  }) {
    return BudgetItem(
      id: id,
      category: category ?? this.category,
      item: item ?? this.item,
      estimated: estimated ?? this.estimated,
      actual: actual ?? this.actual,
      paid: paid ?? this.paid,
      notes: notes ?? this.notes,
      rowNumber: rowNumber,
    );
  }

  static String _cell(List<String> row, int index) =>
      index < row.length ? row[index].trim() : '';
}

class BudgetStats {
  final double totalEstimated;
  final double totalActual;
  final double totalPaid;
  final int itemCount;

  const BudgetStats({
    required this.totalEstimated,
    required this.totalActual,
    required this.totalPaid,
    required this.itemCount,
  });

  double get spentProgress =>
      totalEstimated == 0 ? 0 : (totalActual / totalEstimated).clamp(0.0, 1.0);

  double get remaining => (totalEstimated - totalActual).clamp(0, double.infinity);

  factory BudgetStats.from(List<BudgetItem> items) {
    return BudgetStats(
      totalEstimated: items.fold(0, (s, i) => s + i.estimated),
      totalActual: items.fold(0, (s, i) => s + i.actual),
      totalPaid: items.where((i) => i.paid).fold(0, (s, i) => s + i.actual),
      itemCount: items.length,
    );
  }
}
