import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/property_controller.dart';
import '../services/firestore_service.dart';
import '../models/tenant_model.dart';
import '../models/property_model.dart';

class TenantController extends GetxController {
  static TenantController get to => Get.find();
  
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final PropertyController _propertyController = Get.find<PropertyController>();
  
  // Observables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxList<DocumentSnapshot> tenants = <DocumentSnapshot>[].obs;
  final RxList<DocumentSnapshot> filteredTenants = <DocumentSnapshot>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // fetchTenants();
  }
  
}