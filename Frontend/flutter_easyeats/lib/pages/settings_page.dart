import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'home_page.dart' as home;
import 'dining_halls.dart' as dining;
import 'profile_page.dart';
import 'change_password_page.dart';
import 'notifications_page.dart';
import 'dietary_restrictions_page.dart';
import 'favorites_page.dart';
import 'about_page.dart';
import 'help_support_page.dart';
import 'privacy_policy_page.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const home.MainPage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const dining.MainPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Dining Halls',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 10),
            Center(
              child: Image.asset(
                'assets/images/Logo.png',
                height: 60,
              ),
            ),
            const SizedBox(height: 30),

            _buildSettingsSection(
              context,
              'Account',
              [
                _buildSettingsTile(Icons.person, 'Profile', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                }),
                _buildSettingsTile(Icons.lock, 'Change Password', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),

            _buildSettingsSection(
              context,
              'Preferences',
              [
                _buildSettingsTile(Icons.notifications, 'Notifications', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()),
                  );
                }),
                _buildSettingsTile(Icons.restaurant, 'Dietary Restrictions', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DietaryRestrictionsPage()),
                  );
                }),
                _buildSettingsTile(Icons.favorite, 'Favorites', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FavoritesPage()),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),

            _buildSettingsSection(
              context,
              'About',
              [
                _buildSettingsTile(Icons.info, 'About EasyEats', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                }),
                _buildSettingsTile(Icons.help, 'Help & Support', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpSupportPage()),
                  );
                }),
                _buildSettingsTile(Icons.privacy_tip, 'Privacy Policy', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                  );
                }),
              ],
            ),
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () async {
                  // End the session on the server, then clear it on this device
                  await AuthService.logout();
                  await UserService.clearCurrentUser();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
