import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database_service.dart';
import '../middleware/auth_middleware.dart';

class DocumentAssetController {
  final DatabaseService _db = DatabaseService();

  Router get router {
    final router = Router();
    // Document Vault
    router.get('/documents', _handleGetMyDocuments);
    router.get('/documents/', _handleGetMyDocuments);
    router.get('/documents/my', _handleGetMyDocuments);
    router.post('/documents', _handleUploadDocument);
    router.post('/documents/', _handleUploadDocument);
    router.get('/documents/all', _handleGetAllDocuments);
    // Asset Management
    router.get('/assets', _handleGetMyAssets);
    router.get('/assets/', _handleGetMyAssets);
    router.get('/assets/my', _handleGetMyAssets);
    router.get('/assets/all', _handleGetAllAssets);
    router.post('/assets', _handleCreateAsset);
    router.post('/assets/', _handleCreateAsset);
    router.put('/assets/<id>', _handleUpdateAsset);
    return router;
  }


  // --- Documents Vault ---
  Future<Response> _handleGetMyDocuments(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final userId = auth.user['_id'].toString();
      final docs = await _db.find('documents', query: {'employee_id': userId}, sortField: 'uploaded_at', sortDescending: true);
      return Response(200, body: jsonEncode(docs), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleUploadDocument(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final title = data['title']?.toString().trim();
      final category = data['category']?.toString() ?? 'General';
      final fileName = data['file_name']?.toString() ?? 'Document.pdf';
      final fileBase64 = data['file_base64']?.toString();

      if (title == null || title.isEmpty) {
        return Response(400, body: jsonEncode({'message': 'Document title is required'}), headers: {'content-type': 'application/json'});
      }

      final id = await _db.insertOne('documents', {
        'employee_id': auth.user['_id'].toString(),
        'employee_name': auth.user['name'] ?? 'Employee',
        'title': title,
        'category': category,
        'file_name': fileName,
        'file_base64': fileBase64,
        'uploaded_at': DateTime.now().toIso8601String(),
        'status': 'Verified',
      });

      return Response(201, body: jsonEncode({'id': id, 'message': 'Document uploaded to vault'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleGetAllDocuments(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final docs = await _db.find('documents', sortField: 'uploaded_at', sortDescending: true);
      return Response(200, body: jsonEncode(docs), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  // --- Asset Management ---
  Future<Response> _handleGetMyAssets(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();

    try {
      final userId = auth.user['_id'].toString();
      final assets = await _db.find('assets', query: {'assigned_to_id': userId});
      return Response(200, body: jsonEncode(assets), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleGetAllAssets(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final assets = await _db.find('assets', sortField: 'assigned_date', sortDescending: true);
      return Response(200, body: jsonEncode(assets), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleCreateAsset(Request request) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final name = data['name']?.toString().trim();
      final category = data['category']?.toString() ?? 'Hardware';
      final serialNumber = data['serial_number']?.toString().trim() ?? 'N/A';
      final assignedToId = data['assigned_to_id']?.toString();
      final assignedToName = data['assigned_to_name']?.toString() ?? 'Unassigned';

      if (name == null || name.isEmpty) {
        return Response(400, body: jsonEncode({'message': 'Asset name is required'}), headers: {'content-type': 'application/json'});
      }

      final id = await _db.insertOne('assets', {
        'name': name,
        'category': category,
        'serial_number': serialNumber,
        'assigned_to_id': assignedToId,
        'assigned_to_name': assignedToName,
        'status': assignedToId != null ? 'In Use' : 'Available',
        'assigned_date': DateTime.now().toIso8601String().split('T').first,
      });

      return Response(201, body: jsonEncode({'id': id, 'message': 'Asset recorded successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _handleUpdateAsset(Request request, String id) async {
    final auth = await AuthMiddleware.authenticate(request);
    if (auth == null) return AuthMiddleware.unauthorized();
    if (!auth.isHR) return AuthMiddleware.forbidden();

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      await _db.updateOne('assets', {'_id': id}, data);
      return Response(200, body: jsonEncode({'message': 'Asset updated successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'message': 'Server error: $e'}), headers: {'content-type': 'application/json'});
    }
  }
}
