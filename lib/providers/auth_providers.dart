import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:morehomesapp/services/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _accessToken;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  // -------------------------------
  // Login and save user info locally
  // -------------------------------
  Future<void> login(UserModel user, String access, String refresh) async {
    _isLoading = true;
    notifyListeners();

    _user = user;
    _accessToken = access;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toJson()));
    await prefs.setString('access', access);
    await prefs.setString('refresh', refresh);

    _isLoading = false;
    notifyListeners();
  }

  // -------------------------------
  // Load user info from SharedPreferences
  // -------------------------------
  Future<void> loadUserFromPrefs() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final access = prefs.getString('access');
    final refresh = prefs.getString('refresh');

    if (userData != null && access != null && refresh != null) {
      _user = UserModel.fromJson(json.decode(userData));
      _accessToken = access;
    }

    _isLoading = false;
    notifyListeners();
  }

  // -------------------------------
  // Update user info locally
  // -------------------------------
  Future<void> updateUser(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();

    _user = updatedUser;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(updatedUser.toJson()));

    _isLoading = false;
    notifyListeners();
  }

  // -------------------------------
  // Change Password
  // -------------------------------
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
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
      // response.detail is non-nullable, no need for ??
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

  // -------------------------------
  // Logout user
  // -------------------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('access');
    await prefs.remove('refresh');

    _user = null;
    _accessToken = null;

    notifyListeners();
  }
}