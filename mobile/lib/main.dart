import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'routes/app_router.dart';

/// AIVONITY - Intelligent Vehicle Assistant Ecosystem
/// Advanced Flutter application with innovative features
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  await _initializeApp();

  // Run the app with Riverpod provider scope and error handling
  runApp(
    const ProviderScope(
      child: AIVONITYApp(),
    ),
  );
}

/// Initialize all core application services
Future<void> _initializeApp() async {
  try {
    // Initialize logger first
    AppLogger.initialize();
    AppLogger.info('🚀 Starting AIVONITY application initialization');

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    AppLogger.info('✅ Application initialization completed successfully');
  } catch (e) {
    AppLogger.error('❌ Application initialization failed', e);
    debugPrint('❌ Application initialization failed: $e');
  }
}

class AIVONITYApp extends ConsumerWidget {
  const AIVONITYApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,

      // Theme configuration using our custom theme system
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Localization
      supportedLocales: AppConfig.supportedLocales,

      // Use GoRouter for navigation
      routerConfig: router,

      // Builder for global configurations
      builder: (context, child) {
        return MediaQuery(
          // Disable text scaling for consistent UI
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

