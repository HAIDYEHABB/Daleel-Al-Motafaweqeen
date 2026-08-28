import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  // Firebase must finish initializing before any screen tries to touch
  // FirebaseAuth/Firestore, so we await it here before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DaleelApp());
}

class DaleelApp extends StatelessWidget {
  const DaleelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دليل المتفوقين',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Force RTL for the whole app regardless of device locale, since
      // this app is Arabic-only for now.
      locale: const Locale('ar'),
      localizationsDelegates: const [
        // Global*, not Default* — these come from flutter_localizations
        // and actually contain Arabic translations. Default* only knows
        // English and will crash/fall back when locale is 'ar'.
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      // Real entry point: AuthGate checks whether Firebase already has
      // a signed-in user (persisted session) and restores Session
      // (session.dart) accordingly before routing — falls back to
      // LoginScreen if not signed in. See auth_gate.dart.
      home: const AuthGate(),
    );
  }
}
