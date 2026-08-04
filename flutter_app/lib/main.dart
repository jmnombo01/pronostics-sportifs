import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'services/fcm_service.dart';
import 'ui/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialisé en mode simulation ou hors ligne : $e');
  }

  runApp(
    const ProviderScope(
      child: PronosticsApp(),
    ),
  );
}

class PronosticsApp extends ConsumerStatefulWidget {
  const PronosticsApp({super.key});

  @override
  ConsumerState<PronosticsApp> createState() => _PronosticsAppState();
}

class _PronosticsAppState extends ConsumerState<PronosticsApp> {
  @override
  void initState() {
    super.initState();
    _initializeFcm();
  }

  void _initializeFcm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fcmService = FcmService(ref.read(apiServiceProvider));
      fcmService.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Frogazz Sport Analyse - VIP & Montante',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
