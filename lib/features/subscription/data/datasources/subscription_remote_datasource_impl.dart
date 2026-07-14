import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../models/subscription_model.dart';
import 'subscription_remote_datasource.dart';

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SubscriptionRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _currentUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _subsRef(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.subscriptions);
  }

  @override
  Future<void> saveSubscription(SubscriptionModel subscription) async {
    await _subsRef(subscription.userId).doc(subscription.id).set(subscription.toJson());
  }

  @override
  Future<void> deleteSubscription(String subscriptionId) async {
    final uid = _currentUserId;
    await _subsRef(uid).doc(subscriptionId).delete();
  }

  @override
  Stream<List<SubscriptionModel>> getSubscriptions(String userId) {
    return _subsRef(userId)
        .orderBy('nextBillingDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SubscriptionModel.fromJson(doc.data()))
          .toList();
    });
  }
}
