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
import '../screens/vendors/vendors_detail_screen.dart';
import '../screens/vendors/vendor_form_screen.dart';
import '../screens/vendors/vendor_profile_screen.dart';
import '../screens/timeline/timeline_detail_screen.dart';
import '../screens/timeline/task_form_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/day_of/day_of_screen.dart';
import '../screens/day_of/running_order_form_screen.dart';
import '../screens/day_of/team_member_form_screen.dart';
import '../screens/day_of/team_member_brief_screen.dart';
import '../screens/day_of/checklist_form_screen.dart';
import '../models/budget_item.dart';
import '../models/vendor.dart';
import '../models/task_item.dart';
import '../models/running_order_item.dart';
import '../models/team_member.dart';
import '../models/checklist_item.dart';
import '../core/constants/role_templates.dart';

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

      // ── Main shell (bottom nav) — StatefulShellRoute keeps all tabs mounted ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          selectedIndex: navigationShell.currentIndex,
          onTabSelected: (i) => navigationShell.goBranch(i),
          child: navigationShell,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/overview',
              builder: (_, _) => const OverviewScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/budget',
              builder: (_, _) => const BudgetDetailScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/guests',
              builder: (_, _) => const GuestsDetailScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/vendors',
              builder: (_, _) => const VendorsDetailScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/timeline',
              builder: (_, _) => const TimelineDetailScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/dayof',
              builder: (_, _) => const DayOfScreen(),
            ),
          ]),
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

      // ── Day Of routes ──────────────────────────────────────────────────────
      GoRoute(
        path: '/dayof/running-order/add',
        builder: (_, _) => const RunningOrderFormScreen(),
      ),
      GoRoute(
        path: '/dayof/running-order/edit/:id',
        builder: (_, state) {
          final item = state.extra as RunningOrderItem?;
          return RunningOrderFormScreen(existing: item);
        },
      ),
      GoRoute(
        path: '/dayof/team/add',
        builder: (_, state) {
          final template = state.extra as RoleTemplate?;
          return TeamMemberFormScreen(template: template);
        },
      ),
      GoRoute(
        path: '/dayof/team/edit/:id',
        builder: (_, state) {
          final member = state.extra as TeamMember?;
          return TeamMemberFormScreen(existing: member);
        },
      ),
      GoRoute(
        path: '/dayof/team/brief/:id',
        builder: (_, state) {
          final member = state.extra as TeamMember?;
          if (member == null) return const DayOfScreen();
          return TeamMemberBriefScreen(member: member);
        },
      ),
      GoRoute(
        path: '/dayof/checklist/add',
        builder: (_, _) => const ChecklistFormScreen(),
      ),
      GoRoute(
        path: '/dayof/checklist/edit/:id',
        builder: (_, state) {
          final item = state.extra as ChecklistItem?;
          return ChecklistFormScreen(existing: item);
        },
      ),
    ],
  );
});
