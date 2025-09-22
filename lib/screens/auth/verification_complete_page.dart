import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:payrent_business/screens/auth/profile_signup_page.dart';

class VerificationCompletePage extends StatefulWidget {
  final bool islogin;
  final String mobileNumber;
  const VerificationCompletePage(
      {super.key, required this.islogin, required this.mobileNumber});

  @override
  State<VerificationCompletePage> createState() =>
      _VerificationCompletePageState();
}

class _VerificationCompletePageState extends State<VerificationCompletePage> {
  @override
  void initState() {
    super.initState();
    print('VerificationCompletePage initState called');
    Timer(const Duration(seconds: 2), () async {
      Get.to(ProfileSignupPage(isPhoneRequired: widget.mobileNumber.isNotEmpty));
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
                          widget.islogin
                              ? 'Login successful'
                              : 'Verification Completed.',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SFProDisplay',
                              color: Color(0xff159F00)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 70),
                    AnimatedManWithCircle(key: ValueKey(widget.islogin),
                        image: widget.islogin
                            ? 'assets/animation2.png'
                            : 'assets/animation.png')
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

class ConicGradientCircle extends StatelessWidget {
  const ConicGradientCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(160, 160),
      painter: _ConicPainter(),
    );
  }
}

class _ConicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const gradient = SweepGradient(
      startAngle: 138.49 * (3.1416 / 180), // Convert to radians
      colors: [
        Color(0xFF5BBEDD),
        Color(0xFFDB7BD1),
        Color(0xFF9346EE),
        Color(0xFF5498D7),
        Color(0xFF5BBEDD),
        // Color(0xFFDB7BD1),
      ],
      stops: [0.0, 0.15, 0.45, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2; // Padding from edge

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class EclipsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: 2.416, // ~138.49 degrees
        center: Alignment.center,
        colors: [
          const Color(0xFF5BBEDD).withValues(alpha: 0.3),
          const Color(0xFFDB7BD1).withValues(alpha: 0.3),
          const Color(0xFF9346EE).withValues(alpha: 0.3),
          const Color(0xFF5498D7).withValues(alpha: 0.3),
          const Color(0xFF5BBEDD).withValues(alpha: 0.3),
          const Color(0xFFDB7BD1).withValues(alpha: 0.3),
        ],
        stops: const [0.0, 0.15, 0.45, 0.7, 0.95, 1.2],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ignore: must_be_immutable
class AnimatedManWithCircle extends StatefulWidget {
  String image;
  AnimatedManWithCircle({super.key, required this.image});

  @override
  State<AnimatedManWithCircle> createState() => _AnimatedManWithCircleState();
}

class _AnimatedManWithCircleState extends State<AnimatedManWithCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward(); // start animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Static Conic Gradient Circle
          const ConicGradientCircle(),

          // Animated Man Image
          ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Image.asset(
                widget.image, // Replace with your actual image path
                width: 170,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
