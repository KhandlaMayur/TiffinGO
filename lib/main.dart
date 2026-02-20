import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/landing_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/order_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/firebase_auth_provider.dart';
import 'providers/firestore_order_provider.dart';
import 'providers/firestore_subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/network_provider.dart';
import 'services/offline_operation_service.dart';
import 'widgets/network_poor_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize offline operation service for data persistence
  final offlineService = OfflineOperationService();
  await offlineService.initialize();

  // Configure platform-specific WebView settings
  if (WebViewPlatform.instance != null) {
    try {
      if (Platform.isAndroid) {
        const PlatformWebViewControllerCreationParams params =
            PlatformWebViewControllerCreationParams();
        final WebViewController controller =
            WebViewController.fromPlatformCreationParams(params);
        // Apply Android-specific settings
        final AndroidWebViewController androidController =
            controller.platform as AndroidWebViewController;
        androidController.setMediaPlaybackRequiresUserGesture(false);
      } else if (Platform.isIOS) {
        const PlatformWebViewControllerCreationParams params =
            PlatformWebViewControllerCreationParams();
        final WebViewController controller =
            WebViewController.fromPlatformCreationParams(params);
        // Apply iOS-specific settings
        final WebKitWebViewController webKitController =
            controller.platform as WebKitWebViewController;
        webKitController.setAllowsBackForwardNavigationGestures(true);
      }
    } catch (e) {
      // If platform implementations are not available (e.g., during unit tests),
      // ignore and continue — the assertion will be raised only when a WebView is created.
      debugPrint('WebView platform initialization error: $e');
    }
  }

  runApp(const TiffineApp());
}

class TiffineApp extends StatefulWidget {
  const TiffineApp({super.key});

  @override
  State<TiffineApp> createState() => _TiffineAppState();
}

class _TiffineAppState extends State<TiffineApp> {
  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FirebaseAuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => FirestoreOrderProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => FirestoreSubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Network monitoring provider
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
        // Offline operations service for data persistence
        ChangeNotifierProvider(create: (_) => OfflineOperationService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Tiffine Service',
            theme: themeProvider.currentTheme,
            darkTheme: themeProvider.currentTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const LandingScreen(),
            },
            debugShowCheckedModeBanner: false,
            // Builder wraps the entire app with network monitoring
            // The NetworkPoorOverlay displays a centered "Poor Connection"
            // message that blocks all user interaction when needed
            builder: (context, child) {
              return Stack(
                children: [
                  SizedBox.expand(child: child),
                  const NetworkPoorOverlay(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
