import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart' as rive;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      setState(() => _isSigningIn = true);

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isSigningIn = false);
        return; // user cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (context.mounted) context.goNamed('home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offWhite = const Color(0xFFF8F9FA);
    final teal = Colors.teal;

    return Scaffold(
      backgroundColor: offWhite,
      body: Stack(
        children: [
          // Diagonal backgrounds (top left and top right)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _DiagonalPainter(teal, Alignment.topLeft),
                  ),
                  CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _DiagonalPainter(teal, Alignment.topRight),
                  ),
                ],
              ),
            ),
          ),
          // Beach wave animation at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 280, // Adjust height as needed
              width: double.infinity,
              child: Transform.rotate(
                angle: -3.14159, // -180 degrees in radians
                child: rive.RiveAnimation.asset(
                  'assets/animations/beach_wave.riv',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Foreground UI
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 36),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 80), // Space for animation
                          Text(
                            "WELCOME",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: teal.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: teal.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(Icons.auto_awesome,
                                size: 40, color: teal),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "NeuraNote AI",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: teal.shade900,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Replace CircularProgressIndicator with Rive loading animation
                          _isSigningIn
                              ? SizedBox(
                                  height: 48, // Match button height
                                  width: double.infinity,
                                  child: Center(
                                    child: SizedBox(
                                      height: 180, // Adjust as needed for your animation
                                      width: 180,
                                      child: rive.RiveAnimation.asset(
                                        'assets/animations/loading-lg.riv',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _signInWithGoogle(context),
                                  icon: const Icon(Icons.login),
                                  label: const Text("Continue with Google"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: teal,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    textStyle: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                        ],
                      ),
                    ),
                    // Waving animation in place of person icon
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 172,
                        width: 172,
                        child: rive.RiveAnimation.asset(
                          'assets/animations/waving.riv',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  "Summarize your world — through images and voice",
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.black38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagonalPainter extends CustomPainter {
  final Color color;
  final Alignment alignment;
  _DiagonalPainter(this.color, this.alignment);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.6), color.withOpacity(0.9)],
        begin: alignment,
        end: alignment == Alignment.topLeft
            ? Alignment.bottomRight
            : Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path();
    if (alignment == Alignment.topLeft) {
      // Only draw on the left half
      path
        ..moveTo(0, 0)
        ..lineTo(0, size.height)
        ..lineTo(size.width * 0.5, 0)
        ..close();
    } else {
      // Only draw on the right half
      path
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width * 0.5, 0)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
