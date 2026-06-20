import 'package:flutter/material.dart';

// Import the login screen from the screens folder.
import 'screens/login_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 📦 SUPABASE IMPORT
// This import lets us initialize Supabase when the app starts.
// It won't try to connect until we call Supabase.initialize() below.
// ──────────────────────────────────────────────────────────────────────────────
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 🔑 SUPABASE CREDENTIALS — PLACEHOLDER VALUES
//
// These are FAKE values right now. When you create your Supabase project,
// replace them with your REAL values from:
//   Supabase Dashboard → Settings → API
//
// ⚠️ SECURITY TIP: Before pushing to GitHub, move these to a .env file
//    or use --dart-define so you don't accidentally leak your keys!
//    See the README.md for instructions.
// ══════════════════════════════════════════════════════════════════════════════

void main() async {
  // This line is required before calling any async code in main().
  // Flutter needs this to set up its internal services first.
  WidgetsFlutterBinding.ensureInitialized();

  // ────────────────────────────────────────────────────────────────────────
  // 🔜 SUPABASE INITIALIZATION (uncomment when your Supabase project is ready):
  //
  // This connects your Flutter app to your Supabase backend.
  // Once you replace the URL and anon key above with real values,
  // uncomment the lines below and your app will connect to Supabase!
  // ────────────────────────────────────────────────────────────────────────
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 🟢 FOR NOW: App runs without Supabase — all data is dummy data
  // from the service files in lib/services/
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
      theme: ThemeData(primarySwatch: Colors.green),

      // LoginScreen is the first screen the user sees.
      home: const LoginScreen(),
    );
  }
}
