import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:payrent_business/controllers/phone_auth_controller.dart';
import 'package:payrent_business/controllers/tenant_data_controller.dart';
import 'package:payrent_business/screens/auth/otp_page.dart';
import 'package:payrent_business/services/tenant_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Controllers
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  PhoneAuthController phoneAuthController = Get.put(PhoneAuthController());
  // Animation controllers for ripple effect on button
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  
  // Controllers for form fields
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _loginPhoneController = TextEditingController();
  
  // Focus nodes for form fields
  final FocusNode _loginPhoneFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  
  // Services
  final TenantAuthService _tenantAuthService = TenantAuthService();
  
  // State variables
  String selectedCountry = 'India';
  String selectedCountryCode = '91';
  String selectedCountryFlag = '🇮🇳';
  bool isSignupMobileFilled = false;
  bool isLoginMobileFilled = false;
  bool isLoading = false;
  
  // Animation variables
  bool _isGoogleHovered = false;
  bool _isNextButtonHovered = false;
  // bool _isLoginButtonHovered = false;
  
  // List of existing numbers (for validation)
  final List<String> existingNumbers = [
    "9999999999",
    "8888888888",
    "7777777777",
    "6666666666",
    "5555555555"
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    
    // Setup fade animation for tab transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );
    
    // Initialize button animation controller for ripple effect
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _fadeController.forward();

    // Listen for tab changes to reset and play animations
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fadeController.reset();
        _resetFocus();
      } else {
        _fadeController.forward();
      }
    });

    // Add listeners for form fields
    _mobileController.addListener(() {
      setState(() {
        isSignupMobileFilled = _mobileController.text.length == 10;
      });
    });
    
    _loginPhoneController.addListener(() {
      setState(() {
        isLoginMobileFilled = _loginPhoneController.text.length == 10;
      });
    });

    // Add focus listeners to update UI
    _loginPhoneFocusNode.addListener(() => setState(() {}));
    _mobileFocusNode.addListener(() => setState(() {}));
  }

  void _resetFocus() {
    _loginPhoneFocusNode.unfocus();
    _mobileFocusNode.unfocus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _buttonAnimationController.dispose();
    
    _mobileController.dispose();
    _loginPhoneController.dispose();
    
    _loginPhoneFocusNode.dispose();
    _mobileFocusNode.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    
    return GestureDetector(
      // Tap anywhere on the screen to dismiss keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                const Color(0xFFECE6F0).withOpacity(0.5),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Logo and title with animation
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Padding(
                    padding: EdgeInsets.only(top: screenSize.height * 0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with animated container
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 1.0, end: 1.1),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFECE6F0), Color(0xFFD2EEF5)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7869E6).withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              "assets/logo.png",
                              height: 32,
                              width: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Animated text with gradient
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF4F287D), Color(0xFF7869E6)],
                          ).createShader(bounds),
                          child: TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.8, end: 1.0),
                            duration: const Duration(seconds: 2),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Text(
                              'PayRent',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Subtitle with typing animation
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 800),
                  child: DefaultTextStyle(
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF6B737A),
                      fontWeight: FontWeight.w400,
                    ),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'Manage your rentals with ease',
                          speed: const Duration(milliseconds: 100),
                        ),
                      ],
                      isRepeatingAnimation: false,
                      totalRepeatCount: 1,
                    ),
                  ),
                ),
                
                SizedBox(height: screenSize.height * 0.05),
                
                // TabBar with enhanced styling and ripple effect
                FadeInDown(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 800),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xffEDEEEF),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          splashFactory: InkRipple.splashFactory,
                          highlightColor: Colors.transparent,
                        ),
                        child: TabBar(
                          indicatorWeight: 0,
                          controller: _tabController,
                          dividerColor: Colors.transparent,
                          padding: const EdgeInsets.all(4),
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7869E6), Color(0xFF4F287D)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7869E6).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xff898989),
                          overlayColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.hovered) ||
                                  states.contains(MaterialState.focused) ||
                                  states.contains(MaterialState.pressed)) {
                                return Colors.white.withOpacity(0.1);
                              }
                              return null;
                            },
                          ),
                          onTap: (int index) {
                            setState(() {
                              _mobileController.text = '';
                              _loginPhoneController.text = '';
                              isSignupMobileFilled = false;
                              isLoginMobileFilled = false;
                            });
                            
                            // Add a haptic feedback for tab change
                            HapticFeedback.mediumImpact();
                          },
                          tabs: const [
                            Tab(text: "Log in"),
                            Tab(text: "Sign up"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // TabBarView with enhanced animations
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Log in Tab
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _fadeController,
                            curve: Curves.easeOutCubic,
                          )),
                          child: _buildLoginTab(context, screenSize),
                        ),
                      ),
                      // Sign up Tab
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-0.05, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _fadeController,
                            curve: Curves.easeOutCubic,
                          )),
                          child: _buildSignupTab(context, screenSize),
                        ),
                      ),
                    ],
                  ),
                ),

                // Terms Section with enhanced typography and animations
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: _buildTermsSection(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(BuildContext context, Size screenSize) {
    return SingleChildScrollView( physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenSize.height * 0.02),
          FadeInLeft(
            delay: const Duration(milliseconds: 100),
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                'Welcome back!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
          ),
          FadeInLeft(
            delay: const Duration(milliseconds: 150),
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 20),
              child: Text(
                'Login to continue',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF6B737A),
                ),
              ),
            ),
          ),
          SizedBox(height: screenSize.height * 0.01),
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: _buildCountrySelector(isLogin: true),
          ),
          SizedBox(height: screenSize.height * 0.025),
          _buildAnimatedFormField(
            controller: _loginPhoneController,
            focusNode: _loginPhoneFocusNode,
            label: 'Mobile Number',
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
            prefixText: "+$selectedCountryCode ",
            inputFormatters: [LengthLimitingTextInputFormatter(10)],
            delay: 300,
            showSuccessIcon: isLoginMobileFilled,
          ),
          SizedBox(height: screenSize.height * 0.04),
          _buildAnimatedButton(
            text: 'Next',
            isEnabled: isLoginMobileFilled,
            isLoading: isLoading,
            onPressed: () => _simulateLogin(),
            delay: 400,
          ),
          SizedBox(height: screenSize.height * 0.025),
          // _buildOrDivider(delay: 450),
          // SizedBox(height: screenSize.height * 0.025),
          // _buildSocialLoginButtons(context, isLogin: true, delay: 500),
        ],
      ),
    );
  }

  // Updated signup function
Future<void> _simulateOtpSend() async {
  final phoneNumber = _mobileController.text.trim();
  
  if (phoneNumber.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter a valid phone number')),
    );
    return;
  }
  
  setState(() {
    isLoading = true;
  });
  
  try {
    // ✅ Check if number already exists in Firestore
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phoneNumber)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      setState(() => isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This number is already registered. Please login instead.',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }
    
    // ✅ Send OTP using Firebase and WAIT for the result
    final bool success = await phoneAuthController.sendVerificationCode("+$selectedCountryCode$phoneNumber");
    
    setState(() => isLoading = false);
    
    if (success && phoneAuthController.isCodeSent.value) {
      phoneAuthController.countryCode.value = selectedCountryCode;
      phoneAuthController.mobileNumber.value = phoneNumber;
      // Only navigate if code was successfully sent
      Get.to(OtpVerificationPage(
        islogin: false,
        mobileNumber: phoneNumber,
      ));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'OTP sent successfully!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF34D399),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Show error message if OTP sending failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                phoneAuthController.errorMessage.value.isNotEmpty 
                    ? phoneAuthController.errorMessage.value 
                    : 'Failed to send OTP. Please try again.',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
    
  } catch (e) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sending OTP: $e')),
    );
  }
}

// Updated login function with tenant authentication
Future<void> _simulateLogin() async {
  final phoneNumber = _loginPhoneController.text.trim();
  
  if (phoneNumber.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter a valid phone number')),
    );
    return;
  }
  
  setState(() {
    isLoading = true;
  });
  
  try {
    // 🔍 FIRST: Check if number exists as a tenant
    final tenantInfo = await _tenantAuthService.checkTenantByPhoneNumber(phoneNumber);
    
    if (tenantInfo != null) {
      // ✅ Phone number found in tenant records - proceed with tenant flow
      print('Tenant found: ${tenantInfo['tenantId']}');
      
      // Send OTP for tenant authentication
      final bool success = await phoneAuthController.sendVerificationCode("+$selectedCountryCode$phoneNumber");
      
      setState(() => isLoading = false);
      
      if (success && phoneAuthController.isCodeSent.value) {
        phoneAuthController.countryCode.value = selectedCountryCode;
        phoneAuthController.mobileNumber.value = phoneNumber;
        
        // Navigate to OTP page with tenant info
        Get.to(OtpVerificationPage(
          islogin: true,
          mobileNumber: phoneNumber,
          tenantInfo: tenantInfo, // Pass tenant info for after OTP verification
        ));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'OTP sent successfully!',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF34D399),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  phoneAuthController.errorMessage.value.isNotEmpty 
                      ? phoneAuthController.errorMessage.value 
                      : 'Failed to send OTP. Please try again.',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
      return;
    }
    
    // 🔍 SECOND: Check if number exists as a landlord
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phoneNumber)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      // ✅ Phone number found in landlord records - proceed with landlord flow
      final bool success = await phoneAuthController.sendVerificationCode("+$selectedCountryCode$phoneNumber");
      
      setState(() => isLoading = false);
      
      if (success && phoneAuthController.isCodeSent.value) {
        phoneAuthController.countryCode.value = selectedCountryCode;
        phoneAuthController.mobileNumber.value = phoneNumber;
        
        Get.to(OtpVerificationPage(
          islogin: true,
          mobileNumber: phoneNumber,
        ));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'OTP sent successfully!',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF34D399),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  phoneAuthController.errorMessage.value.isNotEmpty 
                      ? phoneAuthController.errorMessage.value 
                      : 'Failed to send OTP. Please try again.',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
      return;
    }
    
    // ❌ Phone number not found anywhere
    setState(() => isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'You don\'t have access. Please ask your landlord to add your details or sign up as a landlord.',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 4),
      ),
    );
    
  } catch (e) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'Error checking access: $e',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
}

  Widget _buildSignupTab(BuildContext context, Size screenSize) {
    return SingleChildScrollView( physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenSize.height * 0.02),
          FadeInLeft(
            delay: const Duration(milliseconds: 100),
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                'Create Account',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
          ),
          FadeInLeft(
            delay: const Duration(milliseconds: 150),
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 20),
              child: Text(
                'Enter your details to get started',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF6B737A),
                ),
              ),
            ),
          ),
          SizedBox(height: screenSize.height * 0.01),
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: _buildCountrySelector(isLogin: false),
          ),
          SizedBox(height: screenSize.height * 0.025),
          _buildAnimatedFormField(
            controller: _mobileController,
            focusNode: _mobileFocusNode,
            label: 'Mobile Number',
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
            prefixText: "+$selectedCountryCode ",
            inputFormatters: [LengthLimitingTextInputFormatter(10)],
            delay: 300,
            showSuccessIcon: isSignupMobileFilled,
          ),
          SizedBox(height: screenSize.height * 0.04),
          _buildAnimatedButton(
            text: 'Next',
            isEnabled: isSignupMobileFilled,
            isLoading: isLoading,
            onPressed: () => _simulateOtpSend(),
            delay: 400,
          ),
          SizedBox(height: screenSize.height * 0.025),
          // _buildOrDivider(delay: 450),
          // SizedBox(height: screenSize.height * 0.025),
          // _buildSocialLoginButtons(context, isLogin: false, delay: 500),
        ],
      ),
    );
  }
  
  Widget _buildCountrySelector({required bool isLogin}) {
    return Hero(
      tag: isLogin ? 'login_country_selector' : 'signup_country_selector',
      child: Material(
        color: Colors.transparent,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              showCountryPicker(
                context: context,
                showPhoneCode: false,
                countryFilter: ['IN', 'OM', 'AE', 'SA'],
                onSelect: (Country country) {
                  setState(() {
                    selectedCountry = country.name;
                    selectedCountryCode = country.phoneCode;
                    selectedCountryFlag = country.flagEmoji;
                  });
                  
                  // Add a haptic feedback
                  HapticFeedback.lightImpact();
                },
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    splashColor: const Color(0xFFECE6F0).withOpacity(0.3),
                    highlightColor: const Color(0xFFECE6F0).withOpacity(0.15),
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        showPhoneCode: false,
                        countryFilter: ['IN', 'OM', 'AE', 'SA'],
                        onSelect: (Country country) {
                          setState(() {
                            selectedCountry = country.name;
                            selectedCountryCode = country.phoneCode;
                            selectedCountryFlag = country.flagEmoji;
                          });
                          
                          // Add a haptic feedback
                          HapticFeedback.lightImpact();
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Country',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xff6B737A),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    selectedCountryFlag,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedCountry,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16, 
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded, 
                              color: Color(0xFF4F287D),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    // bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
    required int delay,
    bool showSuccessIcon = false,
  }) {
    bool isFocused = focusNode.hasFocus;
    
    return FadeInDown(
      delay: Duration(milliseconds: delay),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        transform: Matrix4.translationValues(0, isFocused ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isFocused 
                ? const Color(0xFF4F287D).withOpacity(0.15)
                : Colors.black.withOpacity(0.03),
              blurRadius: isFocused ? 12 : 8,
              offset: const Offset(0, 2),
              spreadRadius: isFocused ? 1 : 0,
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black87,
          ),
          cursorColor: const Color(0xFF4F287D),
          cursorWidth: 1.5,
          cursorRadius: const Radius.circular(4),
          onTap: () {
            // Add a small haptic feedback
            HapticFeedback.selectionClick();
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F287D), width: 1.5),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: label,
            labelStyle: GoogleFonts.poppins(
              color: isFocused ? const Color(0xFF4F287D) : const Color(0xff6B737A),
              fontWeight: FontWeight.w500,
            ),
            prefixText: prefixText,
            prefixIcon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                icon,
                color: isFocused ? const Color(0xFF4F287D) : const Color(0xFF6B737A),
                size: 22,
              ),
            ),
            suffixIcon: showSuccessIcon
                ? TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF34D399), // Success green color
                          size: 22,
                        ),
                      );
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            if (controller == _mobileController) {
              setState(() {
                isSignupMobileFilled = value.length == 10;
              });
            } else if (controller == _loginPhoneController) {
              setState(() {
                isLoginMobileFilled = value.length == 10;
              });
            }
          },
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'This field is required';
            }
            if ((controller == _mobileController || controller == _loginPhoneController) && val.length != 10) {
              return 'Please enter a valid 10-digit mobile number';
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required String text,
    required bool isEnabled,
    required VoidCallback onPressed,
    bool isLoading = false,
    required int delay,
  }) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _isNextButtonHovered = true),
        onExit: (_) => setState(() => _isNextButtonHovered = false),
        child: GestureDetector(
          onTapDown: isEnabled && !isLoading ? (_) => _buttonAnimationController.forward() : null,
          onTapUp: isEnabled && !isLoading ? (_) => _buttonAnimationController.reverse() : null,
          onTapCancel: isEnabled && !isLoading ? () => _buttonAnimationController.reverse() : null,
          child: ScaleTransition(
            scale: _buttonScaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: isEnabled
                    ? [
                        _isNextButtonHovered ? const Color(0xFF8A7DEF) : const Color(0xFF7869E6),
                        _isNextButtonHovered ? const Color(0xFF5F3595) : const Color(0xFF4F287D),
                      ]
                    : [const Color(0xFFBBB5D6), const Color(0xFF9E8FB3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4F287D).withOpacity(_isNextButtonHovered ? 0.4 : 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      )
                    ]
                  : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled && !isLoading ? () {
                    onPressed();
                    // Add a haptic feedback for button press
                    HapticFeedback.mediumImpact();
                  } : null,
                  borderRadius: BorderRadius.circular(28),
                  splashColor: Colors.white.withOpacity(0.1),
                  child: Center(
                    child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              text,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isEnabled) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider({required int delay}) {
    return FadeIn(
      delay: Duration(milliseconds: delay),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Divider(
              thickness: 1,
              color: Color(0x40000000),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              "or",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B737A),
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              thickness: 1,
              color: Color(0x40000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginButtons(BuildContext context, {required bool isLogin, required int delay}) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isGoogleHovered = true),
        onExit: (_) => setState(() => _isGoogleHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(
            0, _isGoogleHovered ? -2 : 0, 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isGoogleHovered ? 0.12 : 0.08),
                offset: const Offset(0, 4),
                blurRadius: _isGoogleHovered ? 16 : 12,
                spreadRadius: _isGoogleHovered ? 1 : 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Add haptic feedback for button press
                HapticFeedback.mediumImpact();
              },
              borderRadius: BorderRadius.circular(28),
              splashColor: Colors.grey.withOpacity(0.1),
              highlightColor: Colors.grey.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(_isGoogleHovered ? 0.1 : 0.05),
                            blurRadius: _isGoogleHovered ? 10 : 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/google.png', height: 18, width: 18),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      "Continue with Google",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: "By creating an account or signing up you ",
            style: GoogleFonts.poppins(
              color: const Color(0xff757575),
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          TextSpan(
            text: "agree to our ",
            style: GoogleFonts.poppins(
              color: const Color(0xff757575),
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () {
                // Add a haptic feedback for link press
                HapticFeedback.selectionClick();
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Text(
                        "Terms and Conditions",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF4F287D),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.5,
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF4F287D),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      maxLines: 2,
    );
  }
}
