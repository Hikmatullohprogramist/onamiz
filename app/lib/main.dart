import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initializeDateFormatting("uz", "");

  // Notification → navigation callback: notif bosilganda to'g'ri route ochiladi
  NotificationService.setNavigationCallback((route) {
    appRouter.go(route);
  });

  try {
    await NotificationService.init();
  } catch (_) {
    // Native assets may not be linked on hot restart — full rebuild fixes this
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const OnamizApp());
}

class OnamizApp extends StatelessWidget {
  const OnamizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Onamiz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: appRouter,
    );
  }
}
