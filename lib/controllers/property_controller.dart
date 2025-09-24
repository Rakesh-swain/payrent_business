import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/firestore_service.dart';

class PropertyController extends GetxController {
  static PropertyController get to => Get.find();
  
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  
  // Observables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxList<DocumentSnapshot> properties = <DocumentSnapshot>[].obs;
  final RxList<DocumentSnapshot> filteredProperties = <DocumentSnapshot>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchProperties();
  }
  
  // Fetch properties for current landlord
  Future<void> fetchProperties() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }
      
      final uid = _authController.firebaseUser.value!.uid;
      
      // Query properties where landlordId equals current user's ID
      final querySnapshot = await _firestoreService.queryDocuments(
        collection: 'properties',
        filters: [
          ['landlordId', uid],
        ],
      );
      
      properties.value = querySnapshot.docs;
      filteredProperties.value = querySnapshot.docs;
    } catch (e) {
      errorMessage.value = 'Failed to fetch properties';
      print('Error fetching properties: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
 
  
}
