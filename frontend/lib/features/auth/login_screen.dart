import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'auth_service.dart';
import '../home/org_home_screen.dart';
import '../home/user_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    if (_formKey.currentState!.validate()) {

      final result = await AuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (result["success"]) {

        await AuthService.saveSession(
          token: result["token"],
          role: result["role"],
        );

        if (!mounted) return;

        if (result["role"] == "org") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const OrgHomeScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const UserHomeScreen(),
            ),
          );
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["message"])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          elevation: 5,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "FutCup 2026",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Correo electrónico",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Introduce tu email";
                      }
                      else if (!value.endsWith("@pro2fp.es")) {
                        return "El email debe ser @pro2fp.es";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Contraseña",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Introduce tu contraseña";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: const Text("Iniciar sesión"),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text("Crear cuenta"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}