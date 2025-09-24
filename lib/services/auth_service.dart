import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // User model stream
  Stream<UserModel?> get userModelStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromFirestore(doc);
        } else {
          return null;
        }
      } catch (e) {
        print('Error getting user model: $e');
        return null;
      }
    });
  }
  
  // Get user model by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }
  
  // Sign in with phone - send verification code
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    required Function(String, int?) codeSent,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String) codeAutoRetrievalTimeout,
    required Function(PhoneAuthCredential) verificationCompleted,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }
  
  // Sign in with phone - verify code
  Future<UserCredential> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    
    return await _auth.signInWithCredential(credential);
  }
  
  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
   try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

    if (googleUser == null) {
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  } catch (e) {
    print('Google Sign-In Error: $e');
    return null;
  }
  }
  
  // Create user profile in Firestore
  Future<void> createUserProfile({
    required String uid,
    String? email,
    String? phone,
    required String name,
    required String businessName,
    required String userType,
    String? profileImage,
    String? countryCode,
  }) async {
    final UserModel user = UserModel(
      uid: uid,
      email: email,
      phone: phone,
      name: name,
      businessName: businessName,
      profileImage: profileImage,
      userType: userType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isVerified: false,
      countryCode: countryCode
    );
    
    await _firestore.collection('users').doc(uid).set(user.toFirestore());
  }
  
  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? email,
    String? phone,
    String? name,
    String? businessName,
    String? profileImage,
    String? userType,
    bool? isVerified,
    Map<String, dynamic>? additionalInfo,
    String? address,
  }) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    
    if (userDoc.exists) {
      final currentUser = UserModel.fromFirestore(userDoc);
      final updatedUser = currentUser.copyWith(
        email: email,
        phone: phone,
        name: name,
        businessName: businessName,
        profileImage: profileImage,
        userType: userType,
        isVerified: isVerified,
        additionalInfo: additionalInfo,
        address: address,
      );
      
      await _firestore.collection('users').doc(uid).update(updatedUser.toFirestore());
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
  
  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile({required String uid}) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
}
