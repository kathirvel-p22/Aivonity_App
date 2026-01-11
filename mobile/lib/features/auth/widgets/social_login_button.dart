import 'package:flutter/material.dart';

/// Social Login Button Widget
/// Reusable button for social authentication providers
class SocialLoginButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.iconPath,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
    this.borderColor = Colors.grey,
  });

  /// Google Sign-In Button
  factory SocialLoginButton.google({
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SocialLoginButton(
      text: 'Continue with Google',
      iconPath: 'assets/icons/google_logo.png',
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      borderColor: Colors.grey.shade300,
    );
  }

  /// Apple Sign-In Button
  factory SocialLoginButton.apple({
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SocialLoginButton(
      text: 'Continue with Apple',
      iconPath: 'assets/icons/apple_logo.png',
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      borderColor: Colors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Use icon instead of image for simplicity
                  Icon(
                    _getIconForProvider(),
                    size: 24,
                    color: textColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  IconData _getIconForProvider() {
    if (text.contains('Google')) {
      return Icons.g_mobiledata;
    } else if (text.contains('Apple')) {
      return Icons.apple;
    }
    return Icons.login;
  }
}

