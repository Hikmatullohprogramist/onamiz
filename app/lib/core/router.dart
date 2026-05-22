import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/onboarding/classification_screen.dart';
import '../screens/onboarding/pregnancy_setup_screen.dart';
import '../screens/trimester/trimester_dashboard.dart';

Future<String> _initialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final done  = prefs.getBool('onboarding_done') ?? false;
  return done ? '/dashboard' : '/';
}

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final done  = prefs.getBool('onboarding_done') ?? false;
    if (!done && state.matchedLocation == '/dashboard') {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const ClassificationScreen(),
    ),
    GoRoute(
      path: '/onboarding/pregnancy-setup',
      builder: (_, __) => const PregnancySetupScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const TrimesterDashboard(),
    ),
  ],
);
