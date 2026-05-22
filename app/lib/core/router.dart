import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final done  = prefs.getBool('onboarding_done') ?? false;
    if (!done && state.matchedLocation == '/dashboard') return '/';
    if (done  && state.matchedLocation == '/')         return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/',          builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
  ],
);
