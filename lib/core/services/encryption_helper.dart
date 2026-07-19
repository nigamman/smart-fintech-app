import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionHelper {
  /// Encrypts plaintext using AES-256-CBC with a key derived from the passphrase via SHA-256.
  /// Returns a string formatted as "IV_BASE64:CIPHERTEXT_BASE64".
  static String encrypt(String plaintext, String passphrase) {
    final keyBytes = sha256.convert(utf8.encode(passphrase)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }

  /// Decrypts ciphertext formatted as "IV_BASE64:CIPHERTEXT_BASE64" using a key derived from the passphrase.
  static String decrypt(String ciphertextWithIv, String passphrase) {
    try {
      final parts = ciphertextWithIv.split(':');
      if (parts.length != 2) throw const FormatException('Invalid ciphertext format');
      final ivBytes = base64.decode(parts[0]);
      final encryptedBytes = base64.decode(parts[1]);

      final keyBytes = sha256.convert(utf8.encode(passphrase)).bytes;
      final key = enc.Key(Uint8List.fromList(keyBytes));
      final iv = enc.IV(Uint8List.fromList(ivBytes));

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(enc.Encrypted(encryptedBytes), iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }
}
