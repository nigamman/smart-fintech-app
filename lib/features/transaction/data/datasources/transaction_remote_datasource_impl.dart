import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../models/transaction_model.dart';
import 'transaction_remote_datasource.dart';

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  TransactionRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  String get _currentUserId {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _userTransactionsRef(String userId) {
    return firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.transactions);
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await _userTransactionsRef(transaction.userId)
        .doc(transaction.id)
        .set(transaction.toJson());
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _userTransactionsRef(transaction.userId)
        .doc(transaction.id)
        .update(transaction.toJson());
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    final uid = _currentUserId;
    await _userTransactionsRef(uid).doc(transactionId).delete();
  }

  @override
  Future<TransactionModel?> getTransactionById(String transactionId) async {
    final uid = _currentUserId;
    final snapshot = await _userTransactionsRef(uid).doc(transactionId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return TransactionModel.fromJson(snapshot.data()!);
  }

  @override
  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _userTransactionsRef(userId)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromJson(doc.data()))
          .toList();
    });
  }
}
