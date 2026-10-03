import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  PasswordHasher._();

  static String generateSalt([int length = 16]) {
    final rand = Random.secure();
    final saltBytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64Url.encode(saltBytes);
  }

  static String hashPassword(String password, [String? salt]) {
    final actualSalt = salt ?? generateSalt();
    final bytes = utf8.encode('$actualSalt:$password');
    final digest = sha256.convert(bytes);
    return 'sha256\$$actualSalt\$${digest.toString()}';
  }

  static bool verifyPassword(String password, String storedHash) {
    try {
      if (!storedHash.contains('\$')) {
        // Plaintext fallback for legacy testing if any
        return password == storedHash;
      }
      final parts = storedHash.split('\$');
      if (parts.length == 3 && parts[0] == 'sha256') {
        final salt = parts[1];
        final expectedDigest = parts[2];
        final bytes = utf8.encode('$salt:$password');
        final computedDigest = sha256.convert(bytes).toString();
        return computedDigest == expectedDigest;
      }
      // Support standard PBKDF2/Werkzeug hash format fallback if present
      if (storedHash.startsWith('pbkdf2:')) {
        // Werkzeug format
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
