import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:payrent_business/controllers/phone_auth_controller.dart';
import 'package:payrent_business/screens/auth/verification_complete_page.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class OtpVerificationPage extends StatefulWidget {
  final bool islogin;
  final String mobileNumber;

  const OtpVerificationPage({
    super.key,
    required this.islogin,
    required this.mobileNumber,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> with CodeAutoFill {
  final TextEditingController _otpController = TextEditingController();
  bool isOtpComplete = false;
  
  // Resend timer
  Timer? _timer;
  int _resendSeconds = 30;
  bool _canResendOTP = false;
  
  // Get the existing PhoneAuthController instance
  late final PhoneAuthController phoneAuthController;
  
  @override
  void initState() {
    super.initState();
    
    // Get the existing controller instance (don't create new one)
    phoneAuthController = Get.find<PhoneAuthController>();
    
    listenForCode();
    _startResendTimer();
    
    _otpController.addListener(_otpListener);
  }
  
  void _otpListener() {
    setState(() {
      isOtpComplete = _otpController.text.length == 6;
    });
  }
  
  void _startResendTimer() {
    _canResendOTP = false;
    _resendSeconds = 30;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResendOTP = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty) {
      setState(() {
        _otpController.text = code!;
        isOtpComplete = _otpController.text.length == 6;
      });
      
      // Auto-verify when OTP is auto-filled
      if (isOtpComplete) {
        _verifyOtp();
      }
    }
  }

  @override
  void dispose() {
    cancel(); // Cancel SMS autofill listener
    _otpController.removeListener(_otpListener);
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!isOtpComplete) return;
    
    final bool success = await phoneAuthController.verifyOtp(_otpController.text.trim());
    
    if (success) {
      // Navigate on successful verification
      Get.off(() => VerificationCompletePage(
        islogin: widget.islogin,
        mobileNumber: widget.mobileNumber,
      ));
    } else {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  phoneAuthController.errorMessage.value.isNotEmpty
                      ? phoneAuthController.errorMessage.value
                      : 'Invalid OTP. Please try again.',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
      
      // Clear the OTP field on error
      _otpController.clear();
      setState(() {
        isOtpComplete = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    // Use the same country code as used in the previous screen
    // You might need to pass this or get it from a shared preference/controller
    final String fullPhoneNumber = "+91${widget.mobileNumber}"; // Adjust country code as needed
    
    final bool success = await phoneAuthController.sendVerificationCode(fullPhoneNumber);
    
    if (success) {
      _startResendTimer();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'OTP has been resent!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF34D399),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Failed to resend OTP. Please try again.',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
    
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: GoogleFonts.poppins(
        fontSize: 18,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF0F0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4F287D), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F287D).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
    
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFECE6F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      textStyle: GoogleFonts.poppins(
        fontSize: 18,
        color: const Color(0xFF4F287D),
        fontWeight: FontWeight.w600,
      ),
    );

    return Scaffold(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                FadeInLeft(
                  duration: const Duration(milliseconds: 500),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF4F287D),
                        size: 24,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Header
                FadeInDown(
                  duration: const Duration(milliseconds: 700),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OTP Verification',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Please enter the One-Time Password (OTP) that was sent to:',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xff6B737A),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECE6F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.phone_android,
                                    size: 16,
                                    color: Color(0xFF4F287D),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.mobileNumber,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4F287D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                // Edit mobile number functionality
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Color(0xFF6B737A),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // OTP Input
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    children: [
                      Pinput(
                        controller: _otpController,
                        length: 6,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        onCompleted: (pin) {
                          setState(() {
                            isOtpComplete = true;
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            isOtpComplete = value.length == 6;
                          });
                        },
                        pinAnimationType: PinAnimationType.scale,
                        hapticFeedbackType: HapticFeedbackType.lightImpact,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _canResendOTP
                                ? "Didn't receive code? "
                                : "Resend code in ",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xff6B737A),
                            ),
                          ),
                          _canResendOTP
                              ? Obx(() => TextButton(
                                    onPressed: phoneAuthController.isLoading.value 
                                        ? null 
                                        : _resendOtp,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: phoneAuthController.isLoading.value
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF4F287D),
                                            ),
                                          )
                                        : Text(
                                            "Resend OTP",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: const Color(0xFF4F287D),
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                  ))
                              : Text(
                                  "${_resendSeconds}s",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF4F287D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Verify button
                FadeInUp(
                  duration: const Duration(milliseconds: 900),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: isOtpComplete
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4F287D).withOpacity(0.3),
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
                        onTap: (isOtpComplete && !phoneAuthController.isLoading.value)
                            ? _verifyOtp
                            : null,
                        borderRadius: BorderRadius.circular(28),
                        splashColor: Colors.white.withOpacity(0.1),
                        child: Obx(
                          () => Ink(
                            decoration: BoxDecoration(
                              gradient: isOtpComplete
                                  ? const LinearGradient(
                                      colors: [Color(0xFF7869E6), Color(0xFF4F287D)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFFBBB5D6), Color(0xFF9E8FB3)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: phoneAuthController.isLoading.value
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
                                          "Verify & Continue",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (isOtpComplete) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.check_circle_outline_rounded,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}