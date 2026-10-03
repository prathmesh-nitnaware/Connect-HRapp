import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../config/server_config.dart';
import '../db/database_service.dart';
import '../utils/password_hasher.dart';

class AuthController {
  final DatabaseService _db = DatabaseService();

  Router get router {
    final router = Router();
    router.post('/signup', _handleSignup);
    router.post('/login', _handleLogin);
    return router;
  }

  Future<Response> _handleSignup(Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final email = data['email']?.toString().trim();
      final password = data['password']?.toString();
      final name = data['name']?.toString().trim();
      final role = data['role']?.toString().trim() ?? 'employee';
      final department = data['department']?.toString().trim() ?? 'Unassigned';

      if (email == null || email.isEmpty || password == null || password.isEmpty || name == null || name.isEmpty) {
        return Response(400, body: jsonEncode({'message': 'Please provide all required fields'}), headers: {'content-type': 'application/json'});
      }

      final isHR = role.toUpperCase() == 'HR';
      final targetCollection = isHR ? 'hr_users' : 'employees';

      // Check if user already exists
      final existingUser = await _db.findOne(targetCollection, {'email': email});
      if (existingUser != null) {
        return Response(400, body: jsonEncode({'message': 'User already exists'}), headers: {'content-type': 'application/json'});
      }

      final hashedPassword = PasswordHasher.hashPassword(password);
      await _db.insertOne(targetCollection, {
        'name': name,
        'email': email,
        'password': hashedPassword,
        'role': isHR ? 'HR' : 'employee',
        'department': department,
      });

      return Response(201, body: jsonEncode({'message': 'User created successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleLogin(Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final email = data['email']?.toString().trim().toLowerCase();
      final password = data['password']?.toString();

      if (email == null || email.isEmpty || password == null || password.isEmpty) {
        return Response(400, body: jsonEncode({'message': 'Please provide email and password'}), headers: {'content-type': 'application/json'});
      }

      // Check in hr_users and employees
      var user = await _db.findOne('hr_users', {'email': email});
      user ??= await _db.findOne('employees', {'email': email});
      user ??= await _db.findOne('users', {'email': email});

      if (user == null) {
        return Response(401, body: jsonEncode({'message': 'Invalid credentials'}), headers: {'content-type': 'application/json'});
      }

      final storedPasswordHash = user['password']?.toString() ?? '';
      final isPasswordValid = PasswordHasher.verifyPassword(password, storedPasswordHash);

      if (!isPasswordValid) {
        return Response(401, body: jsonEncode({'message': 'Invalid credentials'}), headers: {'content-type': 'application/json'});
      }

      // Generate JWT Token (24h validity)
      final userIdClean = DatabaseService.cleanId(user['_id']);
      final jwt = JWT({
        'user_id': userIdClean,
        'role': user['role'] ?? 'employee',
        'exp': (DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch / 1000).round(),
      });

      final token = jwt.sign(SecretKey(ServerConfig().secretKey));

      return Response(200, body: jsonEncode({
        'token': token,
        'role': user['role'] ?? 'employee',
      }), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }
}
