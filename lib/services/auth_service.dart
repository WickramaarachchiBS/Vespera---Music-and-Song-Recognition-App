import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //SIGN UP WITH EMAIL AND PASSWORD ----------------------------------------------------------------
  Future<UserCredential?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with display name
      await userCredential.user?.updateDisplayName(name);

      // Store user details in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'profilePicture': '', // Empty by default, can be updated later
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Always log full details for debugging device-specific issues.
      // ignore: avoid_print
      print('FirebaseAuth signUp failed: code=${e.code} message=${e.message}');

      if (e.code == 'weak-password') {
        throw 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        throw 'An account already exists for that email.';
      } else {
        throw 'Auth failed (${e.code}): ${e.message ?? 'Unknown error'}';
      }
    } catch (e) {
      // ignore: avoid_print
      print('SignUp error: $e');
      throw 'An unexpected error occurred: $e';
    }
  }

  // SIGN IN WITH EMAIL AND PASSWORD ---------------------------------------------------------------
  Future<UserCredential?> signIn({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('FirebaseAuth signIn failed: code=${e.code} message=${e.message}');

      if (e.code == 'user-not-found') {
        throw 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        throw 'Wrong password provided.';
      } else {
        throw 'Auth failed (${e.code}): ${e.message ?? 'Unknown error'}';
      }
    } catch (e) {
      // ignore: avoid_print
      print('SignIn error: $e');
      throw 'An unexpected error occurred: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // EXTRA FOR LATER USE ----------------------------------------------------------------
  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? profilePicture,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (name != null) {
        updates['name'] = name;
        await _auth.currentUser?.updateDisplayName(name);
      }

      if (profilePicture != null) {
        updates['profilePicture'] = profilePicture;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }
    } catch (e) {
      print('Error updating user profile: $e');
      throw 'Failed to update profile.';
    }
  }
}
