import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payrent_business/services/auth_service.dart';

// Updated PhoneAuthController with better callback handling
class PhoneAuthController extends GetxController {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Observables
  final RxBool isLoading = false.obs;
  final RxBool isCodeSent = false.obs;
  final RxString verificationId = ''.obs;
  final RxInt? resendToken = null;
  final RxString errorMessage = ''.obs;
  // Text controllers
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  
  // Completer to handle async callbacks
  Completer<bool>? _verificationCompleter;
  
  // Send verification code with proper callback handling
  Future<bool> sendVerificationCode(String phoneNumber) async {

    isLoading.value = true;
    errorMessage.value = '';
    isCodeSent.value = false;
    
    // Create a completer to wait for the callback
    _verificationCompleter = Completer<bool>();
    
    try {
      await _authService.sendPhoneVerificationCode(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification completed (Android only)
          isLoading.value = false;
          try {
            await _auth.signInWithCredential(credential);
            if (!_verificationCompleter!.isCompleted) {
              _verificationCompleter!.complete(true);
            }
          } catch (e) {
            if (!_verificationCompleter!.isCompleted) {
              _verificationCompleter!.complete(false);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          errorMessage.value = e.message ?? 'Verification failed';
          print('Phone auth error: ${e.message}');
          if (!_verificationCompleter!.isCompleted) {
            _verificationCompleter!.complete(false);
          }
        },
        codeSent: (String verId, int? resendingToken) {
          isLoading.value = false;
          isCodeSent.value = true;
          verificationId.value = verId;
          // resendToken!.value = resendingToken??0;
          print('Verification code sent to $phoneNumber');
          if (!_verificationCompleter!.isCompleted) {
            _verificationCompleter!.complete(true);
          }
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId.value = verId;
          // Don't complete here, wait for codeSent or verificationFailed
        },
      );
      
      // Wait for the callback to complete
      return await _verificationCompleter!.future;
      
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Error sending verification code: $e';
      print('Error sending verification code: $e');
      if (!_verificationCompleter!.isCompleted) {
        _verificationCompleter!.complete(false);
      }
      return false;
    }
  }
  
  // Verify OTP code
  Future<bool> verifyOtp(String smsCode) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: smsCode,
      );
      
      await _auth.signInWithCredential(credential);
      isLoading.value = false;
      return true;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Invalid verification code';
      print('Error verifying OTP: $e');
      return false;
    }
  }
  
  // Reset
  void reset() {
    isCodeSent.value = false;
    verificationId.value = '';
    resendToken?.value = 0;
    errorMessage.value = '';
    otpController.clear();
    _verificationCompleter = null;
  }
  
  @override
  void onClose() {
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }
}

