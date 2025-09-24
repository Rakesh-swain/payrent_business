import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:payrent_business/controllers/user_profile_controller.dart';
import 'package:payrent_business/screens/landlord/landlord_main_page.dart';
import 'package:payrent_business/screens/tenant/tenant_main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/controller_bindings.dart';
import 'services/firebase_initializer.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';
import 'package:payrent_business/screens/auth/intro_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PayRent Business',
      theme: ThemeData(
        primaryColor: const Color(0xFF2D5FFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5FFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      initialBinding: ControllerBindings(),
      onInit: (){
        Get.put(UserProfileController());
      },
      home: FirebaseInitializer.initializeApp(
        child: const SplashPage(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}



class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  bool _isScaled = false;
  bool _showBackground = false;
  bool _showTagline = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.repeat(reverse: true);

    // Sequenced animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _showBackground = true;
      });
      
      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() {
          _isScaled = true;
        });
      });
      
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _showTagline = true;
        });
      });
    });

    // Navigate after delay
    _navigateAfterDelay();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

   Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
       final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('userType');


          if (userType == 'Landlord') {
            Get.offAll(() => const LandlordMainPage(),
                transition: Transition.fadeIn, duration: const Duration(milliseconds: 800));
          } else if (userType == 'Tenant') {
            Get.offAll(() => const TenantMainPage(),
                transition: Transition.fadeIn, duration: const Duration(milliseconds: 800));
          } else {
            // fallback to intro if unknown usertype
            Get.offAll(() => const IntroPage(),
                transition: Transition.fadeIn, duration: const Duration(milliseconds: 800));
          }
        
      } catch (e) {
        // in case of error go to intro
        Get.offAll(() => const IntroPage(),
            transition: Transition.fadeIn, duration: const Duration(milliseconds: 800));
      }
    } else {
      // No logged in user, go to intro
      Get.offAll(() => const IntroPage(),
          transition: Transition.fadeIn, duration: const Duration(milliseconds: 800));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF7869E6),
              const Color(0xFF4F287D),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background patterns
            AnimatedOpacity(
              opacity: _showBackground ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 1200),
              child: _buildBackgroundElements(),
            ),
            
            // Center logo with animation
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with scale animation
                  AnimatedScale(
                    scale: _isScaled ? 1.0 : 0.2,
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.elasticOut,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  "assets/logo.png",
                                  height: 48,
                                  width: 41,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'PayRent',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Roboto',
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 1,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Tagline with fade-in animation
                  AnimatedOpacity(
                    opacity: _showTagline ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 800),
                    child: FadeIn(
                      duration: const Duration(milliseconds: 800),
                      child: const Text(
                        "Your Rent Payment, Simplified",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom attribution or version
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showTagline ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: const Text(
                  "v1.0.0",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // Animated particles/dots
        ..._buildParticles(20),
        
        // Top-right decorative element
        Positioned(
          top: -60,
          right: -60,
          child: FadeInDown(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 1000),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
        ),
        // Bottom-left decorative element
        Positioned(
          bottom: -80,
          left: -80,
          child: FadeInUp(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 1000),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
        ),
        
        // Small accents
        Positioned(
          top: 100,
          left: 30,
          child: _buildAccentCircle(30, 300),
        ),
        
        Positioned(
          bottom: 150,
          right: 40,
          child: _buildAccentCircle(20, 500),
        ),
        
        // Light ray effect at the center
        Positioned.fill(
          child: Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.1, 0.7],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAccentCircle(double size, int delayMillis) {
    return FadeIn(
      delay: Duration(milliseconds: delayMillis),
      duration: const Duration(milliseconds: 800),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
      ),
    );
  }
  
  List<Widget> _buildParticles(int count) {
    return List.generate(
      count,
      (index) {
        final double size = 3 + (index % 5 * 1.5);
        final double left = (index * 17) % MediaQuery.of(context).size.width;
        final double top = (index * 23) % MediaQuery.of(context).size.height;
        final int delay = 100 + (index * 50);
        
        return Positioned(
          left: left,
          top: top,
          child: FadeIn(
            delay: Duration(milliseconds: delay),
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.4 + ((index % 6) / 10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 5,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}