import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'maps_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  if (kIsWeb) {
    final mapsKey = dotenv.env['MAPS_API_KEY'] ?? '';
    loadMapsScript(mapsKey);
  } else {
    await GoogleSignIn.instance.initialize(
      clientId: const String.fromEnvironment('GOOGLE_CLIENT_ID'),
    );
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SahayakApp());
}

class SahayakApp extends StatelessWidget {
  const SahayakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahayak AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Something went wrong.\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return snap.hasData ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
