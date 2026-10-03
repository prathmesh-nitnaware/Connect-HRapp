import 'package:flutter/foundation.dart';
import '../core/network/api_service.dart';
import '../core/network/api_exception.dart';
import '../core/services/session_service.dart';
import '../models/auth_models.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SessionService _sessionService = SessionService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _sessionService.isAuthenticated;
  String? get currentRole => _sessionService.role;
  String? get currentEmail => _sessionService.email;
  String? get currentName => _sessionService.name;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> loginEmployee({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(LoginRequest(
        email: email.trim(),
        password: password,
      ));

      if (response.token != null) {
        if (response.role?.toUpperCase() == 'HR') {
          _errorMessage = 'Please use the HR Login portal';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await _sessionService.saveSession(
          token: response.token!,
          role: response.role ?? 'employee',
          email: email.trim(),
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginHR({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(LoginRequest(
        email: email.trim(),
        password: password,
      ));

      if (response.token != null) {
        if (response.role?.toUpperCase() != 'HR') {
          _errorMessage = 'Unauthorized. HR access required.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await _sessionService.saveSession(
          token: response.token!,
          role: response.role ?? 'HR',
          email: email.trim(),
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String role = 'employee',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.signup(SignupRequest(
        name: name.trim(),
        email: email.trim(),
        password: password,
        role: role,
      ));

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _sessionService.clearSession();
    notifyListeners();
  }
}
