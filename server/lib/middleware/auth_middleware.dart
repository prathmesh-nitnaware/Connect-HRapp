import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import '../config/server_config.dart';
import '../db/database_service.dart';

class AuthResult {
  final Map<String, dynamic> user;
  final bool isHR;

  AuthResult({required this.user, required this.isHR});
}

class AuthMiddleware {
  AuthMiddleware._();

  static Future<AuthResult?> authenticate(Request request) async {
    final authHeader = request.headers['authorization'] ?? request.headers['Authorization'];
    if (authHeader == null || authHeader.isEmpty) {
      return null;
    }

    final token = authHeader.startsWith('Bearer ')
        ? authHeader.substring(7).trim()
        : authHeader.trim();

    if (token.isEmpty) return null;

    try {
      final jwt = JWT.verify(token, SecretKey(ServerConfig().secretKey));
      final payload = jwt.payload as Map<String, dynamic>;
      final userId = payload['user_id']?.toString();

      if (userId == null) return null;

      final db = DatabaseService();
      // Check in employees first
      var user = await db.findById('employees', userId);
      user ??= await db.findById('hr_users', userId);

      if (user == null) return null;

      final isHR = user['role']?.toString().toUpperCase() == 'HR';
      return AuthResult(user: user, isHR: isHR);
    } catch (_) {
      return null;
    }
  }

  static Response unauthorized([String message = 'Token is invalid or missing']) {
    return Response(
      401,
      body: jsonEncode({'message': message}),
      headers: {'content-type': 'application/json'},
    );
  }

  static Response forbidden([String message = 'Invalid user token or HR access required']) {
    return Response(
      403,
      body: jsonEncode({'message': message}),
      headers: {'content-type': 'application/json'},
    );
  }
}
