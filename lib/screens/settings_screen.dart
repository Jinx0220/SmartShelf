import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/colors.dart';
import 'profile_screen.dart';
import 'store_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedCurrency = 'NPR';
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColor.darkBackground : AppColor.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
        ),
        backgroundColor: isDarkMode ? AppColor.darkSurface : Colors.white,
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Account', isDarkMode),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Profile Information',
            subtitle: 'Manage your account details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            isDarkMode: isDarkMode,
          ),
          _buildSettingsTile(
            icon: Icons.store_outlined,
            title: 'Store Settings',
            subtitle: 'Store name, address, contact',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StoreSettingsScreen()),
              );
            },
            isDarkMode: isDarkMode,
          ),

          const Divider(),

          // Preferences Section
          _buildSectionHeader('Preferences', isDarkMode),
          _buildSwitchTile(
            icon: Icons.notifications_none_outlined,
            title: 'Push Notifications',
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            isDarkMode: isDarkMode,
          ),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            value: isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            isDarkMode: isDarkMode,
          ),
          _buildDropdownTile(
            icon: Icons.attach_money,
            title: 'Currency',
            value: _selectedCurrency,
            items: ['NPR', 'USD', 'INR', 'EUR'],
            onChanged: (value) => setState(() => _selectedCurrency = value!),
            isDarkMode: isDarkMode,
          ),
          _buildDropdownTile(
            icon: Icons.language,
            title: 'Language',
            value: _selectedLanguage,
            items: ['English', 'Nepali', 'Hindi'],
            onChanged: (value) => setState(() => _selectedLanguage = value!),
            isDarkMode: isDarkMode,
          ),

          const Divider(),

          // Data Management
          _buildSectionHeader('Data Management', isDarkMode),
          _buildSettingsTile(
            icon: Icons.backup_outlined,
            title: 'Backup Data',
            subtitle: 'Backup to cloud',
            onTap: () => _showComingSoon('Backup Data', isDarkMode),
            isDarkMode: isDarkMode,
          ),
          _buildSettingsTile(
            icon: Icons.restore_outlined,
            title: 'Restore Data',
            subtitle: 'Restore from backup',
            onTap: () => _showComingSoon('Restore Data', isDarkMode),
            isDarkMode: isDarkMode,
          ),
          _buildSettingsTile(
            icon: Icons.delete_outline,
            title: 'Delete All Data',
            subtitle: 'Permanently delete all data',
            onTap: () => _showDeleteConfirmation(),
            textColor: AppColor.error,
            isDarkMode: isDarkMode,
          ),

          const Divider(),

          // About
          _buildSectionHeader('About', isDarkMode),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About SmartShelf',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutDialog(isDarkMode),
            isDarkMode: isDarkMode,
          ),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: () => _showLogoutConfirmation(),
            textColor: AppColor.error,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColor.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColor.secondary),
      title: Text(
        title,
        style: TextStyle(
            color: textColor ?? (isDarkMode ? AppColor.darkText : AppColor.neutral)
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColor.secondary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required bool isDarkMode,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColor.secondary),
      title: Text(
        title,
        style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColor.primary,
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColor.secondary),
      title: Text(
        title,
        style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: isDarkMode ? AppColor.darkSurface : Colors.white,
        style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
      ),
    );
  }

  void _showComingSoon(String feature, bool isDarkMode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColor.darkSurface : Colors.white,
        title: const Text('About SmartShelf'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store, size: 50, color: AppColor.primary),
            const SizedBox(height: 16),
            Text(
              'SmartShelf v1.0.0',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColor.darkText : AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart Inventory Management System',
              style: TextStyle(color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '© 2024 SmartShelf. All rights reserved.',
              style: TextStyle(fontSize: 12, color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColor.darkSurface : Colors.white,
        title: Text(
          'Delete All Data',
          style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
        ),
        content: Text(
          'This action cannot be undone. Are you sure you want to delete all data?',
          style: TextStyle(color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data deleted!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColor.darkSurface : Colors.white,
        title: Text(
          'Logout',
          style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}