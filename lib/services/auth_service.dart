import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get the current user's ID token
  Future<String?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  /// Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Create or update user in Firestore
        final userModel = await _createOrUpdateUser(user);
        return userModel;
      }

      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Create or update user in Firestore (upsert pattern like Omi)
  Future<UserModel> _createOrUpdateUser(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      // Check if user already exists
      final doc = await userDoc.get();
      
      if (doc.exists) {
        // Update existing user
        await userDoc.update({
          'email': userModel.email,
          'displayName': userModel.displayName,
          'photoUrl': userModel.photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Return existing user data with updated fields
        final existingData = doc.data()!;
        return UserModel(
          uid: userModel.uid,
          email: userModel.email,
          displayName: userModel.displayName,
          photoUrl: userModel.photoUrl,
          createdAt: (existingData['createdAt'] as Timestamp).toDate(),
          updatedAt: DateTime.now(),
        );
      } else {
        // Create new user
        await userDoc.set({
          'uid': userModel.uid,
          'email': userModel.email,
          'displayName': userModel.displayName,
          'photoUrl': userModel.photoUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        return userModel;
      }
    } catch (e) {
      print('Error creating/updating user: $e');
      // Retry logic similar to Omi
      await Future.delayed(const Duration(seconds: 1));
      try {
        await userDoc.set({
          'uid': userModel.uid,
          'email': userModel.email,
          'displayName': userModel.displayName,
          'photoUrl': userModel.photoUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return userModel;
      } catch (retryError) {
        print('Retry failed for user creation: $retryError');
        return userModel; // Return user model even if Firestore fails
      }
    }
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return UserModel(
          uid: data['uid'],
          email: data['email'] ?? '',
          displayName: data['displayName'] ?? '',
          photoUrl: data['photoUrl'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}