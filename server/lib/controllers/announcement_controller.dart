import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database_service.dart';
import '../middleware/auth_middleware.dart';

class AnnouncementController {
  final DatabaseService _db = DatabaseService();

  Router get router {
    final router = Router();
    router.get('/', _handleGetAnnouncements);
    router.post('/', _handleCreateAnnouncement);
    router.delete('/<id>', _handleDeleteAnnouncement);
    router.post('/<id>/read', _handleMarkAsRead);
    return router;
  }



  // Get all announcements
  Future<Response> _handleGetAnnouncements(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final announcements = await _db.find('announcements', sortField: 'created_at', sortDescending: true);
      // Sort pinned announcements to top
      announcements.sort((a, b) {
        final aPinned = a['is_pinned'] == true ? 1 : 0;
        final bPinned = b['is_pinned'] == true ? 1 : 0;
        return bPinned.compareTo(aPinned);
      });

      return Response(200, body: jsonEncode(announcements), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // HR: Create an announcement
  Future<Response> _handleCreateAnnouncement(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final title = data['title']?.toString().trim();
      final content = data['content']?.toString().trim();
      final category = data['category']?.toString() ?? 'General';
      final isPinned = data['is_pinned'] == true;
      final priority = data['priority']?.toString() ?? 'Normal';

      if (title == null || title.isEmpty || content == null || content.isEmpty) {
        return Response(400, body: jsonEncode({'message': 'Title and content are required'}), headers: {'content-type': 'application/json'});
      }

      final id = await _db.insertOne('announcements', {
        'title': title,
        'content': content,
        'category': category,
        'is_pinned': isPinned,
        'priority': priority,
        'author_name': auth.user['name'] ?? 'HR Team',
        'created_at': DateTime.now().toIso8601String(),
        'read_by': [],
      });

      // Notify all employees
      final employees = await _db.find('employees');
      for (final emp in employees) {
        final empId = emp['_id']?.toString();
        if (empId != null) {
          await _db.insertOne('notifications', {
            'user_id': empId,
            'title': '📢 Announcement: $title',
            'message': content.length > 80 ? '${content.substring(0, 80)}...' : content,
            'type': 'announcement',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      return Response(201, body: jsonEncode({'id': id, 'message': 'Announcement published successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // HR: Delete announcement
  Future<Response> _handleDeleteAnnouncement(Request request, String id) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      await _db.deleteOne('announcements', {'_id': id});
      return Response(200, body: jsonEncode({'message': 'Announcement removed'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // Employee: Mark announcement as read
  Future<Response> _handleMarkAsRead(Request request, String id) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final userId = auth.user['_id'].toString();
      final announcement = await _db.findById('announcements', id);
      if (announcement != null) {
        final readBy = List<String>.from(announcement['read_by'] ?? []);
        if (!readBy.contains(userId)) {
          readBy.add(userId);
          await _db.updateOne('announcements', {'_id': id}, {'read_by': readBy});
        }
      }
      return Response(200, body: jsonEncode({'message': 'Marked as read'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }
}
