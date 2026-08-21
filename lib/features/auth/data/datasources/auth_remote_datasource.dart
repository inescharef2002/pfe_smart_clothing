import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(
      String email, String password, String name);
  Future<void> forgotPassword(String email);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithGoogle();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.getIdToken(true);
    final userDoc =
        await firestore.collection('users').doc(credential.user!.uid).get();
    if (!userDoc.exists) {
      return UserModel(
        id: credential.user!.uid,
        email: email,
        name: credential.user!.displayName,
      );
    }
    return UserModel.fromMap(userDoc.data()!, credential.user!.uid);
  }

  @override
  Future<UserModel> registerWithEmail(
      String email, String password, String name) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.getIdToken(true);
    final userModel = UserModel(
      id: credential.user!.uid,
      email: email,
      name: name,
    );
    await firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(userModel.toMap());
    return userModel;
  }

  @override
  Future<void> forgotPassword(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> logout() async {
    try {
      // ✅ Déconnecter Google Sign-In si connecté via Google
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {
          // Ignorer si pas connecté via Google
        }
      }
      // ✅ Déconnecter Firebase APRÈS (plus d'accès Firestore possible après)
      await firebaseAuth.signOut();
    } catch (e) {
      // Ignorer les erreurs de déconnexion
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    try {
      await user.getIdToken(true);
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;
      return UserModel.fromMap(userDoc.data()!, user.uid);
    } catch (e) {
      // Token expiré ou révoqué → retourner null
      return null;
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final User firebaseUser;

    if (kIsWeb) {
      final userCredential =
          await firebaseAuth.signInWithPopup(GoogleAuthProvider());
      firebaseUser = userCredential.user!;
    } else {
      try {
        final googleAccount = await GoogleSignIn.instance.authenticate();
        final idToken = googleAccount.authentication.idToken;
        if (idToken == null) throw Exception('Token Google indisponible');
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        final userCredential =
            await firebaseAuth.signInWithCredential(credential);
        firebaseUser = userCredential.user!;
      } catch (e) {
        // ✅ Gérer l'annulation Google Sign-In proprement
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('canceled') ||
            errorStr.contains('cancelled') ||
            errorStr.contains('sign_in_canceled') ||
            errorStr.contains('sign_in_failed')) {
          throw Exception('Connexion Google annulée');
        }
        rethrow;
      }
    }

    await firebaseUser.getIdToken(true);
    final userDoc =
        await firestore.collection('users').doc(firebaseUser.uid).get();

    if (!userDoc.exists) {
      final userModel = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
      );
      await firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userModel.toMap());
      return userModel;
    }

    return UserModel.fromMap(userDoc.data()!, firebaseUser.uid);
  }
}
