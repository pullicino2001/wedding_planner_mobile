import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/onboarding/sign_in_screen.dart';
import '../screens/onboarding/setup_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/overview/overview_screen.dart';
import '../screens/budget/budget_detail_screen.dart';
import '../screens/budget/budget_form_screen.dart';
import '../screens/guests/guests_detail_screen.dart';
import '../screens/guests/guest_form_screen.dart';
import '../screens/vendors/vendors_detail_screen.dart';
import '../screens/vendors/vendor_form_screen.dart';
import '../screens/vendors/vendor_profile_screen.dart';
import '../screens/timeline/timeline_detail_screen.dart';
import '../screens/timeline/task_form_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../models/budget_item.dart';
import '../models/guest.dart';
import '../models/vendor.dart';
import '../models/task_item.dart';

// ─── Router notifier (bridges Riverpod auth state → GoRouter redirects) ──────

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, _) => notifyListeners());
    _ref.listen(settingsProvider, (_, _) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final settingsState = _ref.read(settingsProvider);

    // Still loading initial state — don't redirect yet
    if (authState.isLoading || settingsState.isLoading) return null;

    final isSignedIn = authState.value != null;
    final isSetUp = settingsState.value?.isComplete ?? false;
    final loc = state.matchedLocation;

    if (!isSignedIn) {
      return loc == '/sign-in' ? null : '/sign-in';
    }
    if (!isSetUp) {
      return loc == '/setup' ? null : '/setup';
    }
    // Signed in and set up — redirect away from auth/setup screens
    if (loc == '/' || loc == '/sign-in' || loc == '/setup') {
      return '/home/overview';
    }
    return null;
  }
}

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>(
  (ref) => RouterNotifier(ref),
);

// ─── Route index helper ────────────────────────────────────────────────────

int _shellIndex(String location) {
  if (location.startsWith('/home/budget')) return 1;
  if (location.startsWith('/home/guests')) return 2;
  if (location.startsWith('/home/vendors')) return 3;
  if (location.startsWith('/home/timeline')) return 4;
  return 0; // overview
}

// ─── Router ──────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Splash ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (_, _) => const SplashScreen(),
      ),

      // ── Auth / onboarding ─────────────────────────────────────────────────
      GoRoute(
        path: '/sign-in',
        builder: (_, _) => const SignInScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (_, _) => const SetupScreen(),
      ),

      // ── Main shell (bottom nav) ────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(
          selectedIndex: _shellIndex(state.matchedLocation),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/home/overview',
            builder: (_, _) => const OverviewScreen(),
          ),
          GoRoute(
            path: '/home/budget',
            builder: (_, _) => const BudgetDetailScreen(),
          ),
          GoRoute(
            path: '/home/guests',
            builder: (_, _) => const GuestsDetailScreen(),
          ),
          GoRoute(
            path: '/home/vendors',
            builder: (_, _) => const VendorsDetailScreen(),
          ),
          GoRoute(
            path: '/home/timeline',
            builder: (_, _) => const TimelineDetailScreen(),
          ),
        ],
      ),

      // ── Budget forms (no bottom nav) ──────────────────────────────────────
      GoRoute(
        path: '/budget/add',
        builder: (_, _) => const BudgetFormScreen(),
      ),
      GoRoute(
        path: '/budget/edit/:rowId',
        builder: (_, state) {
          final item = state.extra as BudgetItem?;
          return BudgetFormScreen(existing: item);
        },
      ),

      // ── Guest forms ────────────────────────────────────────────────────────
      GoRoute(
        path: '/guests/add',
        builder: (_, _) => const GuestFormScreen(),
      ),
      GoRoute(
        path: '/guests/edit/:rowId',
        builder: (_, state) {
          final guest = state.extra as Guest?;
          return GuestFormScreen(existing: guest);
        },
      ),

      // ── Vendor routes ──────────────────────────────────────────────────────
      GoRoute(
        path: '/vendors/add',
        builder: (_, _) => const VendorFormScreen(),
      ),
      GoRoute(
        path: '/vendors/view/:rowId',
        builder: (_, state) {
          final vendor = state.extra as Vendor?;
          if (vendor == null) return const VendorsDetailScreen();
          return VendorProfileScreen(vendor: vendor);
        },
      ),
      GoRoute(
        path: '/vendors/edit/:rowId',
        builder: (_, state) {
          final vendor = state.extra as Vendor?;
          return VendorFormScreen(existing: vendor);
        },
      ),

      // ── Settings (no bottom nav) ──────────────────────────────────────────
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
      ),

      // ── Task forms ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/timeline/add',
        builder: (_, _) => const TaskFormScreen(),
      ),
      GoRoute(
        path: '/timeline/edit/:rowId',
        builder: (_, state) {
          final task = state.extra as TaskItem?;
          return TaskFormScreen(existing: task);
        },
      ),
    ],
  );
});
