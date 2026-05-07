import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/animated_blob_background.dart';
import 'providers/router_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription<Uri?>? _widgetSub;

  @override
  void initState() {
    super.initState();
    _handleInitialWidgetLaunch();
    _widgetSub = HomeWidget.widgetClicked.listen(_onWidgetTapped);
  }

  @override
  void dispose() {
    _widgetSub?.cancel();
    super.dispose();
  }

  // Handle cold-start from widget tap
  Future<void> _handleInitialWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null) {
      _onWidgetTapped(uri);
    }
  }

  void _onWidgetTapped(Uri? uri) {
    if (uri == null) return;
    // Any widget tap navigates to the timeline screen
    final router = ref.read(routerProvider);
    router.go('/home/timeline');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Wedding Planner',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Stack(
        children: [
          const AnimatedBlobBackground(),
          child ?? const SizedBox(),
        ],
      ),
    );
  }
}
