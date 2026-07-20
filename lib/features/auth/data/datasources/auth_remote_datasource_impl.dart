import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  Future<void> updateProfile(UserModel user) async {
    await firestore
        .collection(FirestoreCollections.users)
        .doc(user.id)
        .set(user.toJson(), SetOptions(merge: true));
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
  Future<UserModel> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      
      // Initialize the GoogleSignIn instance lazily before authenticating
      await googleSignIn.initialize(
        serverClientId: '545085974690-30qmmg04gchtg274jsoepjssj6s8184s.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        throw const AuthException('Google sign in cancelled by user.');
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      // Access Token requires explicit scope authorization in v7.0.0+
      final List<String> scopes = ['email', 'profile'];
      final clientAuth = await googleUser.authorizationClient.authorizeScopes(scopes);
      final String? accessToken = clientAuth?.accessToken;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final UserCredential userCredential = await auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException('Firebase Auth sign in failed.');
      }

      final uid = firebaseUser.uid;
      final snapshot = await firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();

      if (snapshot.exists) {
        return UserModel.fromJson(snapshot.data()!);
      }

      // First time Google Sign In - create profile
      final newUser = UserModel(
        id: uid,
        name: firebaseUser.displayName ?? 'Google User',
        email: firebaseUser.email ?? '',
        monthlyIncome: 0.0,
        monthlySavingsGoal: 0.0,
        createdAt: DateTime.now().toUtc(),
      );

      await firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .set(newUser.toJson());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'An error occurred during Google sign in.');
    } catch (e) {
      throw AuthException(e.toString());
    }
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