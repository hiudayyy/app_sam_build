import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _checkStoredUser();
  }

  Future<void> _checkStoredUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final storedUser = await AuthService.getStoredUser();
      _user = storedUser;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(LoginCredentials credentials) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await AuthService.login(credentials);
      _user = user;
    } catch (e) {
      _error = e.toString();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await AuthService.logout();
      _user = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool hasPermission(Permission permission) {
    return AuthService.hasPermission(_user, permission);
  }

  bool hasRole(UserRole role) {
    return AuthService.hasRole(_user, role);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}