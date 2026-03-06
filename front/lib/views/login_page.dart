import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import 'map_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final controller = context.read<AuthController>();
    final savedEmail = await controller.loadSavedEmail();
    if (savedEmail != null) {
      _emailController.text = savedEmail;
    }
  }

  Future<void> _signIn() async {
    final controller = context.read<AuthController>();

    try {
      final success = await controller.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Connexion réussie !')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _signUp() async {
    final controller = context.read<AuthController>();

    try {
      final success = await controller.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vérifiez vos emails pour confirmer !')),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gets screen's size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // calculates sizes to be adaptative
    final logoSize = screenWidth * 0.5;
    final maxLogoSize = 250.0;
    final actualLogoSize = logoSize > maxLogoSize ? maxLogoSize : logoSize;

    final horizontalPadding = screenWidth * 0.05;
    final maxWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // allow scroll
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ------------------------------------- LOGO
                  Image.asset(
                    'assets/images/Logo_NOVI.png',
                    width: actualLogoSize,
                    height: actualLogoSize,
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // --------------------------------------- email
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // --------------------------------------- pwd
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // --------------------------------- BUTTONS --------------
                  Consumer<AuthController>(
                    builder: (context, controller, child) {
                      if (controller.isLoading) {
                        return const CircularProgressIndicator();
                      }
                      return Column(
                        children: [
                          // ---------------------------------- se connecter button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _signIn,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Se connecter',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ------------------------------------- creer un compte button
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _signUp,
                              child: const Text(
                                'Créer un compte',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
