import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pfe_smart_clothing/core/di/injection.dart';
import 'package:pfe_smart_clothing/firebase_options.dart';

import 'package:pfe_smart_clothing/features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GoogleSignIn.instance.initialize(
    clientId: kIsWeb ? 'TON_WEB_CLIENT_ID.apps.googleusercontent.com' : null,
  );

  await initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Clothing Advisor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D28D9),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
