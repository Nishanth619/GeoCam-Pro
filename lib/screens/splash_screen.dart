import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'permissions_screen.dart';
import 'legal_acceptance_screen.dart';
import '../services/permission_service.dart';

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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for the full animation cycle (~3.6 s) before navigating
    Future.delayed(const Duration(milliseconds: 3600), _navigateToNext);
  }

  void _navigateToNext() async {
    if (!mounted) return;
    Widget nextScreen;

    if (!widget.hasAcceptedTerms) {
      nextScreen = LegalAcceptanceScreen(hasSeenOnboarding: widget.hasSeenOnboarding);
    } else if (widget.hasSeenOnboarding) {
      // Even for returning users, verify all permissions are still granted.
      // The user may have revoked them from Settings since last launch.
      final hasAllPermissions = await PermissionService().hasRequiredPermissions();
      if (!mounted) return;
      if (hasAllPermissions) {
        nextScreen = const HomeScreen();
      } else {
        nextScreen = const PermissionsScreen();
      }
    } else {
      nextScreen = const OnboardingScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => nextScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF070E14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedCameraIcon(size: 200),
            SizedBox(height: 40),
            Text(
              'GEOCAM',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =========================================================
/// REUSABLE ANIMATED ICON WIDGET
/// =========================================================
class AnimatedCameraIcon extends StatefulWidget {
  final double size;

  const AnimatedCameraIcon({
    super.key,
    this.size = 280,
  });

  @override
  State<AnimatedCameraIcon> createState() => _AnimatedCameraIconState();
}

class _AnimatedCameraIconState extends State<AnimatedCameraIcon>
    with TickerProviderStateMixin {
  // Hover Parallax State
  bool isHovered = false;
  double rotateX = 0;
  double rotateY = 0;

  // Animation Controllers
  late AnimationController _radarController;
  late AnimationController _shutterController;
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();

    // 1. Radar Spin (30 seconds, linear, repeats forever)
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // 2. Sweeping Light Glare (6 seconds, repeats forever)
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // 3. Shutter Double Focus Snap (6 seconds, complex curve)
    _shutterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _shutterController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent details, BoxConstraints constraints) {
    final centerX = constraints.maxWidth / 2;
    final centerY = constraints.maxHeight / 2;
    setState(() {
      isHovered = true;
      rotateX = ((details.localPosition.dy - centerY) / centerY) * -18;
      rotateY = ((details.localPosition.dx - centerX) / centerX) * 18;
    });
  }

  void _onExit(PointerEvent details) {
    setState(() {
      isHovered = false;
      rotateX = 0;
      rotateY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (e) => _onHover(e, constraints),
          onExit: _onExit,
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Dynamic Hover Glow
                AnimatedOpacity(
                  opacity: isHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedScale(
                    scale: isHovered ? 1.2 : 0.9,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      width: widget.size * 0.9,
                      height: widget.size * 0.9,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x4D818CF8), blurRadius: 60),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3D Parallax container
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 150),
                  builder: (context, double val, child) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(rotateX * math.pi / 180)
                        ..rotateY(rotateY * math.pi / 180)
                        ..scale(isHovered ? 1.05 : 1.0),
                      alignment: FractionalOffset.center,
                      child: child,
                    );
                  },
                  child: _buildDrawnLogo(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawnLogo() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.size * (63 / 280)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x990F172A),
            offset: Offset(0, 25),
            blurRadius: 35,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Squircle and Radar
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size * (63 / 280)),
              child: AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _LogoBackgroundPainter(
                      radarRotation: _radarController.value * 2 * math.pi,
                    ),
                  );
                },
              ),
            ),
          ),

          // Shutter, Lens, and Glare
          Positioned.fill(
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_shutterController, _sweepController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _LogoForegroundPainter(
                    shutterProgress: _shutterController.value,
                    sweepProgress: _sweepController.value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// =========================================================
/// CUSTOM PAINTERS
/// =========================================================

// Painter 1: Background, Bevel, and Spinning Radar
class _LogoBackgroundPainter extends CustomPainter {
  final double radarRotation;
  _LogoBackgroundPainter({required this.radarRotation});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 200);

    final Rect rect = const Rect.fromLTWH(0, 0, 200, 200);
    final RRect squircle =
        RRect.fromRectAndRadius(rect, const Radius.circular(45));

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E1B4B), Color(0xFF020617)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(squircle, bgPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(1.5, 1.5, 197, 197),
          const Radius.circular(43.5)),
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawRRect(
      squircle,
      Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Spinning Radar
    canvas.save();
    canvas.translate(100, 100);
    canvas.rotate(radarRotation);
    canvas.translate(-100, -100);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.5;
    final dashedPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final solidCirclePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(const Offset(100, 100), 35, solidCirclePaint);
    canvas.drawCircle(const Offset(100, 100), 115, solidCirclePaint);
    canvas.drawCircle(const Offset(100, 100), 75, dashedPaint);
    canvas.drawCircle(const Offset(100, 100), 155,
        dashedPaint..color = Colors.white.withOpacity(0.1));

    canvas.drawLine(const Offset(100, -100), const Offset(100, 300), linePaint);
    canvas.drawLine(const Offset(-100, 100), const Offset(300, 100), linePaint);
    canvas.drawLine(
      const Offset(-41, -41),
      const Offset(241, 241),
      linePaint
        ..color = Colors.white.withOpacity(0.08)
        ..strokeWidth = 1,
    );
    canvas.drawLine(const Offset(-41, 241), const Offset(241, -41), linePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoBackgroundPainter oldDelegate) =>
      oldDelegate.radarRotation != radarRotation;
}

// Painter 2: Pin, Lens, Shutter Animation, Glare, Light Sweep
class _LogoForegroundPainter extends CustomPainter {
  final double shutterProgress;
  final double sweepProgress;

  _LogoForegroundPainter({
    required this.shutterProgress,
    required this.sweepProgress,
  });

  final TweenSequence<double> _shutterRotationSeq = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 8),
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 4),
    TweenSequenceItem(tween: Tween(begin: 10.0, end: -20.0), weight: 4),
    TweenSequenceItem(tween: Tween(begin: -20.0, end: 5.0), weight: 6),
    TweenSequenceItem(tween: Tween(begin: 5.0, end: 18.0), weight: 6),
    TweenSequenceItem(tween: Tween(begin: 18.0, end: -65.0), weight: 8),
    TweenSequenceItem(tween: Tween(begin: -65.0, end: 0.0), weight: 19),
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 45),
  ]);

  final TweenSequence<double> _shutterScaleSeq = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 8),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.02), weight: 4),
    TweenSequenceItem(tween: Tween(begin: 1.02, end: 0.92), weight: 4),
    TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.01), weight: 6),
    TweenSequenceItem(tween: Tween(begin: 1.01, end: 1.05), weight: 6),
    TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.75), weight: 8),
    TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.0), weight: 19),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 45),
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 200);

    // 3D Folded Map Pin
    final Path pinLeft = Path()
      ..moveTo(100, 170)
      ..cubicTo(100, 170, 48, 115, 48, 78)
      ..arcToPoint(const Offset(100, 26),
          radius: const Radius.circular(52), clockwise: true)
      ..close();

    final Path pinRight = Path()
      ..moveTo(100, 26)
      ..arcToPoint(const Offset(152, 78),
          radius: const Radius.circular(52), clockwise: true)
      ..cubicTo(152, 115, 100, 170, 100, 170)
      ..close();

    final Path totalPin = Path.combine(PathOperation.union, pinLeft, pinRight);
    canvas.drawPath(
      totalPin.shift(const Offset(0, 16)),
      Paint()
        ..color = Colors.black54
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawPath(
      pinLeft,
      Paint()
        ..shader = const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)])
            .createShader(pinLeft.getBounds()),
    );
    canvas.drawPath(
      pinRight,
      Paint()
        ..shader = const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
            .createShader(pinRight.getBounds()),
    );

    // Metallic Outer Lens Ring
    canvas.drawCircle(
      const Offset(100, 78),
      38,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Color(0xFFE2E8F0), Color(0xFF94A3B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(62, 40, 76, 76)),
    );
    canvas.drawCircle(
      const Offset(100, 78),
      38,
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Inner Dark Lens
    canvas.drawCircle(const Offset(100, 78), 33,
        Paint()..color = const Color(0xFF09090B));

    // Shutter Animation
    final double sRot =
        _shutterRotationSeq.transform(shutterProgress) * math.pi / 180;
    final double sScale = _shutterScaleSeq.transform(shutterProgress);

    canvas.save();
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(center: const Offset(100, 78), radius: 33)));

    final double pupilPulse =
        math.sin(shutterProgress * math.pi * 6).abs() * 2;
    canvas.drawCircle(
        const Offset(100, 78), 13 + pupilPulse, Paint()..color = Colors.black);

    canvas.translate(100, 78);
    canvas.rotate(sRot);
    canvas.scale(sScale);
    canvas.translate(-100, -78);

    final Path blade = Path()
      ..moveTo(94, 62)
      ..lineTo(145, 25)
      ..lineTo(140, 100)
      ..close();
    final bladePaint = Paint()
      ..shader = const LinearGradient(colors: [Colors.white, Color(0xFFCBD5E1)])
          .createShader(blade.getBounds());
    final bladeStroke = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    for (int i = 0; i < 6; i++) {
      canvas.save();
      canvas.translate(100, 78);
      canvas.rotate((i * 60) * math.pi / 180);
      canvas.translate(-100, -78);
      canvas.drawPath(
        blade.shift(const Offset(0, 2)),
        Paint()
          ..color = Colors.black54
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawPath(blade, bladePaint);
      canvas.drawPath(blade, bladeStroke);
      canvas.restore();
    }
    canvas.restore();

    // Curved Glass Glare
    final Path glare = Path()
      ..moveTo(73, 55)
      ..arcToPoint(const Offset(127, 55),
          radius: const Radius.circular(33), clockwise: true)
      ..arcToPoint(const Offset(73, 55),
          radius: const Radius.circular(28), clockwise: false)
      ..close();
    canvas.drawPath(glare, Paint()..color = Colors.white.withOpacity(0.4));

    canvas.drawCircle(
      const Offset(118, 62),
      3,
      Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );

    canvas.drawCircle(
      const Offset(100, 78),
      33,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Sweeping Light Glare Effect
    double sweepX = -150.0;
    if (sweepProgress > 0.15 && sweepProgress < 0.35) {
      final double t = (sweepProgress - 0.15) / 0.20;
      sweepX = -150.0 + (t * 500.0);
    } else if (sweepProgress >= 0.35) {
      sweepX = 350.0;
    }

    canvas.save();
    canvas.clipPath(Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 200, 200), const Radius.circular(45))));

    canvas.transform((Matrix4.identity()
          ..translate(sweepX)
          ..setEntry(0, 1, math.tan(-35 * math.pi / 180)))
        .storage);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 80, 300),
      Paint()
        ..shader = LinearGradient(colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.0),
        ]).createShader(const Rect.fromLTWH(0, 0, 80, 300)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoForegroundPainter oldDelegate) =>
      oldDelegate.shutterProgress != shutterProgress ||
      oldDelegate.sweepProgress != sweepProgress;
}
