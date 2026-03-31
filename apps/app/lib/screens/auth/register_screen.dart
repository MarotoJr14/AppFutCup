import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _obscure       = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).register(
      _usernameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    final auth = ref.read(authProvider);
    auth.whenOrNull(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada. Inicia sesión.'), backgroundColor: AppColors.success),
        );
        context.go('/login');
      },
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error, duration: const Duration(seconds: 3)),
      ),
    );
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Campo requerido';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Debe contener una mayúscula';
    if (!v.contains(RegExp(r'[a-z]'))) return 'Debe contener una minúscula';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Debe contener un número';
    if (!v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) return 'Debe contener un carácter especial';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider) is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Back button row
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => context.go('/login'),
              ),
            ),
            // Scrollable form
            Expanded(
              child: SingleChildScrollView(
                padding : EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo centered
                      Center(
                        child: Image.asset(AppAssets.logoForTheme(context), height: 90),
                      ),
                      SizedBox(height: 24),
                      Text('Crear cuenta', style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 20),
                      _field(_usernameCtrl, AppStrings.username, Icons.person_outline,
                          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null),
                      SizedBox(height: 14),
                      _field(_emailCtrl, AppStrings.email, Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Campo requerido';
                            if (!v.endsWith('@pro2fp.es')) return 'El email debe ser @pro2fp.es';
                            return null;
                          }),
                      SizedBox(height: 14),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        style: TextStyle(color: AppColors.onSurface),
                        validator: _validatePassword,
                        decoration: _deco(AppStrings.password, Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.hint),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• Mínimo 8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 carácter especial',
                        style: TextStyle(color: AppColors.hint, fontSize: 11),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                          ),
                          child: isLoading
                              ? CircularProgressIndicator(color: AppColors.onPrimary)
                              : Text(AppStrings.register, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            // Banner pinned to bottom
            Image.asset(
              'assets/images/futcup2026_banner.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.onSurface),
      decoration: _deco(label, icon),
      validator: validator,
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: AppColors.hint),
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary)),
  );
}
