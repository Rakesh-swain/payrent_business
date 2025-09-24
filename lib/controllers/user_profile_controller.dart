import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../controllers/auth_controller.dart';

class UserProfileController extends GetxController {
  static UserProfileController get to => Get.find();
  
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final AuthController _authController = Get.find<AuthController>();
  
  // Observables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxString profileImagePath = ''.obs;
  final RxString profileImageUrl = ''.obs;
  final RxString name = ''.obs;
  final RxString businessName = ''.obs;
  final RxString email = ''.obs;
  final RxString phone = ''.obs;
  final RxString userType = 'landlord'.obs;
  String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  // Upload profile image
  Future<void> uploadProfileImage(File imageFile) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }
      
      final uid = _authController.firebaseUser.value!.uid;
      
      // Upload to Firebase Storage
      final downloadUrl = await _storageService.uploadFile(
        file: imageFile,
        uploadPath: 'profile_images',
        customFileName: 'profile_$uid.jpg',
      );
      
      // Update user profile
      await _authService.updateUserProfile(uid: uid,
        profileImage: downloadUrl,
      );
      
      profileImagePath.value = downloadUrl;
      successMessage.value = 'Profile image updated successfully';
    } catch (e) {
      errorMessage.value = 'Failed to upload profile image';
      print('Error uploading profile image: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? businessName,
    String? email,
    String? phone,
    String? userType,
    String? address,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }
      
      await _authService.updateUserProfile(
        uid: uid,
        name: name,
        businessName: businessName,
        email: email,
        phone: phone,
        userType: userType,
        address: address
      );
      
      successMessage.value = 'Profile updated successfully';
    } catch (e) {
      errorMessage.value = 'Failed to update profile';
      print('Error updating profile: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  
  
  // Get user profile data
  Future<void> getUserProfile() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }
      
      final uid = _authController.firebaseUser.value!.uid;
      
      // Get user profile data
      final userData = await _authService.getUserProfile(uid: uid);
      
      if (userData != null) {
        name.value = userData['name'] ?? '';
        businessName.value = userData['businessName'] ?? '';
        email.value = userData['email'] ?? '';
        phone.value = userData['phone'] ?? '';
        userType.value = userData['userType'] ?? 'landlord';
        profileImageUrl.value = userData['profileImage'] ?? '';
      }
    } catch (e) {
      errorMessage.value = 'Failed to get user profile';
      print('Error getting user profile: $e');
    } finally {
      isLoading.value = false;
    }
  }
  @override
  void onInit() {
    getUserProfile();
    super.onInit();
  }
}
