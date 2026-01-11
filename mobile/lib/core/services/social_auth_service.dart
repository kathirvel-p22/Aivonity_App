import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/auth_models.dart';
import '../utils/logger.dart';

/// Social Authentication Service
/// Handles Google Sign-In and Apple Sign-In integration
class SocialAuthService with LoggingMixin {
  GoogleSignIn? _googleSignIn;

  SocialAuthService() {
    _initializeGoogleSignIn();
  }

  /// Initialize Google Sign-In
  void _initializeGoogleSignIn() {
    try {
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
        // Add your Google OAuth client ID here for web
        // clientId: kIsWeb ? 'your-web-client-id' : null,
      );
    } catch (e) {
      logError('Google Sign-In initialization failed', e);
      _googleSignIn = null;
    }
  }

  /// Sign in with Google
  Future<SocialLoginData?> signInWithGoogle() async {
    if (_googleSignIn == null) {
      logError('Google Sign-In not available');
      return null;
    }

    try {
      logInfo('Starting Google Sign-In');

      // Check if already signed in
      GoogleSignInAccount? account = _googleSignIn!.currentUser;

      account ??= await _googleSignIn!.signIn();

      if (account == null) {
        logInfo('Google Sign-In cancelled by user');
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await account.authentication;

      if (googleAuth.accessToken == null) {
        logError('Failed to get Google access token');
        return null;
      }

      logInfo('Google Sign-In successful for: ${account.email}');

      return SocialLoginData(
        provider: SocialProvider.google,
        token: googleAuth.accessToken!,
        email: account.email,
        name: account.displayName,
        avatarUrl: account.photoUrl,
      );
    } catch (e, stackTrace) {
      logError('Google Sign-In error', e, stackTrace);
      return null;
    }
  }

  /// Sign in with Apple (iOS only)
  Future<SocialLoginData?> signInWithApple() async {
    try {
      // Check if Apple Sign-In is available
      if (!Platform.isIOS) {
        logError('Apple Sign-In is only available on iOS');
        return null;
      }

      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        logError('Apple Sign-In is not available on this device');
        return null;
      }

      logInfo('Starting Apple Sign-In');

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        logError('Failed to get Apple identity token');
        return null;
      }

      // Construct full name from Apple credential
      String? fullName;
      if (credential.givenName != null || credential.familyName != null) {
        fullName =
            '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                .trim();
        if (fullName.isEmpty) fullName = null;
      }

      logInfo('Apple Sign-In successful');

      return SocialLoginData(
        provider: SocialProvider.apple,
        token: credential.identityToken!,
        email: credential.email,
        name: fullName,
        avatarUrl: null, // Apple doesn't provide avatar URLs
      );
    } catch (e, stackTrace) {
      logError('Apple Sign-In error', e, stackTrace);
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    if (_googleSignIn == null) return;

    try {
      await _googleSignIn!.signOut();
      logInfo('Google Sign-Out successful');
    } catch (e, stackTrace) {
      logError('Google Sign-Out error', e, stackTrace);
    }
  }

  /// Sign out from Apple (Apple doesn't provide a sign-out method)
  Future<void> signOutApple() async {
    // Apple doesn't provide a programmatic sign-out method
    // The user needs to revoke access manually in Settings
    logInfo('Apple Sign-Out: User must revoke access manually in Settings');
  }

  /// Sign out from all social providers
  Future<void> signOutAll() async {
    await Future.wait([
      signOutGoogle(),
      signOutApple(),
    ]);
  }

  /// Check if user is signed in with Google
  Future<bool> isSignedInWithGoogle() async {
    if (_googleSignIn == null) return false;

    try {
      final account = await _googleSignIn!.signInSilently();
      return account != null;
    } catch (e) {
      return false;
    }
  }

  /// Get current Google user
  GoogleSignInAccount? getCurrentGoogleUser() {
    return _googleSignIn?.currentUser;
  }

  /// Disconnect Google account (revokes access)
  Future<void> disconnectGoogle() async {
    if (_googleSignIn == null) return;

    try {
      await _googleSignIn!.disconnect();
      logInfo('Google account disconnected');
    } catch (e, stackTrace) {
      logError('Google disconnect error', e, stackTrace);
    }
  }
}
