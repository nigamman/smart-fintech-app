import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/errors/auth_exception.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const AuthRemoteDataSourceImpl({
    required this.auth,
    required this.firestore,
  });

  @override
  Future<UserModel?> getCurrentUser() async {

    final firebaseUser = auth.currentUser;

    if (firebaseUser == null) return null;

    final snapshot = await firestore
        .collection(FirestoreCollections.users)
        .doc(firebaseUser.uid)
        .get();

    if (!snapshot.exists) return null;

    return UserModel.fromJson(snapshot.data()!);
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      final snapshot = await firestore
          .collection(FirestoreCollections.users)
          .doc(firebaseUser.uid)
          .get();

      if (!snapshot.exists) return null;

      return UserModel.fromJson(snapshot.data()!);
    });
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required double monthlyIncome,
    required double monthlySavingsGoal,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      monthlyIncome: monthlyIncome,
      monthlySavingsGoal: monthlySavingsGoal,
      createdAt: DateTime.now().toUtc(),
    );

    await firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .set(user.toJson());

    return user;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final snapshot = await firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    if (!snapshot.exists) {
      throw const AuthException(
        'User profile not found.',
      );
    }

    return UserModel.fromJson(snapshot.data()!);
  }

  @override
  Future<void> forgotPassword({
    required String email,
  }) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> logout() async {
    await auth.signOut();
  }
}