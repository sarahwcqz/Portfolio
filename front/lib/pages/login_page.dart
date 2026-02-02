import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//--------------------------------------- LOGIN WIDGET ----------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// contains logic + state of the page
class _LoginPageState extends State<LoginPage> {
  // Les "Controllers" permettent de récupérer ce que l'utilisateur tape dans les champs.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
 
  // Une variable pour savoir si on est en train de communiquer avec le serveur.
  bool _isLoading = false;

// ======================================= FUNCTIONS ======================================

  // ---------------------------------- SIGN IN ----------------------------------------
  Future<void> _signIn() async {
    // On passe l'état à "chargement" pour afficher le spinner.
    setState(() => _isLoading = true);
    try {
      // On demande à Supabase de vérifier l'email et le mot de passe.
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
     
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion réussie !')),
        );
      }
    } on AuthException catch (error) {
      // Si Supabase renvoie une erreur (ex: mauvais mot de passe), on l'affiche.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } finally {
      // Une fois terminé (succès ou erreur), on arrête le chargement.
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
              obscureText: true, // Hydes characters and displays points
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