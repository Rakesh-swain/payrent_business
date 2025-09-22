import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:payrent_business/screens/auth/login_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  bool onLastPage = false;
  Timer? _autoScrollTimer;
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  int _currentPage = 0;

  final List<String> imagePaths = [
    "assets/intro1.png",
    "assets/intro2.png",
    "assets/intro3.png",
  ];

  final List<String> titles = [
    "Renting made easy for tenants and owners",
    "Never Miss a Payment Again with Payrent",
    "Hassle-Free Maintenance Management",
  ];

  final List<String> subtitles = [
    "Payrent simplifies rental management. Get organized and save time with Payrent.",
    "No more late rent payments and missed deadlines. Automate rent collection and easily track payments.",
    "Submit, track, and resolve maintenance requests effortlessly",
  ];

  @override
  void initState() {
    super.initState();
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Initialize animation controllers
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _buttonScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Start animations
    _animationController.forward();
    _buttonAnimationController.forward();
    
    // Configure page controller
    _controller.addListener(() {
      int nextPage = _controller.page!.round();
      if (_currentPage != nextPage) {
        setState(() {
          _currentPage = nextPage;
          onLastPage = _currentPage == 2;
        });
        // Reset and restart animations for the new page
        _animationController.reset();
        _animationController.forward();
      }
    });
    
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 3000), (timer) {
      if (_controller.hasClients && !onLastPage) {
        int nextPage = _controller.page!.round() + 1;
        if (nextPage >= imagePaths.length) {
          nextPage = 0;
        }
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _autoScrollTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    _animationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FadeInDown(
          duration: const Duration(milliseconds: 800),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset("assets/logo.png", height: 36, width: 32),
              const SizedBox(width: 8),
              Text(
                'PayRent',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4F287D),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x174D2779),
                  Colors.white.withOpacity(0.1),
                  Colors.white,
                ],
                stops: const [0.0, 0.5, 0.7],
              ),
            ),
          ),
          
          // Background decorative elements
          ..._buildBackgroundElements(screenWidth),
          
          // Main content
          Column(
            children: [
              // Image + stacked card
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: 3,
                  onPageChanged: (index) {
                    setState(() => onLastPage = index == 2);
                  },
                  itemBuilder: (context, index) {
                    return Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Top image area
                        Padding(
                          padding: const EdgeInsets.only(bottom: 200.0),
                          child: Container(
                            color: Colors.transparent,
                            child: Stack(
                              children: [
                                // Main image content based on page
                                _buildMainImageContent(index, screenHeight, screenWidth),
                                
                                // Additional UI elements based on the page
                                if (index == 1) _buildPage2Elements(),
                                if (index == 2) _buildPage3Elements(),
                              ],
                            ),
                          ),
                        ),

                        // Bottom Card with text content
                        _buildBottomCard(index, screenHeight),
                      ],
                    );
                  },
                ),
              ),
              
              // Page indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: SmoothPageIndicator(
                  controller: _controller,
                  count: 3,
                  effect: WormEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    spacing: 12,
                    dotColor: const Color(0xffD9D9D9),
                    activeDotColor: const Color(0xFF7869E6),
                    strokeWidth: 1.5,
                    paintStyle: PaintingStyle.fill,
                    radius: 20,
                  ),
                ),
              ),
              
              // Get Started button
              Padding(
                padding: const EdgeInsets.only(bottom: 30, left: 24, right: 24, top: 5),
                child: ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(LoginPage());
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF4F287D).withOpacity(0.3),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7869E6), Color(0xFF4F287D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F287D).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Main image content based on page index
  Widget _buildMainImageContent(int index, double screenHeight, double screenWidth) {
    if (index == 2) {
      // Split screen layout for the third page
      return Stack(
        children: [
          // Left side image
          Positioned(
            right: 0,
            top: 50,
            bottom: 0,
            child: FadeIn(
              duration: const Duration(milliseconds: 800),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0),
                  child: Image.asset(
                    'assets/intro4.png',
                    width: screenWidth / 2,
                    height: screenHeight * 0.65,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          
          // Right side image
          Positioned(
            left: 0,
            top: 80,
            bottom: 0,
            child: FadeIn(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 800),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0),
                  child: Image.asset(
                    'assets/intro3.png',
                    width: screenWidth / 2,
                    height: screenHeight * 0.65,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Standard full-width image for pages 1 and 2
      return FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Container(
          margin: const EdgeInsets.only(top: 70),
          child: Image.asset(
            imagePaths[index],
            width: screenWidth,
            height: screenHeight * 0.65,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }
  
  // Additional UI elements specific to page 2
  Widget _buildPage2Elements() {
    return Stack(
      children: [
        // Occupancy card
        Positioned(
          top: 100,
          right: 20,
          child: FadeInRight(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 800),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/occupancy.png',
                  height: 100,
                  width: 75,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
        
        // Rent Received card
        Positioned(
          top: 215,
          right: 20,
          child: FadeInRight(
            delay: const Duration(milliseconds: 500),
            duration: const Duration(milliseconds: 800),
            child: _buildAnimatedNotificationCard('Rent Received', Icons.check_circle, Colors.green),
          ),
        ),
        
        // Income Graph
        Positioned(
          bottom: 95,
          right: 0,
          child: FadeInUp(
            delay: const Duration(milliseconds: 700),
            duration: const Duration(milliseconds: 800),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(-2, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: Image.asset(
                  'assets/graph.png',
                  height: 160,
                  width: 126,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Additional UI elements specific to page 3
  Widget _buildPage3Elements() {
    return Positioned(
      top: 100,
      right: 20,
      child: FadeInDown(
        delay: const Duration(milliseconds: 300),
        duration: const Duration(milliseconds: 800),
        child: _buildAnimatedNotificationCard('Request Assigned', Icons.check_circle, Colors.green),
      ),
    );
  }
  
  // Bottom card with title and subtitle
  Widget _buildBottomCard(int index, double screenHeight) {
    return Positioned(
      left: 0,
      right: 0,
      child: FadeInUp(
        from: 50,
        duration: const Duration(milliseconds: 800),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          height: screenHeight / 3.3,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(60),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, -4),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SlideInLeft(
                from: 50,
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 800),
                child: Text(
                  titles[index],
                  textAlign: TextAlign.start,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF333333),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SlideInRight(
                from: 30,
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 800),
                child: Text(
                  subtitles[index],
                  textAlign: TextAlign.start,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Background decorative elements
  List<Widget> _buildBackgroundElements(double screenWidth) {
    return [
      Positioned(
        top: -50,
        right: -50,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF7869E6).withOpacity(0.1),
          ),
        ),
      ),
      Positioned(
        top: 200,
        left: -80,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF7869E6).withOpacity(0.08),
          ),
        ),
      ),
    ];
  }
  
  // Animated notification card
  Widget _buildAnimatedNotificationCard(String text, IconData icon, Color iconColor) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, const Color(0xFFF8F8F8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}