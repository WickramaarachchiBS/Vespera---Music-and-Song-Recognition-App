import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vespera/services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  String _username = 'User';
  String _profilePicture = '';
  String _email = '';
  bool _isLoading = false;

  String get username => _username;
  String get profilePicture => _profilePicture;
  String get email => _email;
  bool get isLoading => _isLoading;

  // Load user data once
  Future<void> loadUserData() async {
    User? user = _authService.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      Map<String, dynamic>? userData = await _authService.getUserData(user.uid);
      if (userData != null) {
        _username = userData['name'] ?? 'User';
        _profilePicture = userData['profilePicture'] ?? '';
        _email = userData['email'] ?? '';
        notifyListeners();
        print('User data loaded: $_username');
        print ('Email: $_email');
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear data on logout
  void clearUserData() {
    _username = 'User';
    _profilePicture = '';
    _email = '';
    notifyListeners();
  }
}