import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'app.dart';

void main() {
  FlutterError.onError =
      (details) => debugPrint('Flutter error: ${details.exceptionAsString()}');

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialise background services
    await NotificationService.init();
    await WidgetService.init();

    runApp(const ProviderScope(child: App()));
  }, (error, stack) => debugPrint('Unhandled error: $error'));
}
