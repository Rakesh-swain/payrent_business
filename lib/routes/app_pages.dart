import 'package:get/get.dart';
import 'package:payrent_business/routes/app_routes.dart';

// Auth screens
import 'package:payrent_business/screens/auth/intro_page.dart';
import 'package:payrent_business/screens/auth/login_page.dart';
import 'package:payrent_business/screens/auth/otp_page.dart';
import 'package:payrent_business/screens/auth/profile_signup_page.dart';
import 'package:payrent_business/screens/auth/signup_successful_page.dart';
import 'package:payrent_business/screens/auth/splash_page.dart';
import 'package:payrent_business/screens/auth/verification_complete_page.dart';
import 'package:payrent_business/services/firebase_initializer.dart';

// Landlord screens
import 'package:payrent_business/screens/landlord/landlord_dashboard_page.dart';
import 'package:payrent_business/screens/landlord/property_management/manage_properties_page.dart';
import 'package:payrent_business/screens/landlord/property_management/property_detail_page.dart';
import 'package:payrent_business/screens/landlord/property_management/add_property_page.dart';
import 'package:payrent_business/screens/landlord/property_management/edit_property_page.dart';
import 'package:payrent_business/screens/landlord/property_management/unit_details_page.dart';
import 'package:payrent_business/screens/landlord/property_management/bulk_upload_page.dart';
import 'package:payrent_business/screens/landlord/property_management/template_viewer_page.dart';

import 'package:payrent_business/screens/landlord/payments/payment_list_page.dart';
import 'package:payrent_business/screens/landlord/payments/payment_detail_page.dart';
import 'package:payrent_business/screens/landlord/payments/payment_schedule_page.dart';
import 'package:payrent_business/screens/landlord/payments/payment_summary_page.dart';

import 'package:payrent_business/screens/landlord/tenant_management/tenant_list_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/tenant_detail_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/add_tenant_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/edit_tenant_page.dart';

import 'package:payrent_business/screens/landlord/mandate/mandate_list_page.dart';
import 'package:payrent_business/screens/landlord/mandate/mandate_viewer_page.dart';
import 'package:payrent_business/screens/landlord/mandate/create_mandate_page.dart';
import 'package:payrent_business/screens/landlord/mandate/new_create_mandate_page.dart';
import 'package:payrent_business/screens/landlord/mandate/mandate_status_page.dart';
import 'package:payrent_business/screens/landlord/mandate/mandate_collection_page.dart';

import 'package:payrent_business/screens/landlord/earnings/earning_details_page.dart';

// Tenant screens
import 'package:payrent_business/screens/tenant/tenant_dashboard_page.dart';
import 'package:payrent_business/screens/tenant/tenant_properties_page.dart';
import 'package:payrent_business/screens/tenant/tenant_property_detail_page.dart';
import 'package:payrent_business/screens/tenant/tenant_payments_page.dart';
import 'package:payrent_business/screens/tenant/tenant_maintenance_page.dart';
import 'package:payrent_business/screens/tenant/maintenance_request/maintenance_request_page.dart';
import 'package:payrent_business/screens/tenant/tenant_profile_page.dart';

// Profile screens
import 'package:payrent_business/screens/profile/user_profile_page.dart';

// Web-specific wrapper
import 'package:payrent_business/screens/web/web_main_page.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    // Splash/Auth Routes
    GetPage(
      name: AppRoutes.splash,
      page: () => FirebaseInitializer.initializeApp(
        child: const SplashPage(),
      ),
    ),
    GetPage(
      name: AppRoutes.intro,
      page: () => const IntroPage(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
    ),
    // GetPage(
    //   name: AppRoutes.otp,
    //   page: () => const OtpPage(),
    // ),
    // GetPage(
    //   name: AppRoutes.signup,
    //   page: () => const ProfileSignupPage(),
    // ),
    // GetPage(
    //   name: AppRoutes.signupSuccess,
    //   page: () => SignupSuccessfulPage(),
    // ),
    // GetPage(
    //   name: AppRoutes.verificationComplete,
    //   page: () => const VerificationCompletePage(),
    // ),

    // Landlord Routes with Web Wrapper
    GetPage(
      name: AppRoutes.landlord,
      page: () => const WebMainPage(userType: 'Landlord'),
    ),
    GetPage(
      name: AppRoutes.landlordDashboard,
      page: () => const WebMainPage(userType: 'Landlord', initialRoute: 'dashboard'),
    ),
    
    // Properties
    GetPage(
      name: AppRoutes.landlordProperties,
      page: () => const WebMainPage(userType: 'Landlord', initialRoute: 'properties'),
    ),
    // GetPage(
    //   name: AppRoutes.landlordPropertyDetail,
    //   page: () => PropertyDetailPage(
    //     propertyId: Get.parameters['propertyId'] ?? '',
    //   ),
    // ),
    GetPage(
      name: AppRoutes.landlordAddProperty,
      page: () => const AddPropertyPage(),
    ),
    // GetPage(
    //   name: AppRoutes.landlordEditProperty,
    //   page: () => EditPropertyPage(
    //     propertyId: Get.parameters['propertyId'] ?? '',
    //   ),
    // ),
    // GetPage(
    //   name: AppRoutes.landlordUnitDetail,
    //   page: () => UnitDetailsPage(
    //     propertyId: Get.parameters['propertyId'] ?? '',
    //     unitId: Get.parameters['unitId'] ?? '',
    //   ),
    // ),
    GetPage(
      name: AppRoutes.landlordBulkUpload,
      page: () => const BulkUploadPage(),
    ),
    // GetPage(
    //   name: AppRoutes.landlordTemplateViewer,
    //   page: () => const TemplateViewerPage(),
    // ),

    // Payments
    GetPage(
      name: AppRoutes.landlordPayments,
      page: () => const WebMainPage(userType: 'Landlord', initialRoute: 'payments'),
    ),
    GetPage(
      name: AppRoutes.landlordPaymentDetail,
      page: () => PaymentDetailPage(
        paymentId: Get.parameters['paymentId'] ?? '',
      ),
    ),
    GetPage(
      name: AppRoutes.landlordPaymentSchedule,
      page: () => const PaymentSchedulePage(),
    ),
    GetPage(
      name: AppRoutes.landlordPaymentSummary,
      page: () => const PaymentSummaryPage(),
    ),

    // Tenants
    GetPage(
      name: AppRoutes.landlordTenants,
      page: () => const WebMainPage(userType: 'Landlord', initialRoute: 'tenants'),
    ),
    GetPage(
      name: AppRoutes.landlordTenantDetail,
      page: () => TenantDetailPage(
        tenantId: Get.parameters['tenantId'] ?? '',
      ),
    ),
    GetPage(
      name: AppRoutes.landlordAddTenant,
      page: () => const AddTenantPage(),
    ),
    GetPage(
      name: AppRoutes.landlordEditTenant,
      page: () => EditTenantPage(
        tenantId: Get.parameters['tenantId'] ?? '',
      ),
    ),

    // Mandates
    GetPage(
      name: AppRoutes.landlordMandates,
      page: () =>  MandateListPage(),
    ),
    // GetPage(
    //   name: AppRoutes.landlordMandateDetail,
    //   page: () => MandateViewerPage(
    //     mandateId: Get.parameters['mandateId'] ?? '',
    //   ),
    // ),
    // GetPage(
    //   name: AppRoutes.landlordCreateMandate,
    //   page: () => const NewCreateMandatePage(),
    // ),
    GetPage(
      name: AppRoutes.landlordMandateStatus,
      page: () => MandateStatusPage(
        mandateId: Get.parameters['mandateId'] ?? '',
      ),
    ),
    // GetPage(
    //   name: AppRoutes.landlordMandateCollection,
    //   page: () => MandateCollectionPage(
    //     mandateId: Get.parameters['mandateId'] ?? '',
    //   ),
    // ),

    // Earnings
    // GetPage(
    //   name: AppRoutes.landlordEarnings,
    //   page: () => const EarningDetailsPage(),
    // ),

    // Tenant Routes with Web Wrapper
    GetPage(
      name: AppRoutes.tenant,
      page: () => const WebMainPage(userType: 'Tenant'),
    ),
    GetPage(
      name: AppRoutes.tenantDashboard,
      page: () => const WebMainPage(userType: 'Tenant', initialRoute: 'dashboard'),
    ),
    GetPage(
      name: AppRoutes.tenantProperties,
      page: () => const WebMainPage(userType: 'Tenant', initialRoute: 'properties'),
    ),
    // GetPage(
    //   name: AppRoutes.tenantPropertyDetail,
    //   page: () => TenantPropertyDetailPage(
    //     propertyId: Get.parameters['propertyId'] ?? '',
    //   ),
    // ),
    GetPage(
      name: AppRoutes.tenantPayments,
      page: () => const WebMainPage(userType: 'Tenant', initialRoute: 'payments'),
    ),
    GetPage(
      name: AppRoutes.tenantMaintenance,
      page: () => const WebMainPage(userType: 'Tenant', initialRoute: 'maintenance'),
    ),
    GetPage(
      name: AppRoutes.tenantMaintenanceRequest,
      page: () => const MaintenanceRequestPage(),
    ),

    // Profile Routes
    GetPage(
      name: AppRoutes.landlordProfile,
      page: () => const WebMainPage(userType: 'Landlord', initialRoute: 'profile'),
    ),
    GetPage(
      name: AppRoutes.tenantProfile,
      page: () => const WebMainPage(userType: 'Tenant', initialRoute: 'profile'),
    ),
  ];
}