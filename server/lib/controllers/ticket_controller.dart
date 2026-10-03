import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database_service.dart';
import '../middleware/auth_middleware.dart';

class TicketController {
  final DatabaseService _db = DatabaseService();

  Router get router {
    final router = Router();
    router.get('/my', _handleGetMyTickets);
    router.post('/', _handleCreateTicket);
    router.get('/all', _handleGetAllTickets);
    router.get('/<id>', _handleGetTicketDetails);
    router.post('/<id>/messages', _handleAddMessage);
    router.put('/<id>/status', _handleUpdateTicketStatus);
    return router;
  }



  Future<Response> _handleGetMyTickets(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final userId = auth.user['_id'].toString();
      final tickets = await _db.find('tickets', query: {'employee_id': userId}, sortField: 'created_at', sortDescending: true);
      return Response(200, body: jsonEncode(tickets), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleCreateTicket(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final subject = data['subject']?.toString().trim();
      final category = data['category']?.toString() ?? 'General';
      final priority = data['priority']?.toString() ?? 'Medium';
      final description = data['description']?.toString().trim() ?? '';

      if (subject == null || subject.isEmpty) {
        return Response(400, body: jsonEncode({'message': 'Subject is required'}), headers: {'content-type': 'application/json'});
      }

      final initialMessage = {
        'sender_id': auth.user['_id'].toString(),
        'sender_name': auth.user['name'] ?? 'User',
        'is_hr': auth.isHR,
        'message': description,
        'sent_at': DateTime.now().toIso8601String(),
      };

      final id = await _db.insertOne('tickets', {
        'employee_id': auth.user['_id'].toString(),
        'employee_name': auth.user['name'] ?? 'Employee',
        'subject': subject,
        'category': category,
        'priority': priority,
        'status': 'Open', // Open, In Progress, Resolved, Closed
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'messages': [initialMessage],
      });

      return Response(201, body: jsonEncode({'id': id, 'message': 'Ticket created successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleGetAllTickets(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final tickets = await _db.find('tickets', sortField: 'created_at', sortDescending: true);
      return Response(200, body: jsonEncode(tickets), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleGetTicketDetails(Request request, String id) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final ticket = await _db.findById('tickets', id);
      if (ticket == null) {
        return Response(404, body: jsonEncode({'message': 'Ticket not found'}), headers: {'content-type': 'application/json'});
      }

      // Check access permission (creator or HR)
      final userId = auth.user['_id'].toString();
      if (!auth.isHR && ticket['employee_id'] != userId) {
        return AuthMiddleware.forbidden();
      }

      return Response(200, body: jsonEncode(ticket), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleAddMessage(Request request, String id) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final text = data['message']?.toString().trim();

      if (text == null || text.isEmpty) {
        return Response(400, body: jsonEncode({'message': 'Message text cannot be empty'}), headers: {'content-type': 'application/json'});
      }

      final ticket = await _db.findById('tickets', id);
      if (ticket == null) {
        return Response(404, body: jsonEncode({'message': 'Ticket not found'}), headers: {'content-type': 'application/json'});
      }

      final messages = List<Map<String, dynamic>>.from(ticket['messages'] ?? []);
      final newMessage = {
        'sender_id': auth.user['_id'].toString(),
        'sender_name': auth.user['name'] ?? 'User',
        'is_hr': auth.isHR,
        'message': text,
        'sent_at': DateTime.now().toIso8601String(),
      };
      messages.add(newMessage);

      await _db.updateOne('tickets', {'_id': id}, {
        'messages': messages,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Notify other party
      final recipientId = auth.isHR ? ticket['employee_id']?.toString() : null;
      if (recipientId != null) {
        await _db.insertOne('notifications', {
          'user_id': recipientId,
          'title': 'New Response on Ticket: ${ticket['subject']} 💬',
          'message': '${auth.user['name']}: $text',
          'type': 'ticket',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return Response(200, body: jsonEncode({'message': 'Message sent successfully', 'entry': newMessage}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleUpdateTicketStatus(Request request, String id) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final status = data['status']?.toString();

      if (status == null || !['Open', 'In Progress', 'Resolved', 'Closed'].contains(status)) {
        return Response(400, body: jsonEncode({'message': 'Invalid status'}), headers: {'content-type': 'application/json'});
      }

      await _db.updateOne('tickets', {'_id': id}, {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return Response(200, body: jsonEncode({'message': 'Status updated to $status'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }
}
