import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCurrency = 'NPR';
  String _selectedLanguage = 'English';

  // Profile data
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _storeName = '';
  String _storeAddress = '';

  // Dialog controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPreferences();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('fullName') ?? 'Not set';
      _email = prefs.getString('email') ?? 'Not set';
      _phone = prefs.getString('phone') ?? 'Not set';
      _storeName = prefs.getString('store_name') ?? 'Everest Kirana Store';
      _storeAddress = prefs.getString('store_address') ?? 'Not set';
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('currency') ?? 'NPR';
      _selectedLanguage = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', _selectedCurrency);
    await prefs.setString('language', _selectedLanguage);
  }

  void _navigateToProfile() {
    _nameController.text = _fullName == 'Not set' ? '' : _fullName;
    _emailController.text = _email == 'Not set' ? '' : _email;
    _phoneController.text = _phone == 'Not set' ? '' : _phone;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Profile Information',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.primary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColor.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColor.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                    prefixText: '+977 ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColor.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppColor.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              if (_nameController.text.isNotEmpty) {
                await prefs.setString('fullName', _nameController.text);
              }
              if (_emailController.text.isNotEmpty && _emailController.text.contains('@')) {
                await prefs.setString('email', _emailController.text);
              }
              if (_phoneController.text.isNotEmpty && _phoneController.text.length == 10) {
                await prefs.setString('phone', _phoneController.text);
              }
              await _loadUserData();
              if (mounted) Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Profile updated successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToStoreSettings() {
    _storeNameController.text = _storeName;
    _storeAddressController.text = _storeAddress == 'Not set' ? '' : _storeAddress;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Store Settings',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.primary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _storeNameController,
                  decoration: InputDecoration(
                    labelText: 'Store Name',
                    labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColor.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _storeAddressController,
                  decoration: InputDecoration(
                    labelText: 'Store Address',
                    labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColor.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppColor.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              if (_storeNameController.text.isNotEmpty) {
                await prefs.setString('store_name', _storeNameController.text);
              }
              if (_storeAddressController.text.isNotEmpty) {
                await prefs.setString('store_address', _storeAddressController.text);
              }
              await _loadUserData();
              if (mounted) Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Store settings updated successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete All Data',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.error,
          ),
        ),
        content: Text(
          'This will delete ALL products and sales. This action cannot be undone. Are you sure?',
          style: GoogleFonts.manrope(fontSize: 14, color: AppColor.neutral),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppColor.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('products');
              await prefs.remove('sales');
              await prefs.remove('manual_predictions');
              if (mounted) Navigator.pop(context);
              Fluttertoast.showToast(msg: 'All data deleted successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Delete All',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.error,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.manrope(fontSize: 14, color: AppColor.neutral),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppColor.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool("isLoggedIn", false);
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'About SmartShelf',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store, size: 50, color: AppColor.primary),
            const SizedBox(height: 16),
            Text(
              'SmartShelf v1.0.0',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart Inventory Management System',
              style: GoogleFonts.manrope(color: AppColor.secondary),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Features:\n'
                  '• Inventory Management\n'
                  '• AI-Powered Predictions\n'
                  '• Sales Analytics\n'
                  '• Bulk Import (CSV)\n'
                  '• Export Orders (WhatsApp/CSV)',
              style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '© 2024 SmartShelf. All rights reserved.',
              style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.manrope(color: AppColor.secondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Profile Information',
            subtitle: _fullName != 'Not set' ? _fullName : 'Manage your account details',
            onTap: _navigateToProfile,
          ),
          _buildSettingsTile(
            icon: Icons.store_outlined,
            title: 'Store Settings',
            subtitle: _storeName,
            onTap: _navigateToStoreSettings,
          ),

          const Divider(),

          // Data Management Section
          _buildSectionHeader('Data Management'),
          _buildSettingsTile(
            icon: Icons.backup_outlined,
            title: 'Backup Data',
            subtitle: 'Coming soon',
            onTap: () => Fluttertoast.showToast(msg: 'Backup feature coming soon'),
          ),
          _buildSettingsTile(
            icon: Icons.restore_outlined,
            title: 'Restore Data',
            subtitle: 'Coming soon',
            onTap: () => Fluttertoast.showToast(msg: 'Restore feature coming soon'),
          ),
          _buildSettingsTile(
            icon: Icons.delete_outline,
            title: 'Delete All Data',
            subtitle: 'Permanently delete all products and sales',
            onTap: _showDeleteConfirmation,
            textColor: AppColor.error,
          ),

          const Divider(),

          // Preferences Section
          _buildSectionHeader('Preferences'),
          _buildDropdownTile(
            icon: Icons.attach_money,
            title: 'Currency',
            value: _selectedCurrency,
            items: ['NPR', 'USD', 'INR', 'EUR'],
            onChanged: (value) async {
              setState(() => _selectedCurrency = value!);
              await _savePreferences();
              Fluttertoast.showToast(msg: 'Currency changed to $value');
            },
          ),
          _buildDropdownTile(
            icon: Icons.language,
            title: 'Language',
            value: _selectedLanguage,
            items: ['English', 'Nepali', 'Hindi'],
            onChanged: (value) async {
              setState(() => _selectedLanguage = value!);
              await _savePreferences();
              Fluttertoast.showToast(msg: 'Language changed to $value');
            },
          ),

          const Divider(),

          // About Section
          _buildSectionHeader('About'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About SmartShelf',
            subtitle: 'Version 1.0.0',
            onTap: _showAboutDialog,
          ),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: _showLogoutConfirmation,
            textColor: AppColor.error,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
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
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColor.secondary),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          color: textColor ?? AppColor.neutral,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.manrope(
          fontSize: 12,
          color: AppColor.secondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColor.secondary),
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColor.secondary),
      title: Text(
        title,
        style: GoogleFonts.manrope(color: AppColor.neutral),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AppColor.background,
        style: GoogleFonts.manrope(color: AppColor.neutral),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: AppColor.primary),
      ),
    );
  }
}