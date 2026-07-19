import 'package:flutter_test/flutter_test.dart';
import 'package:fintech_app/features/transaction/data/models/transaction_model.dart';
import 'package:fintech_app/core/enums/transaction_category.dart';
import 'package:fintech_app/core/enums/transaction_type.dart';

void main() {
  group('TransactionModel Split Billing Tests', () {
    test('default values are set correctly when fields are missing in json', () {
      final json = {
        'id': 'tx-123',
        'userId': 'user-456',
        'amount': 1000.0,
        'type': 'expense',
        'category': 'food',
        'note': 'Dinner split',
        'transactionDate': '2026-07-18T20:00:00.000Z',
        'createdAt': '2026-07-18T20:00:00.000Z',
      };

      final tx = TransactionModel.fromJson(json);

      expect(tx.isSplit, isFalse);
      expect(tx.splitWith, isNull);
      expect(tx.splitPercentage, 50.0);
      expect(tx.isSplitPaid, isFalse);
    });

    test('fields are serialized and deserialized correctly', () {
      final json = {
        'id': 'tx-123',
        'userId': 'user-456',
        'amount': 1500.0,
        'type': 'expense',
        'category': 'shopping',
        'note': 'Shoes split',
        'transactionDate': '2026-07-18T20:00:00.000Z',
        'createdAt': '2026-07-18T20:00:00.000Z',
        'isSplit': true,
        'splitWith': 'Raj',
        'splitPercentage': 30.0,
        'isSplitPaid': true,
      };

      final tx = TransactionModel.fromJson(json);

      expect(tx.isSplit, isTrue);
      expect(tx.splitWith, 'Raj');
      expect(tx.splitPercentage, 30.0);
      expect(tx.isSplitPaid, isTrue);

      final serialized = tx.toJson();
      expect(serialized['isSplit'], isTrue);
      expect(serialized['splitWith'], 'Raj');
      expect(serialized['splitPercentage'], 30.0);
      expect(serialized['isSplitPaid'], isTrue);
    });

    test('copyWith modifies split fields correctly', () {
      final tx = TransactionModel(
        id: 'tx-123',
        userId: 'user-456',
        amount: 200.0,
        type: TransactionType.expense,
        category: TransactionCategory.travel,
        note: 'Cab ride',
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final updated = tx.copyWith(
        isSplit: true,
        splitWith: 'Simran',
        splitPercentage: 40.0,
        isSplitPaid: true,
      );

      expect(updated.isSplit, isTrue);
      expect(updated.splitWith, 'Simran');
      expect(updated.splitPercentage, 40.0);
      expect(updated.isSplitPaid, isTrue);

      // Verify that other fields remain unchanged
      expect(updated.id, 'tx-123');
      expect(updated.amount, 200.0);
    });

    test('deducting friend share calculates net out-of-pocket correctly', () {
      final tx = TransactionModel(
        id: 'tx-123',
        userId: 'user-456',
        amount: 1000.0,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        note: 'Dinner',
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        isSplit: true,
        splitWith: 'Rahul',
        splitPercentage: 60.0, // friend pays 60%
        isSplitPaid: false,
      );

      final friendShare = tx.amount * ((tx.splitPercentage ?? 50.0) / 100);
      final myShare = tx.amount - friendShare;

      expect(friendShare, 600.0);
      expect(myShare, 400.0);
    });
  });
}
