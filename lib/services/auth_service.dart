import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //SIGN UP WITH EMAIL AND PASSWORD ----------------------------------------------------------------
  Future<UserCredential?> signUp({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        throw 'An account already exists for that email.';
      } else {
        throw 'An error occurred: ${e.message}';
      }
    } catch (e) {
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
      if (e.code == 'user-not-found') {
        throw 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        throw 'Wrong password provided.';
      } else {
        throw 'An error occurred: ${e.message}';
      }
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
