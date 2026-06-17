import 'package:flutter/material.dart';

// Import the login screen from the screens folder.
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove the debug banner in the top-right corner.
      debugShowCheckedModeBanner: false,

      // Set the app's theme to use your green primary color.
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),

      // LoginScreen is the first screen the user sees.
      home: const LoginScreen(),
    );
  }
}
