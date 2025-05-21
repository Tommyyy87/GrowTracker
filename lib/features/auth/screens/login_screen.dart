import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_tracker/core/constants/app_colors.dart';
import 'package:grow_tracker/core/constants/app_strings.dart';
import 'package:grow_tracker/core/utils/validators.dart';
import 'package:grow_tracker/features/auth/controllers/auth_controller.dart';
import 'package:grow_tracker/features/auth/widgets/auth_button.dart';
import 'package:grow_tracker/features/auth/widgets/auth_input_field.dart';
import 'package:grow_tracker/features/auth/widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authController.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        if (mounted) {
          context.goNamed('dashboard');
        }
      } else {
        setState(() {
          _errorMessage =
              'Anmeldung fehlgeschlagen. Bitte überprüfe deine Eingaben.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ein Fehler ist aufgetreten: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await _authController.signInWithGoogle();
      // Bei Erfolg erfolgt die Weiterleitung automatisch
      if (mounted) {
        context.goNamed('dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google-Anmeldung fehlgeschlagen: $e';
      });
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Willkommen zurück!',
            style: TextStyle(color: Colors.white)),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.loginSubtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AuthInputField(
                      label: AppStrings.emailOrUsername,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateRequired,
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    AuthInputField(
                      label: AppStrings.password,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: Validators.validatePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Passwort-Wiederherstellung
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Passwort-Wiederherstellung wird bald implementiert.'),
                            ),
                          );
                        },
                        child: const Text(
                          AppStrings.forgotPassword,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    AuthButton(
                      text: AppStrings.loginButton,
                      onPressed: _login,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        AppStrings.orSignInWith,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SocialLoginButton(
                      onPressed: _loginWithGoogle,
                      isLoading: _isGoogleLoading,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          AppStrings.dontHaveAccount,
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            context.goNamed('register');
                          },
                          child: const Text(
                            AppStrings.signUp,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
