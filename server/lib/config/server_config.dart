import 'package:dotenv/dotenv.dart';

class ServerConfig {
  static final ServerConfig _instance = ServerConfig._internal();
  factory ServerConfig() => _instance;
  ServerConfig._internal();

  late final DotEnv _env;

  void init() {
    _env = DotEnv(includePlatformEnvironment: true)..load();
  }

  String get secretKey => _env['SECRET_KEY'] ?? 'connect-hr-super-secret-jwt-key-2026';
  String? get mongoUri => _env['MONGO_URI'];
  int get port => int.tryParse(_env['PORT'] ?? '') ?? 5000;
  String get host => _env['HOST'] ?? '0.0.0.0';
}
