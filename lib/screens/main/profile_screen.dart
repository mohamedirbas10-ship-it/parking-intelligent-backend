import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userEmail = '';
  int _totalBookings = 0;
  int _activeBookings = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('reservationHistory') ?? [];
    final userEmail = prefs.getString('userEmail') ?? '';

    // Count bookings for this user
    int total = 0;
    int active = 0;

    for (var json in historyJson) {
      final parts = json.split('|');
      if (parts.length > 5 && parts[5] == userEmail) {
        total++;
        // Check if active (not expired)
        final reservationTime = DateTime.parse(parts[2]);
        final validityHours = int.parse(parts[3]);
        final expiryTime = reservationTime.add(Duration(hours: validityHours));
        if (DateTime.now().isBefore(expiryTime)) {
          active++;
        }
      }
    }

    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _userEmail = userEmail;
      _totalBookings = total;
      _activeBookings = active;
      _isLoading = false;
    });
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Verify current password and update
              final prefs = await SharedPreferences.getInstance();
              final registeredUsers = prefs.getStringList('registeredUsers') ?? [];
              bool updated = false;

              for (int i = 0; i < registeredUsers.length; i++) {
                final parts = registeredUsers[i].split('|');
                if (parts.length >= 3 && parts[1] == _userEmail && parts[2] == currentPasswordController.text) {
                  // Update password
                  registeredUsers[i] = '${parts[0]}|${parts[1]}|${newPasswordController.text}';
                  await prefs.setStringList('registeredUsers', registeredUsers);
                  updated = true;
                  break;
                }
              }

              if (updated) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Current password is incorrect'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('CHANGE'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userEmail');
      await prefs.remove('userName');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userEmail,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats Cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Bookings',
                            _totalBookings.toString(),
                            Icons.history,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Active Bookings',
                            _activeBookings.toString(),
                            Icons.local_parking,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Settings Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsTile(
                          icon: Icons.lock,
                          title: 'Change Password',
                          subtitle: 'Update your password',
                          onTap: _changePassword,
                        ),
                        _buildSettingsTile(
                          icon: Icons.info,
                          title: 'About',
                          subtitle: 'App version 1.0.0',
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Smart Car Parking',
                              applicationVersion: '1.0.0',
                              applicationIcon: Icon(
                                Icons.local_parking_rounded,
                                size: 48,
                                color: Colors.blue.shade700,
                              ),
                              children: [
                                const Text('A smart parking management system for easy booking and management of parking slots.'),
                              ],
                            );
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.logout,
                          title: 'Logout',
                          subtitle: 'Sign out of your account',
                          onTap: _logout,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color.shade600),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color.shade600),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red.shade700 : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }
}
