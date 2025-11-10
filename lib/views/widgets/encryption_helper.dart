// 📁 lib/utils/encryption_helper.dart
import 'dart:convert';

class EncryptionHelper {
  /// Hàm mã hoá email & password trước khi gửi đi
  /// Trả về Map với key '54vtcnews'
  static Map<String, String> encodeCredentials(String email, String password) {
    final combined = "$email:$password";

    // Encode Base64
    final base64Encoded = base64Url.encode(utf8.encode(combined));

    return {
      'vtcnews': base64Encoded, // key tùy chọn
    };
  }
}
