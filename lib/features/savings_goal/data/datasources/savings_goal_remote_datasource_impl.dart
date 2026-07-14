import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../models/savings_goal_model.dart';
import 'savings_goal_remote_datasource.dart';

class SavingsGoalRemoteDataSourceImpl implements SavingsGoalRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SavingsGoalRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _currentUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _goalsRef(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.savingsGoals);
  }

  @override
  Future<void> saveGoal(SavingsGoalModel goal) async {
    await _goalsRef(goal.userId).doc(goal.id).set(goal.toJson());
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final uid = _currentUserId;
    await _goalsRef(uid).doc(goalId).delete();
  }

  @override
  Stream<List<SavingsGoalModel>> getGoals(String userId) {
    return _goalsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SavingsGoalModel.fromJson(doc.data()))
          .toList();
    });
  }
}
