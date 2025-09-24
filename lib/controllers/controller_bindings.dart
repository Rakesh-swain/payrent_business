import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/google_auth_controller.dart';
import '../controllers/phone_auth_controller.dart';
import '../controllers/user_profile_controller.dart';
import '../controllers/property_controller.dart';
import '../controllers/tenant_controller.dart';
import '../controllers/payment_controller.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ControllerBindings implements Bindings {
  @override
  void dependencies() {
    // Initialize services first
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<FirestoreService>(() => FirestoreService(), fenix: true);
    Get.lazyPut<StorageService>(() => StorageService(), fenix: true);
    
    // Initialize core controllers
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    
    // Initialize auth controllers
    Get.lazyPut<PhoneAuthController>(() => PhoneAuthController(), fenix: true);
    Get.lazyPut<GoogleAuthController>(() => GoogleAuthController(), fenix: true);
    
    // Initialize profile controller
    Get.lazyPut<UserProfileController>(() => UserProfileController(), fenix: true);
    
    // Initialize data management controllers
  }
}
