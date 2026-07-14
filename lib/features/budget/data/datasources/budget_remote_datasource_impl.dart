import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../models/budget_model.dart';
import 'budget_remote_datasource.dart';

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BudgetRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _currentUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _budgetsRef(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.budgets);
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    await _budgetsRef(budget.userId).doc(budget.id).set(budget.toJson());
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    final uid = _currentUserId;
    await _budgetsRef(uid).doc(budgetId).delete();
  }

  @override
  Stream<List<BudgetModel>> getBudgets(String userId, int month, int year) {
    return _budgetsRef(userId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BudgetModel.fromJson(doc.data()))
          .toList();
    });
  }
}
