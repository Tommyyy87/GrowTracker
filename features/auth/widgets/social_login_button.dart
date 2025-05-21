import 'package:flutter/material.dart';
import 'package:grow_tracker/core/constants/app_strings.dart';
import 'package:grow_tracker/core/constants/assets_path.dart';

class SocialLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Image.asset(
              AssetsPath.googleIcon,
              width: 24,
              height: 24,
            ),
      label: const Text(
        AppStrings.googleSignIn,
        style: TextStyle(color: Colors.black87),
      ),
    );
  }
}
