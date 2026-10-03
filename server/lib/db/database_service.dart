import 'dart:math';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import '../config/server_config.dart';
import '../utils/password_hasher.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Db? _mongoDb;

  // In-memory collections store as fallback
  final Map<String, List<Map<String, dynamic>>> _memoryStore = {
    'employees': [],
    'hr_users': [],
    'attendance': [],
    'leaves': [],
    'payslips': [],
    'salary_structures': [],
    'announcements': [],
    'expenses': [],
    'tickets': [],
    'documents': [],
    'assets': [],
    'notifications': [],
  };

  bool get isConnectedToMongo => _mongoDb != null && _mongoDb!.isConnected;

  Future<void> connect() async {
    final uri = ServerConfig().mongoUri;
    if (uri != null && uri.trim().isNotEmpty) {
      try {
        print('Connecting to MongoDB Atlas at $uri...');
        _mongoDb = await Db.create(uri);
        await _mongoDb!.open();
        print('✅ Connected to MongoDB Atlas successfully.');
      } catch (e) {
        print('⚠️ MongoDB connection failed ($e). Falling back to internal Memory Store.');
      }
    } else {
      print('ℹ️ No MONGO_URI specified. Running with high-performance Internal In-Memory Store.');
    }

    // Seed default HR and Employee test accounts in active database and memory store
    await _seedDefaultData();
  }

  Future<void> _seedDefaultData() async {
    final hrHash = PasswordHasher.hashPassword('admin123');
    final empHash = PasswordHasher.hashPassword('password123');

    if (isConnectedToMongo) {
      try {
        final hrCol = _mongoDb!.collection('hr_users');
        final existingHr = await hrCol.findOne(where.eq('email', 'hr@connect.com'));
        if (existingHr == null) {
          await hrCol.insertOne({
            'name': 'Sarah Jenkins (HR)',
            'email': 'hr@connect.com',
            'password': hrHash,
            'role': 'HR',
            'department': 'Human Resources',
          });
          print('✅ Seeded default HR account into MongoDB: hr@connect.com');
        } else {
          // Update password and role to ensure admin123 always works
          await hrCol.updateOne(
            where.eq('email', 'hr@connect.com'),
            modify.set('password', hrHash).set('role', 'HR'),
          );
        }

        final empCol = _mongoDb!.collection('employees');
        final existingEmp = await empCol.findOne(where.eq('email', 'john@connect.com'));
        if (existingEmp == null) {
          await empCol.insertOne({
            'name': 'John Doe',
            'email': 'john@connect.com',
            'password': empHash,
            'role': 'employee',
            'department': 'Engineering',
          });
          await empCol.insertOne({
            'name': 'Emily Watson',
            'email': 'emily@connect.com',
            'password': empHash,
            'role': 'employee',
            'department': 'Design',
          });
          print('✅ Seeded default employee accounts into MongoDB');
        } else {
          await empCol.updateOne(
            where.eq('email', 'john@connect.com'),
            modify.set('password', empHash),
          );
        }
      } catch (e) {
        print('⚠️ Error during Mongo default seeding: $e');
      }
    }

    // Seed default HR account in memory store
    if (_memoryStore['hr_users']!.isEmpty) {
      _memoryStore['hr_users']!.add({
        '_id': 'hr_admin_001',
        'name': 'Sarah Jenkins (HR)',
        'email': 'hr@connect.com',
        'password': hrHash,
        'role': 'HR',
        'department': 'Human Resources',
      });
    }

    // Seed default employee account in memory store
    if (_memoryStore['employees']!.isEmpty) {
      _memoryStore['employees']!.add({
        '_id': 'emp_001',
        'name': 'John Doe',
        'email': 'john@connect.com',
        'password': empHash,
        'role': 'employee',
        'department': 'Engineering',
      });
      _memoryStore['employees']!.add({
        '_id': 'emp_002',
        'name': 'Emily Watson',
        'email': 'emily@connect.com',
        'password': empHash,
        'role': 'employee',
        'department': 'Design',
      });
    }

    // Seed Announcements
    if (_memoryStore['announcements']!.isEmpty) {
      _memoryStore['announcements']!.add({
        '_id': 'ann_001',
        'title': '🎉 Annual Company Retreat 2026',
        'content': 'We are thrilled to announce our Annual Tech & Culture Retreat next month in Goa! Travel and accommodation details are available in the portal.',
        'category': 'Event',
        'is_pinned': true,
        'priority': 'High',
        'author_name': 'Sarah Jenkins (HR)',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'read_by': [],
      });
      _memoryStore['announcements']!.add({
        '_id': 'ann_002',
        'title': '📋 Updated Remote Work Policy',
        'content': 'All engineering and design teams can take up to 2 flexible WFH days per week with manager coordination.',
        'category': 'Policy',
        'is_pinned': false,
        'priority': 'Normal',
        'author_name': 'Sarah Jenkins (HR)',
        'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'read_by': [],
      });
    }

    // Seed Payslips
    if (_memoryStore['payslips']!.isEmpty) {
      _memoryStore['payslips']!.add({
        '_id': 'pay_001',
        'employee_id': 'emp_001',
        'employee_name': 'John Doe',
        'month': 'September',
        'year': 2026,
        'basic_salary': 4500.0,
        'hra': 1800.0,
        'allowances': 700.0,
        'deductions': 250.0,
        'tax': 450.0,
        'gross_salary': 7000.0,
        'net_salary': 6300.0,
        'payment_status': 'Paid',
        'generated_date': '2026-09-30',
      });
    }

    // Seed Assets
    if (_memoryStore['assets']!.isEmpty) {
      _memoryStore['assets']!.add({
        '_id': 'ast_001',
        'name': 'MacBook Pro 16" M3 Max',
        'category': 'Laptop',
        'serial_number': 'MBP-2026-98124',
        'assigned_to_id': 'emp_001',
        'assigned_to_name': 'John Doe',
        'status': 'In Use',
        'assigned_date': '2026-01-15',
      });
      _memoryStore['assets']!.add({
        '_id': 'ast_002',
        'name': 'Dell UltraSharp 27" 4K Monitor',
        'category': 'Hardware',
        'serial_number': 'DEL-4K-00213',
        'assigned_to_id': 'emp_001',
        'assigned_to_name': 'John Doe',
        'status': 'In Use',
        'assigned_date': '2026-02-01',
      });
    }

    // Seed Notifications
    if (_memoryStore['notifications']!.isEmpty) {
      _memoryStore['notifications']!.add({
        '_id': 'notif_001',
        'user_id': 'emp_001',
        'title': 'Welcome to Connect HR 🎉',
        'message': 'Your workplace account is configured and ready. Check your dashboard for daily actions.',
        'type': 'general',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // --- Collection Accessors ---

  Future<Map<String, dynamic>?> findOne(String collection, Map<String, dynamic> query) async {
    if (isConnectedToMongo) {
      final col = _mongoDb!.collection(collection);
      final selector = _buildMongoSelector(query);
      final doc = await col.findOne(selector);
      return doc != null ? _normalizeDoc(doc) : null;
    }

    final items = _memoryStore[collection] ?? [];
    for (final item in items) {
      bool match = true;
      query.forEach((key, val) {
        if (key == '_id' && item['_id'] != val.toString()) match = false;
        if (key != '_id' && item[key] != val) match = false;
      });
      if (match) return Map<String, dynamic>.from(item);
    }
    return null;
  }

  static String cleanId(dynamic id) {
    if (id == null) return '';
    if (id is ObjectId) return id.oid;
    var str = id.toString().trim();
    if (str.startsWith('ObjectId("') && str.endsWith('")')) {
      str = str.substring(10, str.length - 2);
    }
    if (str.startsWith('ObjectId(\'') && str.endsWith('\')')) {
      str = str.substring(10, str.length - 2);
    }
    return str;
  }

  Future<Map<String, dynamic>?> findById(String collection, String id) async {
    final cleaned = cleanId(id);
    if (isConnectedToMongo) {
      final col = _mongoDb!.collection(collection);
      try {
        if (cleaned.length == 24) {
          final doc = await col.findOne(where.id(ObjectId.parse(cleaned)));
          if (doc != null) return _normalizeDoc(doc);
        }
      } catch (_) {}
      try {
        final doc = await col.findOne(where.eq('_id', id));
        if (doc != null) return _normalizeDoc(doc);
      } catch (_) {}
      return null;
    }

    final items = _memoryStore[collection] ?? [];
    for (final item in items) {
      if (cleanId(item['_id']) == cleaned || item['_id'] == id) return Map<String, dynamic>.from(item);
    }
    return null;
  }

  Future<String> insertOne(String collection, Map<String, dynamic> doc) async {
    if (isConnectedToMongo) {
      final col = _mongoDb!.collection(collection);
      final docToInsert = Map<String, dynamic>.from(doc);
      if (!docToInsert.containsKey('_id')) {
        docToInsert['_id'] = ObjectId();
      }
      await col.insertOne(docToInsert);
      return cleanId(docToInsert['_id']);
    }

    final docToInsert = Map<String, dynamic>.from(doc);
    final id = docToInsert['_id']?.toString() ?? 'id_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    docToInsert['_id'] = id;
    _memoryStore.putIfAbsent(collection, () => []).add(docToInsert);
    return id;
  }

  Future<bool> updateOne(String collection, Map<String, dynamic> query, Map<String, dynamic> setFields) async {
    if (isConnectedToMongo) {
      final col = _mongoDb!.collection(collection);
      final selector = _buildMongoSelector(query);
      var mod = modify;
      setFields.forEach((k, v) {
        mod = mod.set(k, v);
      });
      final res = await col.updateOne(selector, mod);
      return res.isSuccess;
    }

    final items = _memoryStore[collection] ?? [];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      bool match = true;
      query.forEach((key, val) {
        if (key == '_id' && item['_id'] != val.toString()) match = false;
        if (key != '_id' && item[key] != val) match = false;
      });
      if (match) {
        items[i].addAll(setFields);
        return true;
      }
    }
    return false;
  }

  Future<bool> deleteOne(String collection, Map<String, dynamic> query) async {
    if (isConnectedToMongo) {
      final col = _mongoDb!.collection(collection);
      final selector = _buildMongoSelector(query);
      final res = await col.deleteOne(selector);
      return res.isSuccess;
    }

    final items = _memoryStore[collection] ?? [];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      bool match = true;
      query.forEach((key, val) {
        if (key == '_id' && item['_id'] != val.toString()) match = false;
        if (key != '_id' && item[key] != val) match = false;
      });
      if (match) {
        items.removeAt(i);
        return true;
      }
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> find(
    String collection, {
    Map<String, dynamic>? query,
    int? limit,
    String? sortField,
    bool sortDescending = false,
  }) async {
    if (isConnectedToMongo) {
      final col = _mongoDb!.collection(collection);
      var sel = query != null ? _buildMongoSelector(query) : where;
      if (sortField != null) {
        sel = sel.sortBy(sortField, descending: sortDescending);
      }
      if (limit != null) {
        sel = sel.limit(limit);
      }
      final docs = await col.find(sel).toList();
      return docs.map(_normalizeDoc).toList();
    }

    var items = List<Map<String, dynamic>>.from(_memoryStore[collection] ?? []);
    if (query != null) {
      items = items.where((item) {
        for (final entry in query.entries) {
          if (entry.key == '_id' && item['_id'] != entry.value.toString()) return false;
          if (entry.key != '_id' && item[entry.key] != entry.value) return false;
        }
        return true;
      }).toList();
    }

    if (sortField != null) {
      items.sort((a, b) {
        final aVal = a[sortField]?.toString() ?? '';
        final bVal = b[sortField]?.toString() ?? '';
        return sortDescending ? bVal.compareTo(aVal) : aVal.compareTo(bVal);
      });
    }

    if (limit != null && items.length > limit) {
      items = items.sublist(0, limit);
    }

    return items;
  }

  Future<int> count(String collection, [Map<String, dynamic>? query]) async {
    if (isConnectedToMongo) {
      final col = _mongoDb!.collection(collection);
      if (query == null || query.isEmpty) {
        return await col.count();
      }
      return await col.count(_buildMongoSelector(query));
    }

    if (query == null || query.isEmpty) {
      return (_memoryStore[collection] ?? []).length;
    }

    final items = _memoryStore[collection] ?? [];
    return items.where((item) {
      for (final entry in query.entries) {
        if (entry.key == '_id' && item['_id'] != entry.value.toString()) return false;
        if (entry.key != '_id' && item[entry.key] != entry.value) return false;
      }
      return true;
    }).length;
  }

  // --- Helper methods ---

  SelectorBuilder _buildMongoSelector(Map<String, dynamic> query) {
    var sel = where;
    query.forEach((key, val) {
      if (key == '_id') {
        final clean = cleanId(val);
        if (clean.length == 24) {
          try {
            sel = sel.id(ObjectId.parse(clean));
            return;
          } catch (_) {}
        }
        sel = sel.eq('_id', val);
      } else {
        sel = sel.eq(key, val);
      }
    });
    return sel;
  }

  Map<String, dynamic> _normalizeDoc(Map<String, dynamic> doc) {
    final result = Map<String, dynamic>.from(doc);
    if (result['_id'] is ObjectId) {
      result['_id'] = (result['_id'] as ObjectId).oid;
    } else if (result['_id'] != null) {
      result['_id'] = result['_id'].toString();
    }
    return result;
  }
}
