import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database_service.dart';
import '../middleware/auth_middleware.dart';
import '../utils/password_hasher.dart';

class HRController {
  final DatabaseService _db = DatabaseService();

  Router get router {
    final router = Router();
    router.get('/analytics', _handleGetAnalytics);
    router.get('/employees', _handleGetEmployees);
    router.post('/employees', _handlePostEmployee);
    router.put('/employees/<id>', _handlePutEmployee);
    router.delete('/employees/<id>', _handleDeleteEmployee);
    router.get('/leaves', _handleGetLeaves);
    router.put('/leaves/<id>', _handlePutLeave);
    router.get('/attendance', _handleGetAttendance);
    return router;
  }

  // Analytics
  Future<Response> _handleGetAnalytics(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final totalEmployees = await _db.count('employees');
      final pendingLeaves = await _db.count('leaves', {'status': 'Pending'});
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayAttendance = await _db.count('attendance', {'date': todayStr});

      return Response(200, body: jsonEncode({
        'totalEmployees': totalEmployees,
        'pendingLeaves': pendingLeaves,
        'todayAttendance': todayAttendance,
      }), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // Employees CRUD
  Future<Response> _handleGetEmployees(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final employees = await _db.find('employees');
      final result = employees.map((emp) => {
        'id': emp['_id']?.toString() ?? '',
        'name': emp['name']?.toString() ?? '',
        'email': emp['email']?.toString() ?? '',
        'role': emp['role']?.toString() ?? 'employee',
        'department': emp['department']?.toString() ?? 'Unassigned',
      }).toList();

      return Response(200, body: jsonEncode(result), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handlePostEmployee(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

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

      final existing = await _db.findOne('employees', {'email': email});
      if (existing != null) {
        return Response(400, body: jsonEncode({'message': 'User already exists'}), headers: {'content-type': 'application/json'});
      }

      final hashedPassword = PasswordHasher.hashPassword(password);
      await _db.insertOne('employees', {
        'name': name,
        'email': email,
        'password': hashedPassword,
        'role': role,
        'department': department,
      });

      return Response(201, body: jsonEncode({'message': 'Employee hired successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handlePutEmployee(Request request, String id) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final updateFields = <String, dynamic>{};
      if (data.containsKey('department')) updateFields['department'] = data['department'];
      if (data.containsKey('role')) updateFields['role'] = data['role'];

      if (updateFields.isEmpty) {
        return Response(400, body: jsonEncode({'message': 'No fields to update'}), headers: {'content-type': 'application/json'});
      }

      final success = await _db.updateOne('employees', {'_id': id}, updateFields);
      if (success) {
        return Response(200, body: jsonEncode({'message': 'Employee updated successfully'}), headers: {'content-type': 'application/json'});
      } else {
        return Response(404, body: jsonEncode({'message': 'Employee not found'}), headers: {'content-type': 'application/json'});
      }
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleDeleteEmployee(Request request, String id) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final success = await _db.deleteOne('employees', {'_id': id});
      if (success) {
        return Response(200, body: jsonEncode({'message': 'Employee deleted successfully'}), headers: {'content-type': 'application/json'});
      } else {
        return Response(404, body: jsonEncode({'message': 'Employee not found'}), headers: {'content-type': 'application/json'});
      }
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // Leaves
  Future<Response> _handleGetLeaves(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final records = await _db.find('leaves', sortField: 'date', sortDescending: true);
      final result = <Map<String, dynamic>>[];

      for (final r in records) {
        String empName = r['employee_name']?.toString() ?? '';
        if (empName.isEmpty && r.containsKey('employee_id')) {
          final emp = await _db.findById('employees', r['employee_id'].toString());
          empName = emp?['name']?.toString() ?? 'Unknown';
        }

        result.add({
          'id': r['_id']?.toString() ?? '',
          'employee_name': empName.isNotEmpty ? empName : 'Unknown',
          'leave_type': r['leave_type']?.toString() ?? '',
          'reason': r['reason']?.toString() ?? '',
          'date': r['date']?.toString() ?? '',
          'status': r['status']?.toString() ?? 'Pending',
        });
      }

      return Response(200, body: jsonEncode(result), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handlePutLeave(Request request, String id) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final status = data['status']?.toString();

      if (status != 'Approved' && status != 'Rejected') {
        return Response(400, body: jsonEncode({'message': 'Invalid status'}), headers: {'content-type': 'application/json'});
      }

      final success = await _db.updateOne('leaves', {'_id': id}, {'status': status});
      if (success) {
        return Response(200, body: jsonEncode({'message': 'Leave ${status!.toLowerCase()} successfully'}), headers: {'content-type': 'application/json'});
      } else {
        return Response(404, body: jsonEncode({'message': 'Leave request not found'}), headers: {'content-type': 'application/json'});
      }
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // Attendance
  Future<Response> _handleGetAttendance(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final records = await _db.find('attendance', limit: 100, sortField: 'date', sortDescending: true);
      final result = <Map<String, dynamic>>[];

      for (final r in records) {
        String empName = r['employee_name']?.toString() ?? '';
        if (empName.isEmpty && r.containsKey('employee_id')) {
          final emp = await _db.findById('employees', r['employee_id'].toString());
          empName = emp?['name']?.toString() ?? 'Unknown';
        }

        result.add({
          'id': r['_id']?.toString() ?? '',
          'employee_name': empName.isNotEmpty ? empName : 'Unknown',
          'date': r['date']?.toString() ?? '',
          'punch_in': r['punch_in']?.toString() ?? '',
          'punch_out': r['punch_out']?.toString() ?? '',
        });
      }

      return Response(200, body: jsonEncode(result), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }
}
