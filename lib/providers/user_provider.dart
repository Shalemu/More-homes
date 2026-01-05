import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  String? _accessToken;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  final UserService _userService = UserService();

  void setAccessToken(String token) {
    _accessToken = token;
  }

  Future<void> loadUser() async {
    if (_accessToken == null) return;
    _isLoading = true;
    notifyListeners();

    final response = await _userService.fetchLoggedInUser(_accessToken!);
    if (response.statusCode == 200 && response.data != null) {
      _user = response.data;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateUser(UserModel updatedUser) async {
    if (_accessToken == null) return false;
    _isLoading = true;
    notifyListeners();

    final response =
        await _userService.updateProfile(_accessToken!, updatedUser);
    if (response.statusCode == 200 && response.data != null) {
      _user = response.data;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
