import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database_service.dart';
import '../middleware/auth_middleware.dart';

class ExpenseController {
  final DatabaseService _db = DatabaseService();

  Router get router {
    final router = Router();
    router.get('/my', _handleGetMyExpenses);
    router.post('/', _handleCreateExpense);
    router.get('/all', _handleGetAllExpenses);
    router.put('/<id>/status', _handleUpdateExpenseStatus);
    return router;
  }



  Future<Response> _handleGetMyExpenses(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final userId = auth.user['_id'].toString();
      final expenses = await _db.find('expenses', query: {'employee_id': userId}, sortField: 'date', sortDescending: true);
      return Response(200, body: jsonEncode(expenses), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleCreateExpense(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final title = data['title']?.toString().trim();
      final amount = (data['amount'] as num?)?.toDouble();
      final category = data['category']?.toString() ?? 'General';
      final date = data['date']?.toString() ?? DateTime.now().toIso8601String().split('T').first;
      final notes = data['notes']?.toString() ?? '';
      final receiptBase64 = data['receipt_base64']?.toString();

      if (title == null || title.isEmpty || amount == null || amount <= 0) {
        return Response(400, body: jsonEncode({'message': 'Please provide a valid title and amount'}), headers: {'content-type': 'application/json'});
      }

      final id = await _db.insertOne('expenses', {
        'employee_id': auth.user['_id'].toString(),
        'employee_name': auth.user['name'] ?? 'Employee',
        'title': title,
        'amount': amount,
        'category': category,
        'date': date,
        'notes': notes,
        'receipt_base64': receiptBase64,
        'status': 'Pending', // Pending, Approved, Rejected, Paid
        'submitted_at': DateTime.now().toIso8601String(),
        'reviewer_notes': '',
      });

      // Notify HR
      final hrUsers = await _db.find('hr_users');
      for (final hr in hrUsers) {
        final hrId = hr['_id']?.toString();
        if (hrId != null) {
          await _db.insertOne('notifications', {
            'user_id': hrId,
            'title': 'New Expense Claim Submitted 📊',
            'message': '${auth.user['name']} submitted a \$${amount.toStringAsFixed(2)} claim for $title.',
            'type': 'expense',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      return Response(201, body: jsonEncode({'id': id, 'message': 'Expense claim submitted successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleGetAllExpenses(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final expenses = await _db.find('expenses', sortField: 'submitted_at', sortDescending: true);
      return Response(200, body: jsonEncode(expenses), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleUpdateExpenseStatus(Request request, String id) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final status = data['status']?.toString();
      final reviewerNotes = data['reviewer_notes']?.toString() ?? '';

      if (status == null || !['Approved', 'Rejected', 'Paid', 'Pending'].contains(status)) {
        return Response(400, body: jsonEncode({'message': 'Invalid status'}), headers: {'content-type': 'application/json'});
      }

      final expense = await _db.findById('expenses', id);
      if (expense == null) {
        return Response(404, body: jsonEncode({'message': 'Expense claim not found'}), headers: {'content-type': 'application/json'});
      }

      await _db.updateOne('expenses', {'_id': id}, {
        'status': status,
        'reviewer_notes': reviewerNotes,
        'reviewed_by': auth.user['name'] ?? 'HR Admin',
        'reviewed_at': DateTime.now().toIso8601String(),
      });

      // Notify the employee
      final employeeId = expense['employee_id']?.toString();
      if (employeeId != null) {
        await _db.insertOne('notifications', {
          'user_id': employeeId,
          'title': 'Expense Claim $status 🧾',
          'message': 'Your claim for "${expense['title']}" was marked as $status.',
          'type': 'expense',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return Response(200, body: jsonEncode({'message': 'Expense claim updated to $status'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }
}
