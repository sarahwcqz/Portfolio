// visual components
import 'package:flutter/material.dart';
// supabase connexion
import 'package:supabase_flutter/supabase_flutter.dart';
// .env for keys
import 'package:flutter_dotenv/flutter_dotenv.dart';
// login page
import './pages/login_page.dart';

// ---------------------------------------------- INIT (supabase + keys) -------------------------------------------------
Future<void> main() async {
  //async init
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

// alias to use 'supabase'
final supabase = Supabase.instance.client;



// ---------------------------------------------- ROOT WIDGET -------------------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // basic construction of root widget
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Allygo',
      theme: ThemeData.dark(),
      home: const LoginPage(),
    );
  }
}