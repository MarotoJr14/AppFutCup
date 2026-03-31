import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _obscure    = true;
  bool _remember   = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_login') ?? false;
    if (remember) {
      _emailCtrl.text = prefs.getString('saved_email') ?? '';
      _passCtrl.text = prefs.getString('saved_password') ?? '';
      _remember = true;
      setState(() {});
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_remember) {
      await prefs.setBool('remember_login', true);
      await prefs.setString('saved_email', _emailCtrl.text.trim());
      await prefs.setString('saved_password', _passCtrl.text);
    } else {
      await prefs.setBool('remember_login', false);
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    final auth = ref.read(authProvider);
    auth.whenOrNull(
      data: (user) {
        if (user != null) {
          _saveData();
          context.go('/home');
        }
      },
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error, duration: const Duration(seconds: 3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider) is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable form fills remaining space
            Expanded(
              child: SingleChildScrollView(
                padding : EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      Image.asset(AppAssets.logoForTheme(context), height: 120),
                      SizedBox(height: 40),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: AppColors.onSurface),
                        decoration: _inputDeco(AppStrings.email, Icons.email_outlined),
                        validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        style: TextStyle(color: AppColors.onSurface),
                        decoration: _inputDeco(AppStrings.password, Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.hint,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _remember,
                            onChanged: (value) {
                              setState(() {
                                _remember = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            checkColor: AppColors.onPrimary,
                          ),
                          Text(
                            AppStrings.rememberMe,
                            style: TextStyle(color: AppColors.onSurface),
                          ),
                        ],
                      ),
                      SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                          ),
                          child: isLoading
                              ? CircularProgressIndicator(color: AppColors.onPrimary)
                              : Text(AppStrings.login, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text(AppStrings.register, style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Banner pinned to bottom, full width, same as AppFooter
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

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
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
