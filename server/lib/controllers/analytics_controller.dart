import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database_service.dart';
import '../middleware/auth_middleware.dart';

class AnalyticsController {
  final DatabaseService _db = DatabaseService();

  Router get router {
    final router = Router();
    router.get('/advanced', _handleGetAdvancedAnalytics);
    router.get('/advanced-analytics', _handleGetAdvancedAnalytics);
    router.get('/export-attendance', _handleExportAttendanceCsv);
    router.get('/reports/attendance-csv', _handleExportAttendanceCsv);
    router.get('/export-leaves', _handleExportLeavesCsv);
    router.get('/reports/leaves-csv', _handleExportLeavesCsv);
    return router;
  }

  Future<Response> _handleGetAdvancedAnalytics(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();


    try {
      final employees = await _db.find('employees');
      final attendance = await _db.find('attendance');
      final leaves = await _db.find('leaves');
      final payslips = await _db.find('payslips');

      // Department breakdown
      final deptCounts = <String, int>{};
      for (final emp in employees) {
        final dept = emp['department']?.toString() ?? 'Unassigned';
        deptCounts[dept] = (deptCounts[dept] ?? 0) + 1;
      }

      // Leave type distribution
      final leaveTypeCounts = <String, int>{};
      for (final l in leaves) {
        final type = l['leave_type']?.toString() ?? 'Other';
        leaveTypeCounts[type] = (leaveTypeCounts[type] ?? 0) + 1;
      }

      // Recent 7 days attendance trend (percentage based on total employees)
      final totalEmp = employees.isNotEmpty ? employees.length : 1;
      final recentDays = <Map<String, dynamic>>[];
      final now = DateTime.now();

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i)).toIso8601String().split('T').first;
        final count = attendance.where((a) => a['date'] == date && (a['punch_in']?.toString().isNotEmpty ?? false)).length;
        final percentage = ((count / totalEmp) * 100).clamp(0, 100).round();
        recentDays.add({
          'date': date,
          'day': _getDayName(now.subtract(Duration(days: i)).weekday),
          'count': count,
          'percentage': percentage,
        });
      }

      // Total payroll expenditure
      double totalPayroll = 0.0;
      for (final p in payslips) {
        totalPayroll += (p['net_salary'] as num?)?.toDouble() ?? 0.0;
      }

      return Response(200, body: jsonEncode({
        'total_employees': employees.length,
        'department_distribution': deptCounts,
        'leave_distribution': leaveTypeCounts,
        'attendance_trend': recentDays,
        'total_payroll_expenditure': totalPayroll,
        'total_leave_requests': leaves.length,
      }), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleExportAttendanceCsv(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final records = await _db.find('attendance', sortField: 'date', sortDescending: true);
      final buffer = StringBuffer();
      buffer.writeln('ID,Employee Name,Date,Punch In,Punch Out,Method');

      for (final r in records) {
        final id = r['_id']?.toString() ?? '';
        final name = (r['employee_name']?.toString() ?? 'Unknown').replaceAll(',', ' ');
        final date = r['date']?.toString() ?? '';
        final inTime = r['punch_in']?.toString() ?? '';
        final outTime = r['punch_out']?.toString() ?? '';
        final method = r['method']?.toString() ?? 'Standard';
        buffer.writeln('$id,$name,$date,$inTime,$outTime,$method');
      }

      return Response(200, body: buffer.toString(), headers: {
        'content-type': 'text/csv; charset=utf-8',
        'content-disposition': 'attachment; filename="attendance_report.csv"',
      });
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleExportLeavesCsv(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final records = await _db.find('leaves', sortField: 'date', sortDescending: true);
      final buffer = StringBuffer();
      buffer.writeln('ID,Employee Name,Leave Type,Date,Status,Reason');

      for (final r in records) {
        final id = r['_id']?.toString() ?? '';
        final name = (r['employee_name']?.toString() ?? 'Unknown').replaceAll(',', ' ');
        final type = r['leave_type']?.toString() ?? '';
        final date = r['date']?.toString() ?? '';
        final status = r['status']?.toString() ?? '';
        final reason = (r['reason']?.toString() ?? '').replaceAll(',', ' ').replaceAll('\n', ' ');
        buffer.writeln('$id,$name,$type,$date,$status,$reason');
      }

      return Response(200, body: buffer.toString(), headers: {
        'content-type': 'text/csv; charset=utf-8',
        'content-disposition': 'attachment; filename="leaves_report.csv"',
      });
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}
