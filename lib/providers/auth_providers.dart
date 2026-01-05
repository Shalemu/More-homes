import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _accessToken;

  // ignore: unused_field
  String? _refreshToken;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  // Login and save to shared preferences
  Future<void> login(UserModel user, String access, String refresh) async {
    _isLoading = true;
    notifyListeners();

    _user = user;
    _accessToken = access;
    _refreshToken = refresh;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toJson()));
    await prefs.setString('access', access);
    await prefs.setString('refresh', refresh);

    _isLoading = false;
    notifyListeners();
  }

  // Load user from shared preferences
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
      _refreshToken = refresh;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update user data
  Future<void> updateUser(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();

    _user = updatedUser;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(updatedUser.toJson()));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('access');
    await prefs.remove('refresh');

    _user = null;
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
  }
}
