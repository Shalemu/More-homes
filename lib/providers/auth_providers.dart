import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:morehomesapp/models/user_model.dart';
import 'package:morehomesapp/services/auth_services.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _accessToken;
  int? _tokenExpiry;

  bool _isLoading = false;

  
  UserModel? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;

  bool get isAuthenticated =>
      _accessToken != null &&
      _accessToken!.isNotEmpty &&
      _isTokenValid();

 
  bool _isTokenValid() {
    if (_tokenExpiry == null) return false;
    return DateTime.now().millisecondsSinceEpoch < _tokenExpiry!;
  }

  
  Future<void> login(
    UserModel user,
    String access,
    String refresh, {
    int? expiresInSeconds,
  }) async {
    _setLoading(true);

    _user = user;
    _accessToken = access;

  
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

 
  Future<void> loadUserFromPrefs() async {
    _setLoading(true);

    final prefs = await SharedPreferences.getInstance();

    final userData = prefs.getString('user');
    final access = prefs.getString('access');
    prefs.getString('refresh');
    final expiry = prefs.getInt('expiry');

    if (userData != null && access != null && expiry != null) {
      _user = UserModel.fromJson(json.decode(userData));
      _accessToken = access;
      _tokenExpiry = expiry;
    }

    _setLoading(false);
  }


 Future<bool> checkAuthStatus() async {
  if (!_isTokenValid()) {
    await logout();
    return false;
  }

  return true;
}

  void validateSessionOrLogout() {
    if (!_isTokenValid()) {
      logout();
    }
  }


  /// Sends the updated profile (and optional base64 profile picture) to the
  /// backend, then persists the returned user locally on success.
  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    String? location,
    File? profileImage,
  }) async {
    if (_accessToken == null || !_isTokenValid()) {
      await logout();
      return {
        'success': false,
        'message': 'Session expired. Please login again.',
      };
    }

    _setLoading(true);

    final authService = AuthService();
    final response = await authService.updateProfile(
      token: _accessToken!,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      location: location ?? _user?.location,
      profileImage: profileImage,
    );

    if (response.statusCode == 200 && response.data != null) {
      _user = response.data;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_user!.toJson()));
    }

    _setLoading(false);

    return {
      'success': response.statusCode == 200,
      'message': response.detail,
    };
  }

 
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_accessToken == null || !_isTokenValid()) {
      await logout();
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

    return {
      'success': response.statusCode == 200,
      'message': response.detail,
    };
  }

 
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear(); 

    _user = null;
    _accessToken = null;
    _tokenExpiry = null;

    notifyListeners();
  }


  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}