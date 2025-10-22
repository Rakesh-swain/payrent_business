class AppRoutes {
  // Auth routes
  static const splash = '/';
  static const intro = '/intro';
  static const login = '/login';
  static const otp = '/otp';
  static const signup = '/signup';
  static const signupSuccess = '/signup-success';
  static const verificationComplete = '/verification-complete';
  
  // Landlord routes
  static const landlord = '/landlord';
  static const landlordDashboard = '/landlord/dashboard';
  static const landlordProperties = '/landlord/properties';
  static const landlordPropertyDetail = '/landlord/properties/:propertyId';
  static const landlordAddProperty = '/landlord/properties/add';
  static const landlordEditProperty = '/landlord/properties/:propertyId/edit';
  static const landlordUnitDetail = '/landlord/properties/:propertyId/units/:unitId';
  static const landlordBulkUpload = '/landlord/properties/bulk-upload';
  static const landlordTemplateViewer = '/landlord/properties/template-viewer';
  
  static const landlordPayments = '/landlord/payments';
  static const landlordPaymentDetail = '/landlord/payments/:paymentId';
  static const landlordPaymentSchedule = '/landlord/payments/schedule';
  static const landlordPaymentSummary = '/landlord/payments/summary';
  
  static const landlordTenants = '/landlord/tenants';
  static const landlordTenantDetail = '/landlord/tenants/:tenantId';
  static const landlordAddTenant = '/landlord/tenants/add';
  static const landlordEditTenant = '/landlord/tenants/:tenantId/edit';
  
  static const landlordMandates = '/landlord/mandates';
  static const landlordMandateDetail = '/landlord/mandates/:mandateId';
  static const landlordCreateMandate = '/landlord/mandates/create';
  static const landlordMandateStatus = '/landlord/mandates/:mandateId/status';
  static const landlordMandateCollection = '/landlord/mandates/:mandateId/collection';
  
  static const landlordEarnings = '/landlord/earnings';
  static const landlordEarningDetails = '/landlord/earnings/details';
  
  // Tenant routes
  static const tenant = '/tenant';
  static const tenantDashboard = '/tenant/dashboard';
  static const tenantProperties = '/tenant/properties';
  static const tenantPropertyDetail = '/tenant/properties/:propertyId';
  static const tenantPayments = '/tenant/payments';
  static const tenantMaintenance = '/tenant/maintenance';
  static const tenantMaintenanceRequest = '/tenant/maintenance/request';
  
  // Profile routes (shared)
  static const profile = '/profile';
  static const landlordProfile = '/landlord/profile';
  static const tenantProfile = '/tenant/profile';
  
  // Helper methods
  static String getRouteWithParams(String route, Map<String, String> params) {
    String finalRoute = route;
    params.forEach((key, value) {
      finalRoute = finalRoute.replaceAll(':$key', value);
    });
    return finalRoute;
  }
  
  static bool isLandlordRoute(String route) {
    return route.startsWith('/landlord');
  }
  
  static bool isTenantRoute(String route) {
    return route.startsWith('/tenant');
  }
  
  static bool isAuthRoute(String route) {
    const authRoutes = [splash, intro, login, otp, signup, signupSuccess, verificationComplete];
    return authRoutes.contains(route);
  }
}