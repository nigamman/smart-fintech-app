import 'package:flutter_test/flutter_test.dart';
import 'package:fintech_app/core/services/encryption_helper.dart';
import 'package:fintech_app/features/transaction/data/models/transaction_model.dart';
import 'package:fintech_app/core/enums/transaction_category.dart';
import 'package:fintech_app/core/enums/transaction_type.dart';

void main() {
  group('EncryptionHelper Tests', () {
    const passphrase = 'my_secure_passphrase';
    const originalText = '{"amount":150.0,"note":"Lunch","category":"food"}';

    test('should encrypt and decrypt string successfully', () {
      final encrypted = EncryptionHelper.encrypt(originalText, passphrase);
      expect(encrypted, isNot(originalText));
      expect(encrypted.contains(':'), isTrue);

      final decrypted = EncryptionHelper.decrypt(encrypted, passphrase);
      expect(decrypted, originalText);
    });

    test('should fail to decrypt with wrong passphrase', () {
      final encrypted = EncryptionHelper.encrypt(originalText, passphrase);
      expect(
        () => EncryptionHelper.decrypt(encrypted, 'wrong_passphrase'),
        throwsException,
      );
    });

    test('should fail to decrypt malformed ciphertext', () {
      expect(
        () => EncryptionHelper.decrypt('invalid_format', passphrase),
        throwsException,
      );
    });
  });

  group('TransactionModel Encryption Tests', () {
    const passphrase = 'sync_passphrase_123';
    final originalModel = TransactionModel(
      id: 'tx_123',
      userId: 'user_456',
      amount: 120.5,
      type: TransactionType.expense,
      category: TransactionCategory.shopping,
      note: 'New shoes',
      transactionDate: DateTime(2026, 7, 19, 10, 0),
      createdAt: DateTime(2026, 7, 19, 10, 0),
    );

    test('should encrypt transaction details into isEncrypted and encryptedData', () {
      final encryptedModel = originalModel.encrypt(passphrase);

      expect(encryptedModel.id, originalModel.id);
      expect(encryptedModel.userId, originalModel.userId);
      expect(encryptedModel.transactionDate, originalModel.transactionDate);
      expect(encryptedModel.isEncrypted, isTrue);
      expect(encryptedModel.encryptedData, isNotNull);
      
      // Sensitive fields should be wiped/defaulted in the outer encrypted model
      expect(encryptedModel.amount, 0.0);
      expect(encryptedModel.category, TransactionCategory.other);
      expect(encryptedModel.note, isNull);
    });

    test('should decrypt transaction details successfully back to original state', () {
      final encryptedModel = originalModel.encrypt(passphrase);
      final decryptedModel = encryptedModel.decrypt(passphrase);

      expect(decryptedModel.id, originalModel.id);
      expect(decryptedModel.userId, originalModel.userId);
      expect(decryptedModel.amount, originalModel.amount);
      expect(decryptedModel.type, originalModel.type);
      expect(decryptedModel.category, originalModel.category);
      expect(decryptedModel.note, originalModel.note);
      expect(decryptedModel.transactionDate, originalModel.transactionDate);
      expect(decryptedModel.createdAt, originalModel.createdAt);
      expect(decryptedModel.isEncrypted, isFalse);
      expect(decryptedModel.encryptedData, isNull);
    });
  });
}
