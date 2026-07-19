import 'dart:convert';
import '../../domain/entities/transaction.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/services/encryption_helper.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.amount,
    required super.type,
    required super.category,
    super.note,
    required super.transactionDate,
    required super.createdAt,
    super.isSplit = false,
    super.splitWith,
    super.splitPercentage = 50.0,
    super.isSplitPaid = false,
    super.isEncrypted = false,
    super.encryptedData,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final isEncrypted = json['isEncrypted'] as bool? ?? false;
    if (isEncrypted) {
      return TransactionModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        amount: 0.0,
        type: TransactionType.expense,
        category: TransactionCategory.other,
        transactionDate: DateTime.parse(json['transactionDate']),
        createdAt: DateTime.parse(json['transactionDate']),
        isEncrypted: true,
        encryptedData: json['encryptedData'] as String?,
      );
    }

    return TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
            (e) => e.name == json['type'],
      ),
      category: TransactionCategory.values.firstWhere(
            (e) => e.name == json['category'],
      ),
      note: json['note'] as String?,
      transactionDate: DateTime.parse(json['transactionDate']),
      createdAt: DateTime.parse(json['createdAt']),
      isSplit: json['isSplit'] as bool? ?? false,
      splitWith: json['splitWith'] as String?,
      splitPercentage: (json['splitPercentage'] as num?)?.toDouble() ?? 50.0,
      isSplitPaid: json['isSplitPaid'] as bool? ?? false,
      isEncrypted: false,
      encryptedData: null,
    );
  }

  Map<String, dynamic> toJson() {
    if (isEncrypted) {
      return {
        'id': id,
        'userId': userId,
        'transactionDate': transactionDate.toIso8601String(),
        'isEncrypted': true,
        'encryptedData': encryptedData,
      };
    }
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'note': note,
      'transactionDate': transactionDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isSplit': isSplit,
      'splitWith': splitWith,
      'splitPercentage': splitPercentage,
      'isSplitPaid': isSplitPaid,
      'isEncrypted': false,
      'encryptedData': null,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? note,
    DateTime? transactionDate,
    DateTime? createdAt,
    bool? isSplit,
    String? splitWith,
    double? splitPercentage,
    bool? isSplitPaid,
    bool? isEncrypted,
    String? encryptedData,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      isSplit: isSplit ?? this.isSplit,
      splitWith: splitWith ?? this.splitWith,
      splitPercentage: splitPercentage ?? this.splitPercentage,
      isSplitPaid: isSplitPaid ?? this.isSplitPaid,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      encryptedData: encryptedData ?? this.encryptedData,
    );
  }

  TransactionModel encrypt(String passphrase) {
    if (isEncrypted) return this;

    final Map<String, dynamic> dataToEncrypt = {
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'isSplit': isSplit,
      'splitWith': splitWith,
      'splitPercentage': splitPercentage,
      'isSplitPaid': isSplitPaid,
    };

    final encryptedPayload = EncryptionHelper.encrypt(
      json.encode(dataToEncrypt),
      passphrase,
    );

    return TransactionModel(
      id: id,
      userId: userId,
      amount: 0.0,
      type: TransactionType.expense,
      category: TransactionCategory.other,
      transactionDate: transactionDate,
      createdAt: transactionDate,
      isSplit: false,
      isSplitPaid: false,
      isEncrypted: true,
      encryptedData: encryptedPayload,
    );
  }

  TransactionModel decrypt(String passphrase) {
    if (!isEncrypted || encryptedData == null) return this;

    final decryptedJsonStr = EncryptionHelper.decrypt(
      encryptedData!,
      passphrase,
    );
    final decryptedMap = json.decode(decryptedJsonStr) as Map<String, dynamic>;

    return TransactionModel(
      id: id,
      userId: userId,
      amount: (decryptedMap['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
            (e) => e.name == decryptedMap['type'],
      ),
      category: TransactionCategory.values.firstWhere(
            (e) => e.name == decryptedMap['category'],
      ),
      note: decryptedMap['note'] as String?,
      transactionDate: transactionDate,
      createdAt: DateTime.parse(decryptedMap['createdAt']),
      isSplit: decryptedMap['isSplit'] as bool? ?? false,
      splitWith: decryptedMap['splitWith'] as String?,
      splitPercentage: (decryptedMap['splitPercentage'] as num?)?.toDouble() ?? 50.0,
      isSplitPaid: decryptedMap['isSplitPaid'] as bool? ?? false,
      isEncrypted: false,
      encryptedData: null,
    );
  }
}