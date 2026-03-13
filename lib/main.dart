import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'objectbox/objectbox_setup.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  await init();
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e. Did you run flutterfire configure?');
  }

  // Initialize ObjectBox (placeholder)
  await ObjectBoxSetup.init();

  try {
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '1070399594044-mfor5alkk5o73j2cp1gc6ukoph4a3if0.apps.googleusercontent.com',
    );
  } catch (e) {
    debugPrint('GoogleSignIn init error: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Office Time Tracker',
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: authState.isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
