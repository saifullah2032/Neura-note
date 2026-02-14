import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/token_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teal = Colors.teal;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: teal),
        titleTextStyle: GoogleFonts.poppins(
          color: teal.shade900,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final firebaseUser = authProvider.firebaseUser;
          final displayName = firebaseUser?.displayName ?? 'User';
          final email = firebaseUser?.email ?? 'No email';
          final photoUrl = firebaseUser?.photoURL;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile picture
                CircleAvatar(
                  radius: 50,
                  backgroundColor: teal.shade200,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Icon(Icons.person, size: 50, color: teal.shade700)
                      : null,
                ),
                const SizedBox(height: 20),
                // User name
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Email
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const Divider(height: 30),
                // Token info
                Consumer<TokenProvider>(
                  builder: (context, tokenProvider, _) {
                    final remaining = tokenProvider.remainingTokens;
                    final total = tokenProvider.totalTokens;
                    return Text(
                      "Tokens Remaining: $remaining / $total",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: teal.shade900,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                // Go Premium button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text("Go Premium"),
                ),
                const SizedBox(height: 30),
                // Logout button
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'Sign Out',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          'Are you sure you want to sign out?',
                          style: GoogleFonts.poppins(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              'Sign Out',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await authProvider.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    'Sign Out',
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
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
}
