import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:payrent_business/controllers/user_profile_controller.dart';
import 'package:payrent_business/screens/landlord/landlord_main_page.dart';
import 'package:payrent_business/screens/tenant/tenant_main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'controllers/controller_bindings.dart';
import 'services/firebase_initializer.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';
import 'package:payrent_business/screens/auth/intro_page.dart';
import 'package:payrent_business/routes/app_routes.dart';
import 'package:payrent_business/routes/app_pages.dart';
import 'package:payrent_business/screens/web/web_main_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PayRent - Desktop & Web',
      theme: ThemeData(
        primaryColor: const Color(0xFF2D5FFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5FFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      // Responsive wrapper for better web/desktop support
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1400, name: DESKTOP),
            const Breakpoint(start: 1401, end: double.infinity, name: '4K'),
          ],
        );
      },
      // Use new routing system
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      initialBinding: ControllerBindings(),
      onInit: (){
        Get.put(UserProfileController());
      },
      debugShowCheckedModeBanner: false,
    );
  }
}



