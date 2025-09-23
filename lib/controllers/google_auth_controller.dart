import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class GoogleAuthController extends GetxController {
  final AuthService _authService = AuthService();
  
  // Observables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Sign in with Google
  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final userCredential = await _authService.signInWithGoogle();
      
      isLoading.value = false;
      
      if (userCredential != null && userCredential.user != null) {
        // Check if this is a new user
        bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser) {
          // Create user profile in Firestore
          await _createUserProfile(userCredential.user!);
          
          // Navigate to complete profile page (to collect additional info)
          Get.offAllNamed('/complete-profile');
        } else {
          // Navigate to home page or dashboard
          Get.offAllNamed('/dashboard');
        }
      } else {
        errorMessage.value = 'Google sign in was canceled';
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Google sign in failed: $e';
      print('Error signing in with Google: $e');
    }
  }
  
  // Create user profile
  Future<void> _createUserProfile(User user) async {
    try {
      // Extract information from Google user
      final displayName = user.displayName ?? '';
      
      // Split display name into first and last name
      final nameList = displayName.split(' ');
      final firstName = nameList.isNotEmpty ? nameList.first : '';
      final lastName = nameList.length > 1 ? nameList.last : '';
      
      await _authService.createUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        name: displayName,
        businessName: '',
        profileImage: user.photoURL,
        userType: 'landlord', // Default to landlord, can be updated later
      );
    } catch (e) {
      print('Error creating user profile: $e');
      errorMessage.value = 'Failed to create user profile';
    }
  }
}
