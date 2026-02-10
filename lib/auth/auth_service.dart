import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floodsense/auth/app_user.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //Sign up with email & password
  Future<AppUser?> signUp({
    required String email, 
    required String password, 
    String? phone}) 
    async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final uid = credential.user?.uid;

    final appUser = AppUser(
      uid: uid!,
      email: email,
      role: "user",
      phoneNumber: phone,
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .set(appUser.toJson());

    return appUser;
  }

  //Login with email & password
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final uid = credential.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();

    return AppUser.fromJson(doc.data()!);
  }

  //Forgot password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  //get current user
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc =
        await _firestore.collection('users').doc(user.uid).get();

    return AppUser.fromJson(doc.data()!);
}


  //delete user account
  Future<void> deleteUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }

  //Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
