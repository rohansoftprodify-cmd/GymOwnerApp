import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/features/auth/login_page.dart';
import 'package:gym_owner_app/src/features/attendance/attendance_history_page.dart';
import 'package:gym_owner_app/src/features/dashboard/dashboard_page.dart';
import 'package:gym_owner_app/src/features/members/members_page.dart';
import 'package:gym_owner_app/src/features/onboarding/onboarding_page.dart';
import 'package:gym_owner_app/src/features/profile/gym_profile_page.dart';
import 'package:gym_owner_app/src/features/profile/gym_profile_section_page.dart';
import 'package:gym_owner_app/src/features/profile/profile_section.dart';
import 'package:gym_owner_app/src/features/setup/gym_owner_setup_page.dart';
import 'package:gym_owner_app/src/features/splash/splash_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(path: '/splash', builder: (_, state) => const SplashPage()),
    GoRoute(path: '/onboarding', builder: (_, state) => const OnboardingPage()),
    GoRoute(path: '/login', builder: (_, state) => const LoginPage()),
    GoRoute(path: '/owner-setup', builder: (_, state) => const GymOwnerSetupPage()),
    GoRoute(path: '/', builder: (_, state) => const DashboardPage()),
    GoRoute(
      path: '/attendance-history',
      builder: (_, state) {
        final gymId = state.uri.queryParameters['gymId'];
        if (gymId == null || gymId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Missing gym id')));
        }
        return AttendanceHistoryPage(gymId: gymId);
      },
    ),
    GoRoute(
      path: '/members',
      builder: (_, state) {
        final gymId = state.uri.queryParameters['gymId'];
        if (gymId == null || gymId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Missing gym id')));
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Members')),
          body: MembersPage(gymId: gymId),
        );
      },
    ),
    GoRoute(
      path: '/gym-profile',
      builder: (_, state) {
        final gymId = state.uri.queryParameters['gymId'];
        if (gymId == null || gymId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Missing gym id')));
        }
        return GymProfilePage(gymId: gymId);
      },
      routes: [
        GoRoute(
          path: 'section',
          builder: (_, state) {
            final gymId = state.uri.queryParameters['gymId'];
            final section = ProfileSection.fromQuery(state.uri.queryParameters['section']);
            if (gymId == null || gymId.isEmpty || section == null) {
              return const Scaffold(body: Center(child: Text('Invalid section')));
            }
            return GymProfileSectionPage(gymId: gymId, section: section);
          },
        ),
      ],
    ),
  ],
);
