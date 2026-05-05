import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';

/// Pushes updated task data to the home screen widget.
class WidgetService {
  static const _androidProvider = 'WeddingWidgetProvider';
  static const _appGroup = 'group.com.marriage.thebigm';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroup);
  }

  static Future<void> update(List<TaskItem> tasks) async {
    // Upcoming, not-done tasks sorted by date
    final upcoming = tasks
        .where((t) => !t.isDone && t.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    // Write up to 3 task slots
    for (var i = 0; i < 3; i++) {
      if (i < upcoming.length) {
        final t = upcoming[i];
        await HomeWidget.saveWidgetData('task_${i}_title', t.title);
        await HomeWidget.saveWidgetData(
          'task_${i}_date',
          DateFormat('d MMM').format(t.dueDate!),
        );
        await HomeWidget.saveWidgetData('task_${i}_assignee', t.assignedTo);
        await HomeWidget.saveWidgetData('task_${i}_visible', true);
      } else {
        await HomeWidget.saveWidgetData('task_${i}_title', '');
        await HomeWidget.saveWidgetData('task_${i}_date', '');
        await HomeWidget.saveWidgetData('task_${i}_assignee', '');
        await HomeWidget.saveWidgetData('task_${i}_visible', false);
      }
    }

    final hasAny = upcoming.isNotEmpty;
    await HomeWidget.saveWidgetData('has_tasks', hasAny);

    await HomeWidget.updateWidget(
      androidName: _androidProvider,
      iOSName: 'WeddingWidget',
    );
  }
}
