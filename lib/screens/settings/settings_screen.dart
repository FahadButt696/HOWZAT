import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../routes/app_routes.dart'; // For navigation after logout

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Method to handle logout
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to the login/home screen and remove all previous routes
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
    } catch (e) {
      print("Error during logout: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B6623), Color(0xFF1E3C72)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "Settings",
                    style: GoogleFonts.balooBhai2(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // REMOVED: General Section Header
              // _buildSettingSectionHeader("General"),
              // REMOVED: Adjust UI mode tile
              // _buildSettingTile(
              //   icon: Icons.light_mode,
              //   title: "Adjust UI mode",
              //   onTap: () {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(
              //           content: Text('UI Mode adjustment coming soon!'),
              //           duration: const Duration(seconds: 2)), // Set duration
              //     );
              //   },
              // ),
              // REMOVED: Remove ads tile
              // _buildSettingTile(
              //   icon: Icons.ad_units,
              //   title: "Remove ads",
              //   onTap: () {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(
              //           content: Text('Ad removal functionality coming soon!'),
              //           duration: const Duration(seconds: 2)), // Set duration
              //     );
              //   },
              // ),
              // REMOVED: Clear all data tile
              // _buildSettingTile(
              //   icon: Icons.delete_forever,
              //   title: "Clear all data",
              //   onTap: () {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(
              //           content: Text('Clear all data functionality coming soon!'),
              //           duration: const Duration(seconds: 2)), // Set duration
              //     );
              //   },
              // ),
              _buildSettingSectionHeader("Help & Feedback"),
              _buildSettingTile(
                icon: Icons.star_rate,
                title: "Rate us",
                subtitle: "Rate us and use our apps",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Rate us functionality coming soon!'),
                        duration: const Duration(seconds: 2)), // Set duration
                  );
                },
              ),
              _buildSettingTile(
                icon: Icons.share,
                title: "Share this app",
                subtitle: "Share the app to your friends",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Share app functionality coming soon!'),
                        duration: const Duration(seconds: 2)), // Set duration
                  );
                },
              ),
              _buildSettingTile(
                icon: Icons.feedback,
                title: "Feedback",
                subtitle: "Report bugs and tell us what to improve",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Feedback functionality coming soon!'),
                        duration: const Duration(seconds: 2)), // Set duration
                  );
                },
              ),
              _buildSettingTile(
                icon: Icons.play_arrow,
                title: "See the app on Play Store",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Play Store link coming soon!'),
                        duration: const Duration(seconds: 2)), // Set duration
                  );
                },
              ),
              _buildSettingTile(
                icon: Icons.privacy_tip,
                title: "Privacy policy",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Privacy policy link coming soon!'),
                        duration: const Duration(seconds: 2)), // Set duration
                  );
                },
              ),
              const SizedBox(height: 20),
              // Logout Button
              Center(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.redAccent, Colors.red],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: Text(
                      "Logout",
                      style: GoogleFonts.balooBhai2(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "Version 1.9",
                  style: GoogleFonts.balooBhai2(color: Colors.white54, fontSize: 14),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: GoogleFonts.balooBhai2(
          fontSize: 18,
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          title,
          style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 16),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: GoogleFonts.balooBhai2(color: Colors.white54, fontSize: 12),
        )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: onTap,
      ),
    );
  }
}
