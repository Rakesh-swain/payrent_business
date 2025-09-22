import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:payrent_business/screens/auth/verification_complete_page.dart';
import 'package:payrent_business/screens/landlord/landlord_main_page.dart';
import 'package:payrent_business/screens/tenant/tenant_main_page.dart';

// ignore: must_be_immutable
class SignupSuccessfulPage extends StatefulWidget {
  bool accountType;
 SignupSuccessfulPage(
      {super.key, required this.accountType});

  @override
  State<SignupSuccessfulPage> createState() =>
      _SignupSuccessfulPageState(); 
}

class _SignupSuccessfulPageState extends State<SignupSuccessfulPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () async {
      if (widget.accountType) {
        Get.offAll(LandlordMainPage());
      } else {
        Get.offAll(TenantMainPage());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0Xff0F7200), size: 25),
                        const SizedBox(height: 10),
                        Text(
                        'Account Created Successfully',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SFProDisplay',
                              color: Color(0xff159F00)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 70),
                    AnimatedManWithCircle(image: 'assets/animation2.png',
                        )
                  ],
                ),
              ),
              Stack(
                children: [
                  // 🌗 Eclipse Gradient at Bottom
                  Positioned(
                    bottom: -160,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: EclipsePainter(),
                      ),
                    ),
                  ),

                  // 🖼️ First (bottom-most) image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/layer1.png',
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // 🖼️ Second image on top
                  Positioned(
                    bottom: 90,
                    left: 0,
                    right: 30,
                    child: Image.asset(
                      'assets/layer2.png',
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // 🖼️ Third (top-most) image
                  Positioned(
                    bottom: 80,
                    left: 10,
                    right: 0,
                    child: Image.asset(
                      'assets/layer3.png',
                      height: 130,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}