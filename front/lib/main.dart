// visual components
import 'package:flutter/material.dart';
// supabase connexion
import 'package:supabase_flutter/supabase_flutter.dart';
// .env for keys
import 'package:flutter_dotenv/flutter_dotenv.dart';
//provider
import 'package:provider/provider.dart';
// login page
import 'views/login_page.dart';
import 'controllers/auth_controller.dart';
import 'controllers/address_search_controller.dart';
import 'controllers/location_controller.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/reports_controller.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => AddressSearchController()),
        ChangeNotifierProvider(create: (_) => LocationController()),
        ChangeNotifierProvider(create: (_) => NavigationController()),
        ChangeNotifierProvider(create: (_) => ReportController()),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Novi',
        theme: ThemeData.dark(),
        home: const LoginPage(),
      ),
    );
  }
}
