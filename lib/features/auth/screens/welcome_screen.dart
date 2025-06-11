import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widgets/app_logo.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../widgets/auth_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 40),
                const Column(
                  children: [
                    AppLogo(size: 100),
                    SizedBox(height: 24),
                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Willkommen bei ${AppStrings.appName}!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    AuthButton(
                      text: AppStrings.loginButton,
                      onPressed: () => context.pushNamed('login'),
                      isPrimary: false,
                    ),
                    const SizedBox(height: 16),
                    AuthButton(
                      text: AppStrings.registerButton,
                      onPressed: () => context.pushNamed('register'),
                    ),
                    const SizedBox(height: 32),
                    // Auskommentiert, um "Überspringen" zu entfernen, wie vom Benutzer gewünscht
                    // TextButton(
                    //   onPressed: () {
                    //     context.goNamed('dashboard');
                    //   },
                    //   child: const Text(
                    //     AppStrings.skipButton,
                    //     style: TextStyle(color: Colors.white70),
                    //   ),
                    // ),
                    const SizedBox(height: 32),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
