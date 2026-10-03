import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database_service.dart';
import '../middleware/auth_middleware.dart';

class EmployeeController {
  final DatabaseService _db = DatabaseService();

  // Default company office coordinates (Configurable)
  static const double officeLatitude = 18.5204;
  static const double officeLongitude = 73.8567;
  static const double allowedRadiusMeters = 500.0;

  Router get router {
    final router = Router();
    router.get('/profile', _handleGetProfile);
    router.post('/smart-punch', handleSmartPunch);
    router.get('/attendance/stats', handleGetAttendanceStats);
    router.get('/work-hours-stats', handleGetAttendanceStats);
    router.get('/attendance/qr-token', handleGetOfficeQrToken);
    router.get('/qr-code', handleGetOfficeQrToken);
    return router;
  }


  // Profile endpoint
  Future<Response> _handleGetProfile(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    final user = auth.user;
    return Response(200, body: jsonEncode({
      'name': user['name'] ?? '',
      'email': user['email'] ?? '',
      'role': user['role'] ?? 'employee',
      'department': user['department'] ?? 'N/A',
    }), headers: {'content-type': 'application/json'});
  }

  // Generate dynamic QR token for reception display
  Future<Response> handleGetOfficeQrToken(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final qrToken = 'CONNECT_HR_OFFICE_CHECKIN_${today}_SECURE';
    return Response(200, body: jsonEncode({
      'qr_token': qrToken,
      'office_name': 'Connect HR HQ',
      'valid_date': today,
      'office_latitude': officeLatitude,
      'office_longitude': officeLongitude,
      'radius_meters': allowedRadiusMeters,
    }), headers: {'content-type': 'application/json'});
  }

  // Smart Punch In / Out (Geofenced GPS or QR code scanner)
  Future<Response> handleSmartPunch(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final action = data['action']?.toString(); // punch_in or punch_out
      final method = data['method']?.toString() ?? 'standard'; // standard, geofence, qr
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      final qrCode = data['qr_code']?.toString();
      final userId = auth.user['_id'].toString();

      // Geofence verification
      if (method == 'geofence') {
        if (lat == null || lng == null) {
          return Response(400, body: jsonEncode({'message': 'GPS location required for geofenced check-in'}), headers: {'content-type': 'application/json'});
        }
        final distance = _calculateDistanceInMeters(lat, lng, officeLatitude, officeLongitude);
        if (distance > allowedRadiusMeters) {
          return Response(400, body: jsonEncode({
            'message': 'You are ${distance.round()}m away from office. Allowed radius: ${allowedRadiusMeters.round()}m.'
          }), headers: {'content-type': 'application/json'});
        }
      }

      // QR Code verification
      if (method == 'qr') {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final expectedQr = 'CONNECT_HR_OFFICE_CHECKIN_${today}_SECURE';
        if (qrCode != expectedQr && qrCode != 'CONNECT_HR_OFFICE_CHECKIN') {
          return Response(400, body: jsonEncode({'message': 'Invalid or expired Office QR code'}), headers: {'content-type': 'application/json'});
        }
      }

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final nowTimeStr = DateFormat('HH:mm:ss').format(DateTime.now());

      final record = await _db.findOne('attendance', {
        'employee_id': userId,
        'date': todayStr,
      });

      if (action == 'punch_in') {
        if (record != null && (record['punch_in']?.toString().isNotEmpty == true)) {
          return Response(400, body: jsonEncode({'message': 'Already punched in today'}), headers: {'content-type': 'application/json'});
        }

        if (record != null) {
          await _db.updateOne('attendance', {'_id': record['_id']}, {
            'punch_in': nowTimeStr,
            'method': method,
            'latitude': lat,
            'longitude': lng,
          });
        } else {
          await _db.insertOne('attendance', {
            'employee_id': userId,
            'employee_name': auth.user['name'] ?? 'Unknown',
            'date': todayStr,
            'punch_in': nowTimeStr,
            'punch_out': '',
            'method': method,
            'latitude': lat,
            'longitude': lng,
          });
        }

        return Response(200, body: jsonEncode({
          'message': 'Punched in successfully via ${method.toUpperCase()}',
          'time': nowTimeStr,
        }), headers: {'content-type': 'application/json'});
      } else if (action == 'punch_out') {
        if (record == null || (record['punch_in']?.toString().isEmpty ?? true)) {
          return Response(400, body: jsonEncode({'message': 'Must punch in first'}), headers: {'content-type': 'application/json'});
        }
        if (record['punch_out']?.toString().isNotEmpty == true) {
          return Response(400, body: jsonEncode({'message': 'Already punched out today'}), headers: {'content-type': 'application/json'});
        }

        // Calculate hours worked
        final punchInTime = record['punch_in']?.toString() ?? '';
        final hoursWorked = _calculateHours(punchInTime, nowTimeStr);

        await _db.updateOne('attendance', {'_id': record['_id']}, {
          'punch_out': nowTimeStr,
          'hours_worked': hoursWorked,
        });

        return Response(200, body: jsonEncode({
          'message': 'Punched out successfully. Total: ${hoursWorked.toStringAsFixed(1)} hrs',
          'time': nowTimeStr,
          'hours_worked': hoursWorked,
        }), headers: {'content-type': 'application/json'});
      }

      return Response(400, body: jsonEncode({'message': 'Invalid action'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // Work Hours & Overtime Calculator
  Future<Response> handleGetAttendanceStats(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final userId = auth.user['_id'].toString();
      final records = await _db.find('attendance', query: {'employee_id': userId});

      double totalHours = 0.0;
      double overtimeHours = 0.0;
      int daysPresent = 0;

      for (final r in records) {
        if (r['punch_in']?.toString().isNotEmpty == true) {
          daysPresent++;
          final inTime = r['punch_in']?.toString() ?? '';
          final outTime = r['punch_out']?.toString() ?? '';
          if (outTime.isNotEmpty) {
            final hrs = _calculateHours(inTime, outTime);
            totalHours += hrs;
            if (hrs > 8.0) {
              overtimeHours += (hrs - 8.0);
            }
          }
        }
      }

      return Response(200, body: jsonEncode({
        'days_present': daysPresent,
        'total_hours': double.parse(totalHours.toStringAsFixed(1)),
        'overtime_hours': double.parse(overtimeHours.toStringAsFixed(1)),
        'avg_hours_per_day': daysPresent > 0 ? double.parse((totalHours / daysPresent).toStringAsFixed(1)) : 0.0,
      }), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // Attendance endpoints
  Future<Response> handlePostAttendance(Request request) async {
    return handleSmartPunch(request);
  }

  Future<Response> handleGetAttendance(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final userId = auth.user['_id'].toString();
      final records = await _db.find(
        'attendance',
        query: {'employee_id': userId},
        limit: 30,
        sortField: 'date',
        sortDescending: true,
      );

      final history = records.map((r) => {
        'date': r['date']?.toString() ?? '',
        'punch_in': r['punch_in']?.toString() ?? '',
        'punch_out': r['punch_out']?.toString() ?? '',
        'method': r['method']?.toString() ?? 'Standard',
      }).toList();

      return Response(200, body: jsonEncode(history), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // Leave endpoints
  Future<Response> handlePostLeave(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final leaveType = data['leave_type']?.toString();
      final reason = data['reason']?.toString();
      final dateStr = data['date']?.toString() ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (leaveType == null || reason == null) {
        return Response(400, body: jsonEncode({'message': 'Please provide leave type and reason'}), headers: {'content-type': 'application/json'});
      }

      await _db.insertOne('leaves', {
        'employee_id': auth.user['_id'].toString(),
        'employee_name': auth.user['name'] ?? 'Unknown',
        'leave_type': leaveType,
        'reason': reason,
        'date': dateStr,
        'status': 'Pending',
      });

      // Notify HR
      final hrUsers = await _db.find('hr_users');
      for (final hr in hrUsers) {
        final hrId = hr['_id']?.toString();
        if (hrId != null) {
          await _db.insertOne('notifications', {
            'user_id': hrId,
            'title': 'New Leave Request 🗓️',
            'message': '${auth.user['name']} applied for $leaveType on $dateStr.',
            'type': 'leave',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      return Response(201, body: jsonEncode({'message': 'Leave applied successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> handleGetLeave(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final userId = auth.user['_id'].toString();
      final records = await _db.find(
        'leaves',
        query: {'employee_id': userId},
        sortField: 'date',
        sortDescending: true,
      );

      final history = records.map((r) => {
        'id': r['_id']?.toString() ?? '',
        'leave_type': r['leave_type']?.toString() ?? '',
        'reason': r['reason']?.toString() ?? '',
        'date': r['date']?.toString() ?? '',
        'status': r['status']?.toString() ?? 'Pending',
      }).toList();

      return Response(200, body: jsonEncode(history), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // --- Helper math ---
  double _calculateDistanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a)); // 2 * R * 1000 in meters
  }

  double _calculateHours(String inTime, String outTime) {
    try {
      final inParts = inTime.split(':').map(int.parse).toList();
      final outParts = outTime.split(':').map(int.parse).toList();
      final inMinutes = inParts[0] * 60 + inParts[1];
      final outMinutes = outParts[0] * 60 + outParts[1];
      final diff = outMinutes - inMinutes;
      return diff > 0 ? diff / 60.0 : 0.0;
    } catch (_) {
      return 0.0;
    }
  }
}
