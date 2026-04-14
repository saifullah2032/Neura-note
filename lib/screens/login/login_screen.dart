import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart' as rive;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/themes.dart';
import '../../core/fluid_components.dart';
import '../widgets/ocean_ui_components.dart';
import '../widgets/swaying_coral.dart';

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
      curve: AppTheme.butterSmooth,
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeachSand,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 380;
          
          return Stack(
            children: [
              // Underwater Current Background
              UnderwaterCurrentBackground(
                child: const SizedBox.expand(),
              ),
              
              // Swaying Coral - Bottom Corners
              Positioned(
                bottom: 0,
                left: -20,
                child: SwayingCoral(
                  isLeft: true,
                  primaryColor: AppTheme.glassSoftTeal,
                  secondaryColor: AppTheme.primaryOceanTeal,
                  height: isSmallScreen ? 120 : 160,
                ),
              ),
              Positioned(
                bottom: 0,
                right: -20,
                child: SwayingCoral(
                  isLeft: false,
                  primaryColor: AppTheme.glassSoftTeal,
                  secondaryColor: AppTheme.primaryOceanTeal,
                  height: isSmallScreen ? 120 : 160,
                ),
              ),
              
              // Main Content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 20 : 32,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: isSmallScreen ? 20 : 40),
                          
                          // Logo Animation
                          SizedBox(
                            height: isSmallScreen ? 110 : 140,
                            width: isSmallScreen ? 110 : 140,
                            child: rive.RiveAnimation.asset(
                              'assets/animations/waving.riv',
                              fit: BoxFit.contain,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Welcome Card - Glassmorphism
                          OceanGlassCard(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 24 : 28,
                              vertical: isSmallScreen ? 28 : 36,
                            ),
                            backgroundColor: AppTheme.glassSoftTeal,
                            child: Column(
                              children: [
                                Text(
                                  'WELCOME',
                                  style: TextStyle(
                                    fontFamily: 'ClashDisplay',
                                    fontSize: isSmallScreen ? 20 : 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 3,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // App Icon
                                Container(
                                  width: isSmallScreen ? 48 : 56,
                                  height: isSmallScreen ? 48 : 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppTheme.actionCoral, AppTheme.glassLightPeach],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.actionCoral.withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome, 
                                    size: isSmallScreen ? 24 : 28, 
                                    color: Colors.white
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                Text(
                                  'NeuraNote AI',
                                  style: TextStyle(
                                    fontFamily: 'ClashDisplay',
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Login Button - 10% CORAL CTA
                                if (_isSigningIn)
                                  SizedBox(
                                    height: 48,
                                    width: 48,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.actionCoral,
                                      ),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: () => _signInWithGoogle(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.actionCoral,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.login, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Continue with Google',
                                            style: TextStyle(
                                              fontFamily: 'Satoshi',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Tagline
                          Text(
                            'Summarize your world — through images and voice',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 14,
                              height: 1.6,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: isSmallScreen ? 40 : 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
