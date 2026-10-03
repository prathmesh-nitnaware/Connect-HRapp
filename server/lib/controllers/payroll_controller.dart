import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database_service.dart';
import '../middleware/auth_middleware.dart';

class PayrollController {
  final DatabaseService _db = DatabaseService();

  Router get router {
    final router = Router();
    router.get('/my-payslips', _handleGetMyPayslips);
    router.get('/all', _handleGetAllPayslips);
    router.post('/generate', _handleGeneratePayslip);
    router.get('/structure', _handleGetSalaryStructure);
    router.post('/structure', _handleSaveSalaryStructure);
    return router;
  }

  // Employee: Get personal payslips
  Future<Response> _handleGetMyPayslips(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final userId = auth.user['_id'].toString();
      final payslips = await _db.find('payslips', query: {'employee_id': userId}, sortField: 'year', sortDescending: true);
      return Response(200, body: jsonEncode(payslips), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // HR: Get all company payslips
  Future<Response> _handleGetAllPayslips(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final payslips = await _db.find('payslips', sortField: 'year', sortDescending: true);
      return Response(200, body: jsonEncode(payslips), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // HR: Generate a payslip for an employee
  Future<Response> _handleGeneratePayslip(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final employeeId = data['employee_id']?.toString();
      final month = data['month']?.toString() ?? 'Current Month';
      final year = int.tryParse(data['year']?.toString() ?? '') ?? DateTime.now().year;
      final basicSalary = (data['basic_salary'] as num?)?.toDouble() ?? 0.0;
      final hra = (data['hra'] as num?)?.toDouble() ?? 0.0;
      final allowances = (data['allowances'] as num?)?.toDouble() ?? 0.0;
      final deductions = (data['deductions'] as num?)?.toDouble() ??
          (data['provident_fund'] as num?)?.toDouble() ??
          0.0;
      final tax = (data['tax'] as num?)?.toDouble() ??
          (data['tax_deductions'] as num?)?.toDouble() ??
          0.0;

      if (employeeId == null || employeeId.isEmpty) {
        return Response(400, body: jsonEncode({'message': 'Please specify employee'}), headers: {'content-type': 'application/json'});
      }

      var employee = await _db.findById('employees', employeeId);
      employee ??= await _db.findOne('employees', {'email': employeeId});
      final employeeName = data['employee_name']?.toString().isNotEmpty == true
          ? data['employee_name'].toString()
          : (employee?['name'] ?? 'Employee');

      final grossSalary = basicSalary + hra + allowances;
      final totalDeductions = deductions + tax;
      final netSalary = grossSalary - totalDeductions;

      final id = await _db.insertOne('payslips', {
        'employee_id': employeeId,
        'employee_name': employeeName,
        'month': month,
        'year': year,
        'basic_salary': basicSalary,
        'hra': hra,
        'allowances': allowances,
        'provident_fund': deductions,
        'deductions': deductions,
        'tax_deductions': tax,
        'tax': tax,
        'gross_salary': grossSalary,
        'net_salary': netSalary,
        'net_pay': netSalary,
        'payment_status': 'Paid',
        'status': 'Paid',
        'generated_date': DateTime.now().toIso8601String().split('T').first,
        'generated_at': DateTime.now().toIso8601String(),
      });

      // Send notification to the employee
      await _db.insertOne('notifications', {
        'user_id': employeeId,
        'title': 'New Payslip Generated 💰',
        'message': 'Your salary slip for $month $year of ₹${netSalary.toStringAsFixed(0)} is ready to view and download.',
        'type': 'payroll',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      return Response(201, body: jsonEncode({
        'id': id,
        '_id': id,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'month': month,
        'year': year,
        'basic_salary': basicSalary,
        'hra': hra,
        'allowances': allowances,
        'provident_fund': deductions,
        'tax_deductions': tax,
        'gross_salary': grossSalary,
        'net_pay': netSalary,
        'status': 'Paid',
        'generated_at': DateTime.now().toIso8601String(),
        'message': 'Payslip generated successfully'
      }), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // Employee & HR: Get salary structure
  Future<Response> _handleGetSalaryStructure(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final employeeId = request.url.queryParameters['employee_id'] ?? auth.user['_id'].toString();
      final structure = await _db.findOne('salary_structures', {'employee_id': employeeId});

      if (structure != null) {
        return Response(200, body: jsonEncode(structure), headers: {'content-type': 'application/json'});
      }

      // Default high-value enterprise structure
      final basic = 50000.0;
      final hra = 20000.0;
      final special = 10000.0;
      final pf = 3500.0;
      final tds = 4500.0;
      final monthlyGross = basic + hra + special;
      final netTakeHome = monthlyGross - pf - tds;
      final annualCtc = monthlyGross * 12;

      return Response(200, body: jsonEncode({
        'employee_id': employeeId,
        'base_annual_ctc': annualCtc,
        'monthly_gross': monthlyGross,
        'breakdown': {
          'basic': basic,
          'hra': hra,
          'special_allowance': special,
          'pf': pf,
          'tds_estimated': tds,
          'net_take_home': netTakeHome,
        },
        'basic_salary': basic,
        'hra': hra,
        'allowances': special,
        'deductions': pf,
        'tax': tds,
        'net_salary': netTakeHome,
      }), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // HR: Save salary structure for employee
  Future<Response> _handleSaveSalaryStructure(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final employeeId = data['employee_id']?.toString();

      if (employeeId == null) {
        return Response(400, body: jsonEncode({'message': 'employee_id is required'}), headers: {'content-type': 'application/json'});
      }

      final existing = await _db.findOne('salary_structures', {'employee_id': employeeId});
      if (existing != null) {
        await _db.updateOne('salary_structures', {'employee_id': employeeId}, data);
      } else {
        await _db.insertOne('salary_structures', data);
      }

      return Response(200, body: jsonEncode({'message': 'Salary structure saved successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }
}
