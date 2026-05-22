import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/shell/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Splash — redirect ichida emas, widget ichida hal qiladi
    GoRoute(
      path: '/splash',
      pageBuilder: (_, state) => NoTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
      ),
    ),

    // Onboarding
    GoRoute(
      path: '/',
      pageBuilder: (_, state) => _fade(state.pageKey, const OnboardingScreen()),
    ),

    // Main shell (bottom nav)
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (_, state) => _fade(state.pageKey, const DashboardScreen()),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (_, state) => _fade(state.pageKey, const HistoryScreen()),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (_, state) => _fade(state.pageKey, const CalendarScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (_, state) => _fade(state.pageKey, const ProfileScreen()),
        ),
      ],
    ),
  ],
);

CustomTransitionPage<void> _fade(LocalKey key, Widget child) =>
    CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      ),
    );
