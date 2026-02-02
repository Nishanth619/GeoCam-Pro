import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'legal_acceptance_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool hasSeenOnboarding;
  final bool hasAcceptedTerms;

  const SplashScreen({
    super.key,
    required this.hasSeenOnboarding,
    required this.hasAcceptedTerms,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  
  static const Color brandGreen = Color(0xFF00D98E);
  static const double totalDuration = 3200;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _mainController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), _navigateToNext);
    });
  }

  // Animation getters with CSS-matched timings
  double get _logoZoom {
    const start = 0.0;
    const end = 1000 / totalDuration;
    if (_mainController.value < start) return 0;
    if (_mainController.value > end) return 1;
    final t = (_mainController.value - start) / (end - start);
    // Cubic bezier approximation for (0.34, 1.56, 0.64, 1)
    return _elasticOut(t);
  }

  double get _cameraRotate {
    const start = 300 / totalDuration;
    const end = 1500 / totalDuration;
    if (_mainController.value < start) return 0;
    if (_mainController.value > end) return 1;
    return Curves.easeOut.transform((_mainController.value - start) / (end - start));
  }

  double get _outerCircleFade {
    const start = 800 / totalDuration;
    const end = 1400 / totalDuration;
    if (_mainController.value < start) return 0;
    if (_mainController.value > end) return 1;
    return Curves.easeOut.transform((_mainController.value - start) / (end - start));
  }

  double get _crosshairSlide {
    const start = 1000 / totalDuration;
    const end = 1500 / totalDuration;
    if (_mainController.value < start) return 0;
    if (_mainController.value > end) return 1;
    return Curves.easeOut.transform((_mainController.value - start) / (end - start));
  }

  double _bladeAnim(int index) {
    double startMs = 1200 + (index * 100);
    double endMs = startMs + 400;
    double start = startMs / totalDuration;
    double end = endMs / totalDuration;
    if (_mainController.value < start) return 0;
    if (_mainController.value > end) return 1;
    return Curves.easeOut.transform((_mainController.value - start) / (end - start));
  }

  double get _eyeAppear {
    const start = 1900 / totalDuration;
    const end = 2200 / totalDuration;
    if (_mainController.value < start) return 0;
    if (_mainController.value > end) return 1;
    return Curves.easeOut.transform((_mainController.value - start) / (end - start));
  }

  double get _textSlide {
    const start = 2000 / totalDuration;
    const end = 2800 / totalDuration;
    if (_mainController.value < start) return 0;
    if (_mainController.value > end) return 1;
    return Curves.easeOut.transform((_mainController.value - start) / (end - start));
  }

  double _elasticOut(double t) {
    // Approximation of cubic-bezier(0.34, 1.56, 0.64, 1)
    return 1 - math.pow(1 - t, 3) * (1 - 1.56 * t);
  }

  void _navigateToNext() {
    Widget nextScreen;
    
    if (!widget.hasAcceptedTerms) {
      nextScreen = LegalAcceptanceScreen(hasSeenOnboarding: widget.hasSeenOnboarding);
    } else if (widget.hasSeenOnboarding) {
      nextScreen = const HomeScreen();
    } else {
      nextScreen = const OnboardingScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container
                Transform.scale(
                  scale: _logoZoom.clamp(0.0, 1.5),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Outer Circle
                        Opacity(
                          opacity: _outerCircleFade,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: brandGreen, width: 8),
                            ),
                          ),
                        ),
                        
                        // Crosshair Lines - OUTSIDE the circle
                        // Top line
                        Positioned(
                          top: 25 - 45 - (3 * (1 - _crosshairSlide)),
                          child: Opacity(
                            opacity: _crosshairSlide,
                            child: Container(width: 8, height: 40, color: brandGreen),
                          ),
                        ),
                        // Bottom line
                        Positioned(
                          bottom: 25 - 45 - (3 * (1 - _crosshairSlide)),
                          child: Opacity(
                            opacity: _crosshairSlide,
                            child: Container(width: 8, height: 40, color: brandGreen),
                          ),
                        ),
                        // Left line
                        Positioned(
                          left: 25 - 45 - (3 * (1 - _crosshairSlide)),
                          child: Opacity(
                            opacity: _crosshairSlide,
                            child: Container(width: 40, height: 8, color: brandGreen),
                          ),
                        ),
                        // Right line
                        Positioned(
                          right: 25 - 45 - (3 * (1 - _crosshairSlide)),
                          child: Opacity(
                            opacity: _crosshairSlide,
                            child: Container(width: 40, height: 8, color: brandGreen),
                          ),
                        ),

                        // Camera Circle
                        Transform.rotate(
                          angle: (1 - _cameraRotate) * -math.pi,
                          child: Transform.scale(
                            scale: 0.3 + (_cameraRotate * 0.7),
                            child: Opacity(
                              opacity: _cameraRotate,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 6),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 75,
                                    height: 75,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Aperture blades - 6 triangles around center
                                        ...List.generate(6, (index) => _buildBlade(index)),
                                        
                                        // Eye/Pupil in center
                                        Opacity(
                                          opacity: _eyeAppear,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              color: Colors.black,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  top: 5,
                                                  left: 6,
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.9),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
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
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // GEOCAM Text
                Opacity(
                  opacity: _textSlide,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _textSlide)),
                    child: const Text(
                      'GEOCAM',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlade(int index) {
    final anim = _bladeAnim(index);
    final double angle = index * 60 * math.pi / 180; // 0, 60, 120, 180, 240, 300 degrees
    
    // Bounce effect: 0 -> 1.2 at 60% -> 1 at 100%
    double scale = 0;
    if (anim > 0) {
      if (anim < 0.6) {
        scale = (anim / 0.6) * 1.2;
      } else {
        scale = 1.2 - ((anim - 0.6) / 0.4) * 0.2;
      }
    }

    return Transform.rotate(
      angle: angle,
      child: Align(
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: anim > 0 ? 1 : 0,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: const Size(28, 34),
              painter: _TrianglePainter(color: brandGreen),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    
    // Triangle pointing UP: top center, bottom left, bottom right
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
