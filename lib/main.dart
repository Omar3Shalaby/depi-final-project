import 'package:flutter/material.dart';
import 'Screens/login.dart';
import 'Screens/main_shell.dart';

void main() {
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
      // Change to LoginScreen() once auth flow is ready
      home: const LoginScreen(),
      routes: {
        '/home': (context) => const MainShell(),
      },
    );
  }
}
