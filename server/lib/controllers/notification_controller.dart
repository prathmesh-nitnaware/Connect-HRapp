import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database_service.dart';
import '../middleware/auth_middleware.dart';

class NotificationController {
  final DatabaseService _db = DatabaseService();

  Router get router {
    final router = Router();
    router.get('/', _handleGetNotifications);
    router.post('/read-all', _handleMarkAllRead);
    router.put('/read-all', _handleMarkAllRead);
    router.post('/<id>/read', _handleMarkOneRead);
    router.put('/<id>/read', _handleMarkOneRead);
    return router;
  }



  Future<Response> _handleGetNotifications(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final userId = auth.user['_id'].toString();
      final notifications = await _db.find('notifications', query: {'user_id': userId}, sortField: 'created_at', sortDescending: true);
      return Response(200, body: jsonEncode(notifications), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleMarkAllRead(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final userId = auth.user['_id'].toString();
      final userNotifs = await _db.find('notifications', query: {'user_id': userId});
      for (final n in userNotifs) {
        final id = n['_id']?.toString();
        if (id != null) {
          await _db.updateOne('notifications', {'_id': id}, {'is_read': true});
        }
      }
      return Response(200, body: jsonEncode({'message': 'All marked as read'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleMarkOneRead(Request request, String id) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      await _db.updateOne('notifications', {'_id': id}, {'is_read': true});
      return Response(200, body: jsonEncode({'message': 'Marked as read'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }
}
