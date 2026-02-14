import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'preferences_service.dart';

/// Service for handling Google Sign-In authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final PreferencesService _prefs = PreferencesService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: AppConfig.driveScopes,
  );

  GoogleSignInAccount? _currentUser;
  auth.AuthClient? _authClient;

  /// Get the current signed-in user
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Get user's display name
  String get displayName => _currentUser?.displayName ?? 'User';

  /// Get user's email
  String get email => _currentUser?.email ?? '';

  /// Initialize and attempt silent sign-in
  Future<bool> initialize() async {
    try {
      final wasLoggedIn = await _prefs.isLoggedIn;

      // Try to sign in silently first (auto-login with existing account)
      _currentUser = await _googleSignIn.signInSilently();

      if (_currentUser != null) {
        await _createAuthClient();
        await _saveLoginState(true);
        return true;
      }

      // If silent sign-in failed but user was previously logged in,
      // try regular sign-in (this handles token expiration cases)
      if (wasLoggedIn) {
        _currentUser = await _googleSignIn.signIn();
        if (_currentUser != null) {
          await _createAuthClient();
          await _saveLoginState(true);
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
      // If there was an error but user was previously logged in, try again
      final wasLoggedIn = await _prefs.isLoggedIn;
      if (wasLoggedIn) {
        try {
          _currentUser = await _googleSignIn.signIn();
          if (_currentUser != null) {
            await _createAuthClient();
            return true;
          }
        } catch (e2) {
          debugPrint('Retry sign-in failed: $e2');
        }
      }
      return false;
    }
  }

  /// Save login state to persistent storage
  Future<void> _saveLoginState(bool isLoggedIn) async {
    await _prefs.setLoginState(
      isLoggedIn,
      email: isLoggedIn ? _currentUser?.email : null,
    );
  }

  /// Check if user was previously logged in
  Future<bool> wasUserLoggedIn() async {
    return await _prefs.isLoggedIn;
  }

  /// Check if Google Drive was previously connected
  Future<bool> isDriveConnected() async {
    return await _prefs.isDriveConnected;
  }

  /// Save Google Drive connection state
  Future<void> setDriveConnected(bool isConnected) async {
    await _prefs.setDriveConnected(isConnected);
  }

  /// Sign in with Google account
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _createAuthClient();
        await _saveLoginState(true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Sign-in failed: $e');
      return false;
    }
  }

  /// Sign out - only clears session, user must explicitly call this
  Future<void> signOut() async {
    // Clear persistent login state
    await _saveLoginState(false);
    // Clear drive connection state
    await setDriveConnected(false);
    // Disconnect completely to allow signing in with a different account
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      // If disconnect fails, fall back to signOut
      await _googleSignIn.signOut();
    }
    _currentUser = null;
    _authClient?.close();
    _authClient = null;
  }

  /// Sign in with a different Google account
  Future<bool> signInWithDifferentAccount() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Disconnect error (ignored): $e');
    }
    return await signIn();
  }

  /// Create authenticated HTTP client for API calls
  Future<void> _createAuthClient() async {
    if (_currentUser == null) return;

    final authentication = await _currentUser!.authentication;
    final accessToken = authentication.accessToken;

    if (accessToken == null) {
      throw Exception('Failed to get access token');
    }

    final credentials = auth.AccessCredentials(
      auth.AccessToken(
        'Bearer',
        accessToken,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      AppConfig.driveScopes,
    );

    _authClient = auth.authenticatedClient(
      http.Client(),
      credentials,
    );
  }

  /// Get authenticated HTTP client for Google APIs
  Future<http.Client> getAuthenticatedClient() async {
    if (_authClient == null) {
      await _createAuthClient();
    }
    return _authClient ?? http.Client();
  }

  /// Refresh authentication if needed
  Future<bool> refreshAuth() async {
    try {
      if (_currentUser != null) {
        await _currentUser!.authentication;
        await _createAuthClient();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Auth refresh failed: $e');
      return false;
    }
  }
}
