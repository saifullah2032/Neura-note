import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart' as rive;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../widgets/ocean_animations.dart';
import '../widgets/ocean_ui_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isSigningIn = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      setState(() => _isSigningIn = true);

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isSigningIn = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (context.mounted) context.goNamed('home');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF006064).withValues(alpha: 0.08),
                    const Color(0xFF4DB6AC).withValues(alpha: 0.05),
                    const Color(0xFFF8F9FA),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF006064).withValues(alpha: 0.15),
                    const Color(0xFF006064).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Transform.rotate(
                angle: -3.14159,
                child: rive.RiveAnimation.asset(
                  'assets/animations/beach_wave.riv',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    SizedBox(
                      height: 160,
                      width: 160,
                      child: rive.RiveAnimation.asset(
                        'assets/animations/waving.riv',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    OceanGlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                      child: Column(
                        children: [
                          Text(
                            'WELCOME',
                            style: GoogleFonts.syne(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: const Color(0xFF006064),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF006064),
                                  const Color(0xFF4DB6AC),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF006064).withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.auto_awesome, size: 36, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'NeuraNote AI',
                            style: GoogleFonts.syne(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00363A),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_isSigningIn)
                            const SizedBox(
                              height: 48,
                              width: 48,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006064)),
                              ),
                            )
                          else
                            OceanButton(
                              text: 'Continue with Google',
                              icon: Icons.login,
                              width: double.infinity,
                              onPressed: () => _signInWithGoogle(context),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Summarize your world — through images and voice',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: const Color(0xFF546E7A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
