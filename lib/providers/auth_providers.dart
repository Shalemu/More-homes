import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _accessToken;
  String? _refreshToken;

  Map<String, dynamic>? get user => _user;
  String? get accessToken => _accessToken;

  bool get isAuthenticated => _accessToken != null;

  void login(Map<String, dynamic> user, String access, String refresh) {
    _user = user;
    _accessToken = access;
    _refreshToken = refresh;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
  }
}
