import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'Screens/login.dart';
import 'Screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriVision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF4F9F4),
      ),
      // Redirect to home if user is already logged in
      home: FirebaseAuth.instance.currentUser != null
          ? const MainShell()
          : const LoginScreen(),
      routes: {
        '/home': (context) => const MainShell(),
      },
    );
  }
}
