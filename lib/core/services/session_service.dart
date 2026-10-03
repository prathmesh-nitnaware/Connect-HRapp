import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionUser {
  final String id;
  final String name;
  final String email;
  final String role;

  SessionUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}

class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  static const String _keyToken = 'auth_token';
  static const String _keyRole = 'user_role';
  static const String _keyEmail = 'user_email';
  static const String _keyName = 'user_name';
  static const String _keyUserId = 'user_id';
  static const String _keyBaseUrl = 'custom_base_url';

  String? _token;
  String? _role;
  String? _email;
  String? _name;
  String? _userId;
  String? _customBaseUrl;

  String? get token => _token;
  String? get role => _role;
  String? get email => _email;
  String? get name => _name;
  String? get userId => _userId;
  String? get customBaseUrl => _customBaseUrl;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isHR => _role?.toUpperCase() == 'HR';

  SessionUser? get currentUser {
    if (!isAuthenticated) return null;
    return SessionUser(
      id: _userId ?? _email ?? 'EMP001',
      name: _name ?? 'Employee',
      email: _email ?? '',
      role: _role ?? 'EMPLOYEE',
    );
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    _role = prefs.getString(_keyRole);
    _email = prefs.getString(_keyEmail);
    _name = prefs.getString(_keyName);
    _userId = prefs.getString(_keyUserId);
    _customBaseUrl = prefs.getString(_keyBaseUrl);
    notifyListeners();
  }

  Future<void> saveSession({
    required String token,
    required String role,
    String? email,
    String? name,
    String? userId,
  }) async {
    _token = token;
    _role = role;
    if (email != null) _email = email;
    if (name != null) _name = name;
    if (userId != null) _userId = userId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRole, role);
    if (email != null) await prefs.setString(_keyEmail, email);
    if (name != null) await prefs.setString(_keyName, name);
    if (userId != null) await prefs.setString(_keyUserId, userId);

    notifyListeners();
  }

  Future<void> setCustomBaseUrl(String? url) async {
    _customBaseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null && url.isNotEmpty) {
      await prefs.setString(_keyBaseUrl, url);
    } else {
      await prefs.remove(_keyBaseUrl);
    }
    notifyListeners();
  }

  Future<void> clearSession() async {
    _token = null;
    _role = null;
    _email = null;
    _name = null;
    _userId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
    await prefs.remove(_keyUserId);

    notifyListeners();
  }
}
