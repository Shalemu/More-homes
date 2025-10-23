import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _accessToken;
  String? _refreshToken;

  UserModel? get user => _user;

  String? get accessToken => _accessToken;

  bool get isAuthenticated => _accessToken != null;

  /// Login with UserModel and tokens
  void login(UserModel user, String access, String refresh) {
    _user = user;
    _accessToken = access;
    _refreshToken = refresh;
    notifyListeners();
  }

  /// Logout and clear all user data
  void logout() {
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
  }

  /// Update current user data
  void updateUser(UserModel user) {
    _user = user;
    notifyListeners();
  }
}
