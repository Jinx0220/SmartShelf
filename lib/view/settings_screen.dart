// ignore_for_file: spell_checking_inspector

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:smartshelf/viewmodel/theme_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/colors.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../viewmodel/product_viewmodel.dart';
import '../viewmodel/sale_viewmodel.dart';
import '../viewmodel/dashboard_viewmodel.dart'; // 🟢 ADD THIS IMPORT
import '../model/user_model.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeAddressController = TextEditingController();

  bool _isInjectingMock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<AuthViewModel>().loadCurrentUser();
      if (!mounted) return;
      await context.read<SettingsViewModel>().loadSettings();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    super.dispose();
  }

  // --- CORE DATA OPERATIONS & HANDLERS ---

  Future<void> _clearAppCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final List<FileSystemEntity> entities = tempDir.listSync();
        for (var entity in entities) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
        Fluttertoast.showToast(msg: "Temporary cache cleared successfully!");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to clear temporary app files.");
    }
  }

  Future<void> _handleAccountDeletion() async {
    final TextEditingController deleteController = TextEditingController();
    final navigator = Navigator.of(context);
    final authVm = context.read<AuthViewModel>();
    final dashboardVm = context.read<DashboardViewModel>(); // 🟢 ADD THIS

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete Account",
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: AppColor.error),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This action is permanent and will completely delete your store account, products, and records.",
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              "Type 'DELETE' to confirm:",
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.secondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: deleteController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error),
            onPressed: () => Navigator.pop(context, deleteController.text.trim() == 'DELETE'),
            child: const Text("Confirm Delete"),
          )
        ],
      ),
    );

    if (confirm == true) {
      Fluttertoast.showToast(msg: "Deleting account references...");
      bool success = await authVm.deleteAccountPermanently();

      if (success) {
        // 🟢 ADD THIS: Reset dashboard before navigating
        await dashboardVm.loadDashboardData();

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      } else {
        Fluttertoast.showToast(msg: authVm.error ?? "Failed to delete account.");
      }
    }
  }

  Future<void> _launchFeedbackChannel() async {
    final Uri url = Uri.parse("mailto:support@smartshelf.com?subject=SmartShelf%20Feedback");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Fluttertoast.showToast(msg: "Could not open default email client.");
    }
  }

  // --- DATA BACKUP STORAGE ENGINE ---
  Future<void> _executeDataBackup() async {
    final navigator = Navigator.of(context);
    final productVm = context.read<ProductViewModel>();
    final saleVm = context.read<SaleViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const CircularProgressIndicator(color: AppColor.primary),
            const SizedBox(height: 20),
            Text("Creating secure backup file...", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );

    try {
      final Map<String, dynamic> backupPayload = {
        'products': productVm.allProducts?.map((p) => p.toMap()).toList() ?? [],
        'sales': saleVm.sales?.map((s) => s.toMap()).toList() ?? [],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'appVersion': '1.0.0'
      };

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/smartshelf_bkp_latest.json');
      await file.writeAsString(jsonEncode(backupPayload));

      navigator.pop();

      Fluttertoast.showToast(
        msg: "Backup file saved securely!",
        backgroundColor: AppColor.success,
        textColor: Colors.white,
      );
    } catch (e) {
      navigator.pop();
      Fluttertoast.showToast(msg: "Backup failed: ${e.toString()}", backgroundColor: AppColor.error);
    }
  }

  // --- DATA RESTORE STORAGE ENGINE ---
  void _executeDataRestore() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Restore Data from Backup',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select a saved backup file to restore:', style: GoogleFonts.manrope(fontSize: 14)),
            const SizedBox(height: 14),
            _buildBackupFileSlot("smartshelf_bkp_latest.json"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppColor.secondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupFileSlot(String filename) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file_outlined, color: AppColor.primary),
        title: Text(
          filename,
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.neutral),
        ),
        onTap: () async {
          final navigator = Navigator.of(context);
          final productVm = context.read<ProductViewModel>();
          final saleVm = context.read<SaleViewModel>();
          final dashboardVm = context.read<DashboardViewModel>(); // 🟢 ADD THIS

          navigator.pop();
          Fluttertoast.showToast(msg: "Verifying backup file integrity...");

          try {
            final directory = await getApplicationDocumentsDirectory();
            final file = File('${directory.path}/$filename');

            if (!await file.exists()) {
              Fluttertoast.showToast(msg: "Selected backup file was not found.", backgroundColor: AppColor.error);
              return;
            }

            final String jsonContent = await file.readAsString();
            final Map<String, dynamic> decodedData = jsonDecode(jsonContent);

            await productVm.restoreProductsFromJson(decodedData['products'] as List<dynamic>);
            await saleVm.restoreSalesFromJson(decodedData['sales'] as List<dynamic>);

            // 🟢 ADD THIS: Refresh dashboard after restore
            await dashboardVm.loadDashboardData();

            Fluttertoast.showToast(
              msg: "Inventory and sales history successfully restored!",
              backgroundColor: AppColor.success,
              textColor: Colors.white,
            );
          } catch (e) {
            Fluttertoast.showToast(
              msg: "Failed to read backup: The file layout is corrupted.",
              backgroundColor: AppColor.error,
            );
          }
        },
      ),
    );
  }

  Future<void> _injectMockSalesData() async {
    if (_isInjectingMock) return;
    setState(() => _isInjectingMock = true);

    Fluttertoast.showToast(msg: "Generating 60 days of sample sales records...");

    try {
      final saleVm = context.read<SaleViewModel>();
      final dashboardVm = context.read<DashboardViewModel>(); // 🟢 ADD THIS

      await saleVm.clearAllSalesBatch();

      for (int i = 60; i >= 0; i--) {
        final timestampDate = DateTime.now().subtract(Duration(days: i));
        double simulatedRevenue = 150.0 + (i % 7 * 45.0) + (i % 30 * 12.0);

        await saleVm.addMockSaleRecord(
          totalPrice: simulatedRevenue,
          timestamp: timestampDate,
          productName: "Sample Sales Item",
        );
      }

      // 🟢 ADD THIS: Refresh dashboard after mock data injection
      await dashboardVm.loadDashboardData();

      Fluttertoast.showToast(
        msg: "Sample sales data loaded successfully!",
        backgroundColor: AppColor.success,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to generate sample data.");
    } finally {
      if (mounted) setState(() => _isInjectingMock = false);
    }
  }

  String _getDayLabel(int day) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return (day >= 0 && day < 7) ? days[day] : 'Sun';
  }

  int _getDayIndex(String day) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days.indexOf(day);
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();
    final themeVm = context.watch<ThemeViewModel>();
    final user = authVm.user;

    final bool darkThemeActive = themeVm.isDarkMode;
    final Color layoutBackground = darkThemeActive ? const Color(0xFF121212) : AppColor.background;
    final Color primaryTextColor = darkThemeActive ? Colors.white : AppColor.neutral;
    final Color secondaryTextColor = darkThemeActive ? Colors.grey.shade400 : AppColor.secondary;

    return Scaffold(
      backgroundColor: layoutBackground,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: authVm.loading || settingsVm.loading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : ListView(
        children: [
          _buildSectionHeader('Account Settings'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Profile Information',
            subtitle: user?.fullName ?? 'Not set',
            textColor: primaryTextColor,
            subColor: secondaryTextColor,
            onTap: () => _navigateToProfile(context, user),
          ),
          _buildSettingsTile(
            icon: Icons.store_outlined,
            title: 'Store Settings',
            subtitle: user?.storeName ?? 'Everest Kirana Store',
            textColor: primaryTextColor,
            subColor: secondaryTextColor,
            onTap: () => _navigateToStoreSettings(context, user),
          ),
          _buildSettingsTile(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Report an issue or suggest a new feature',
            textColor: primaryTextColor,
            subColor: secondaryTextColor,
            onTap: _launchFeedbackChannel,
          ),

          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: secondaryTextColor),
            title: Text(
              'Dark Mode Display',
              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w500, color: primaryTextColor),
            ),
            value: darkThemeActive,
            onChanged: (value) => themeVm.toggleTheme(),
            activeThumbColor: AppColor.primary,
          ),

          const Divider(),
          _buildSectionHeader('System Data Management'),
          _buildSettingsTile(
            icon: Icons.backup_outlined,
            title: 'Backup App Data',
            subtitle: 'Save a backup copy of your products and sales history',
            textColor: primaryTextColor,
            subColor: secondaryTextColor,
            onTap: _executeDataBackup,
          ),
          _buildSettingsTile(
            icon: Icons.restore_outlined,
            title: 'Restore from Backup',
            subtitle: 'Recover your products and sales records from a saved file',
            textColor: primaryTextColor,
            subColor: secondaryTextColor,
            onTap: _executeDataRestore,
          ),
          _buildSettingsTile(
            icon: Icons.cleaning_services_outlined,
            title: 'Clear Temporary Cache',
            subtitle: 'Free up storage space and resolve minor layout lag',
            textColor: primaryTextColor,
            subColor: secondaryTextColor,
            onTap: _clearAppCache,
          ),
          _buildSettingsTile(
            icon: Icons.cleaning_services,
            title: 'Reset All Store Data',
            subtitle: 'Permanently erase all inventory items and sales history',
            onTap: () => _showDeleteConfirmation(context),
            textColor: AppColor.error,
            subColor: secondaryTextColor,
          ),
          _buildSettingsTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account Permanently',
            subtitle: 'Wipe out your profile and all store records forever',
            onTap: _handleAccountDeletion,
            textColor: AppColor.error,
            subColor: secondaryTextColor,
          ),

          const Divider(),
          _buildSectionHeader('Developer Sandboxing'),
          ListTile(
            leading: Icon(_isInjectingMock ? Icons.hourglass_top : Icons.data_array, color: secondaryTextColor),
            title: Text(
              'Generate Demo Data (For Testing)',
              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w500, color: primaryTextColor),
            ),
            subtitle: Text(
              'Fill the app with 60 days of sample sales history to view charts',
              style: GoogleFonts.manrope(fontSize: 12, color: secondaryTextColor),
            ),
            trailing: _isInjectingMock
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.chevron_right, color: secondaryTextColor),
            onTap: _isInjectingMock ? null : _injectMockSalesData,
          ),

          const Divider(),
          _buildSectionHeader('Localization Configuration'),
          _buildDropdownTile(
            icon: Icons.attach_money,
            title: 'System Tracking Currency',
            value: settingsVm.currency,
            textColor: primaryTextColor,
            darkThemeActive: darkThemeActive,
            items: const ['NPR', 'USD', 'INR', 'EUR', 'GBP'],
            onChanged: (value) async {
              if (value != null) {
                await settingsVm.saveCurrency(value);
                Fluttertoast.showToast(
                  msg: "Currency updated to: $value",
                  backgroundColor: AppColor.primary,
                  textColor: Colors.white,
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.language, color: secondaryTextColor),
            title: Text(
              'App Language',
              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w500, color: primaryTextColor),
            ),
            trailing: Text(
              'English',
              style: GoogleFonts.manrope(fontSize: 14, color: secondaryTextColor),
            ),
          ),
          _buildDropdownTile(
            icon: Icons.calendar_today,
            title: 'Weekly Day-Off',
            value: _getDayLabel(settingsVm.weeklyOffDay),
            textColor: primaryTextColor,
            darkThemeActive: darkThemeActive,
            items: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
            onChanged: (value) async {
              if (value != null) {
                final day = _getDayIndex(value);
                await settingsVm.saveWeeklyOffDay(day);
                Fluttertoast.showToast(msg: 'Weekly day-off preference saved.');
              }
            },
          ),

          const Divider(),
          _buildSectionHeader('System Information'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About SmartShelf',
            subtitle: 'Version 1.0.0',
            textColor: primaryTextColor,
            subColor: secondaryTextColor,
            onTap: _showAboutDialog,
          ),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Log Out',
            subtitle: 'Securely sign out of your account on this device',
            onTap: () => _showLogoutConfirmation(context),
            textColor: AppColor.error,
            subColor: secondaryTextColor,
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
        style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.primary),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? subColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: subColor ?? AppColor.secondary),
      title: Text(
        title,
        style: GoogleFonts.manrope(color: textColor ?? AppColor.neutral, fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.manrope(fontSize: 12, color: subColor ?? AppColor.secondary),
      ),
      trailing: Icon(Icons.chevron_right, color: subColor ?? AppColor.secondary),
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required Color textColor,
    required bool darkThemeActive,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColor.secondary),
      title: Text(
        title,
        style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: darkThemeActive ? const Color(0xFF2C2C2C) : AppColor.background,
        style: GoogleFonts.manrope(fontSize: 14, color: textColor, fontWeight: FontWeight.bold),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.manrope()))).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: AppColor.primary),
      ),
    );
  }

  // 🟢 FIXED: Now properly refreshes dashboard after deletion
  void _showDeleteConfirmation(BuildContext context) {
    final navigator = Navigator.of(context);
    final productVm = context.read<ProductViewModel>();
    final saleVm = context.read<SaleViewModel>();
    final dashboardVm = context.read<DashboardViewModel>(); // 🟢 ADD THIS

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Erase All Store Data',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.error),
        ),
        content: const Text(
          'This will permanently delete all your products, current stock data, and sales history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppColor.secondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. Clear all data from repositories
              await productVm.clearAllProductsBatch();
              await saleVm.clearAllSalesBatch();

              // 2. Clear local caches (using your methods)
              productVm.clearLocalCacheData();
              saleVm.clearLocalCacheData();

              // 🟢 CRITICAL FIX: Refresh dashboard to show zero values
              await dashboardVm.loadDashboardData();

              // 3. Close dialog
              navigator.pop();

              // 4. Show confirmation
              Fluttertoast.showToast(
                msg: 'All local store data has been completely reset.',
                backgroundColor: AppColor.success,
                textColor: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete All Data', style: GoogleFonts.manrope(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🟢 FIXED: Now properly clears data before logout
  void _showLogoutConfirmation(BuildContext context) {
    final navigator = Navigator.of(context);
    final authVm = context.read<AuthViewModel>();
    final productVm = context.read<ProductViewModel>();
    final saleVm = context.read<SaleViewModel>();
    final dashboardVm = context.read<DashboardViewModel>(); // 🟢 ADD THIS

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.error),
        ),
        content: const Text('Are you sure you want to log out? This will safely clear your active session logs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppColor.secondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. Flush transient data models from application memory channels
              productVm.clearLocalCacheData();
              saleVm.clearLocalCacheData();

              // 🟢 ADD THIS: Reset dashboard before logout
              await dashboardVm.loadDashboardData();

              // 2. Clear out authentication keys
              await authVm.logout();

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Log Out', style: GoogleFonts.manrope(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile(BuildContext context, UserModel? user) {
    _nameController.text = user?.fullName ?? '';
    _emailController.text = user?.email ?? '';

    final navigator = Navigator.of(context);
    final authVm = context.read<AuthViewModel>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Profile Information',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppColor.secondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedUser = user!.copyWith(
                fullName: _nameController.text.trim(),
                email: _emailController.text.trim(),
              );
              final success = await authVm.updateProfile(updatedUser);

              if (success) {
                navigator.pop();
                Fluttertoast.showToast(msg: 'Profile updated successfully.');
              } else {
                Fluttertoast.showToast(msg: authVm.error ?? 'Failed to update profile changes.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save Changes', style: GoogleFonts.manrope(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToStoreSettings(BuildContext context, UserModel? user) {
    _storeNameController.text = user?.storeName ?? '';
    _storeAddressController.text = user?.storeAddress ?? '';

    final navigator = Navigator.of(context);
    final authVm = context.read<AuthViewModel>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Store Settings',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _storeNameController,
              decoration: InputDecoration(
                labelText: 'Store Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _storeAddressController,
              decoration: InputDecoration(
                labelText: 'Store Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppColor.secondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedUser = user!.copyWith(
                storeName: _storeNameController.text.trim(),
                storeAddress: _storeAddressController.text.trim(),
              );
              final success = await authVm.updateProfile(updatedUser);

              if (success) {
                navigator.pop();
                Fluttertoast.showToast(msg: 'Store profile updated successfully.');
              } else {
                Fluttertoast.showToast(msg: authVm.error ?? 'Failed to update store configurations.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save Config', style: GoogleFonts.manrope(color: Colors.white)),
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
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store, size: 50, color: AppColor.primary),
            const SizedBox(height: 16),
            Text(
              'SmartShelf Inventory Manager',
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.neutral),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart Inventory & Sales Ledger',
              style: GoogleFonts.manrope(color: AppColor.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '© 2026 SmartShelf. All rights reserved.',
              style: GoogleFonts.manrope(fontSize: 11, color: AppColor.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.manrope(color: AppColor.secondary)),
          ),
        ],
      ),
    );
  }
}

class CriticalProduct {
  final String name;
  final int stock;
  final int threshold;
  final String productId;
  CriticalProduct({required this.name, required this.stock, required this.threshold, required this.productId});
}

class TopProduct {
  final String name;
  final int quantity;
  final int rank;
  TopProduct({required this.name, required this.quantity, required this.rank});
}