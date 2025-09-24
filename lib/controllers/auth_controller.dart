import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();
  
  final AuthService _authService = AuthService();
  
  // Observables
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> userModel = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Auth status
  final RxBool isLoggedIn = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    
    // Listen to Firebase auth state changes
    firebaseUser.bindStream(_authService.authStateChanges);
    
    // Update login status when Firebase user changes
    ever(firebaseUser, _setIsLoggedIn);
    
    // Listen to user model changes
    userModel.bindStream(_authService.userModelStream);
  }
  
  // Set login status
  void _setIsLoggedIn(User? user) {
    isLoggedIn.value = user != null;
  }
  
  // Sign out
  Future<void> signOut() async {
    isLoading.value = true;
    try {
      await _authService.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      errorMessage.value = 'Failed to sign out';
      print('Error signing out: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
 
  
  // Check user type
  bool get isLandlord => userModel.value?.isLandlord ?? false;
  bool get isTenant => userModel.value?.isTenant ?? false;
  
  // Get user info
  String get userName => userModel.value?.fullName ?? '';
  String? get userEmail => userModel.value?.email;
  String? get userPhone => userModel.value?.phone;
  String? get profileImageUrl => userModel.value?.profileImage;
  
  // Check if user account is verified
  bool get isVerified => userModel.value?.isVerified ?? false;
}
