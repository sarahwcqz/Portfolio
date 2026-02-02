import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './map_page.dart';


//--------------------------------------- LOGIN WIDGET ----------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// contains logic + state of the page
class _LoginPageState extends State<LoginPage> {
  // controllers to get what user inputs
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
 
  // loading flag to display loading circle later
  bool _isLoading = false;

// ======================================= FUNCTIONS ======================================

  // ---------------------------------- SIGN IN ----------------------------------------
  Future<void> _signIn() async {
    // set loading flag to 'loading'
    setState(() => _isLoading = true);
    try {
      // Supabase verifies email + pswd
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
     
      // if connection successful
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion réussie !')),
        );
        // redirect to MapPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
        );
      }
    // if connection failed
    } on AuthException catch (error) {
      // display error msg
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } finally {
      // set loading flag to 'off'
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --------------------------------- SIGN UP ----------------------------------------
  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      // use Supabase to create new user
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // on success => mail confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vérifiez vos emails pour confirmer !')),
        );
      }
    // if failure => display error message
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    // update state flag
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ----------------------------------- CONTROLLERS DISPOSAL ----------------------------------
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

// =============================================== UI ===========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ------------------------------- email -------------------------------------
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            // -------------------------------- password ----------------------------------
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true, // Hydes characters and displays points (privacy of pswd)
            ),
            const SizedBox(height: 20),
           
            // If loading => loading circle
            if (_isLoading)
              const CircularProgressIndicator()
            // else => diplay buttons
            else ...[
              ElevatedButton(
                onPressed: _signIn,
                child: const Text('Se connecter'),
              ),
              TextButton(
                onPressed: _signUp,
                child: const Text('Créer un compte'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}