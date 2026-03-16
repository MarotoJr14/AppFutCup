import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../home/user_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _teamController = TextEditingController();

  void _register() async {
    if (_formKey.currentState!.validate()) {

      final result = await AuthService.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        favouriteTeamId: 1, // provisional
      );

      if (result["success"]) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cuenta creada correctamente")),
        );

        Navigator.pop(context);

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
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "Nombre de usuario",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Introduce un nombre";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Correo electrónico (@pro2fp.es)",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Introduce un email";
                      }
                      if (!value.endsWith("@pro2fp.es")) {
                        return "Debe ser un correo @pro2fp.es";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Contraseña",
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return "Mínimo 6 caracteres";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _teamController,
                    decoration: const InputDecoration(
                      labelText: "Equipo favorito",
                    ),
                  ),
                  const SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: _register,
                    child: const Text("Crear cuenta"),
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