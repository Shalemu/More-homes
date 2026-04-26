import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:morehomesapp/models/user_model.dart';
import 'package:morehomesapp/services/auth_services.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _accessToken;
  int? _tokenExpiry;

  bool _isLoading = false;

  // GETTERS 
  UserModel? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;

  bool get isAuthenticated =>
      _accessToken != null &&
      _accessToken!.isNotEmpty &&
      _isTokenValid();

  // TOKEN VALIDATION
  bool _isTokenValid() {
    if (_tokenExpiry == null) return false;
    return DateTime.now().millisecondsSinceEpoch < _tokenExpiry!;
  }

  // LOGIN 
  Future<void> login(
    UserModel user,
    String access,
    String refresh, {
    int? expiresInSeconds,
  }) async {
    _setLoading(true);

    _user = user;
    _accessToken = access;

    // default expiry = 24h if backend doesn't provide it
    _tokenExpiry = DateTime.now()
        .add(Duration(seconds: expiresInSeconds ?? 86400))
        .millisecondsSinceEpoch;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user', json.encode(user.toJson()));
    await prefs.setString('access', access);
    await prefs.setString('refresh', refresh);
    await prefs.setInt('expiry', _tokenExpiry!);

    _setLoading(false);
  }

  // LOAD SESSION 
  Future<void> loadUserFromPrefs() async {
    _setLoading(true);

    final prefs = await SharedPreferences.getInstance();

    final userData = prefs.getString('user');
    final access = prefs.getString('access');
    final refresh = prefs.getString('refresh');
    final expiry = prefs.getInt('expiry');

    if (userData != null && access != null && refresh != null) {
      _user = UserModel.fromJson(json.decode(userData));
      _accessToken = access;
      _tokenExpiry = expiry;
    }

    _setLoading(false);
  }

  //CHECK SESSION 
Future<bool> checkAuthStatus() async {
  if (!_isTokenValid()) {
    await logout();
    return false;
  }

  return true;
}

  // UPDATE USER 
  Future<void> updateUser(UserModel updatedUser) async {
    _setLoading(true);

    _user = updatedUser;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(updatedUser.toJson()));

    _setLoading(false);
  }

  //CHANGE PASSWORD 
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_accessToken == null || !_isTokenValid()) {
      return {
        'success': false,
        'message': 'Session expired. Please login again.',
      };
    }

    final authService = AuthService();

    final response = await authService.changePassword(
      token: _accessToken!,
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': response.detail,
      };
    } else {
      return {
        'success': false,
        'message': response.detail,
      };
    }
  }

  // LOGOUT
  Future<void> logout() async {
    _setLoading(true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('access');
    await prefs.remove('refresh');
    await prefs.remove('expiry');

    _user = null;
    _accessToken = null;
    _tokenExpiry = null;

    _setLoading(false);
  }

  // INTERNAL
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}