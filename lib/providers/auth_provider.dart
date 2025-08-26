import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // User signed in, get user data from Firestore
        final userData = await _authService.getUserData(firebaseUser.uid);
        _user = userData ?? UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '',
          photoUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        // User signed out
        _user = null;
      }
      notifyListeners();
    });
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final userModel = await _authService.signInWithGoogle();
      
      if (userModel != null) {
        _user = userModel;
        _setLoading(false);
        return true;
      } else {
        _setError('Sign in was cancelled or failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to sign in: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _setError('Failed to sign out: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message
  void clearError() {
    _clearError();
    notifyListeners();
  }
}