import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/colors.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _storeNameController = TextEditingController(text: 'Everest Kirana Store');
  final _ownerNameController = TextEditingController(text: 'Ashish Chaudhary');
  final _phoneController = TextEditingController(text: '+977 9800000000');
  final _emailController = TextEditingController(text: 'everest@smartshelf.com');
  final _addressController = TextEditingController(text: 'Kathmandu, Nepal');
  final _gstController = TextEditingController(text: '123456789');

  bool _isEditing = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColor.darkBackground : AppColor.background,
      appBar: AppBar(
        title: Text(
          'Store Settings',
          style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
        ),
        backgroundColor: isDarkMode ? AppColor.darkSurface : Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _saveStoreSettings();
                }
                _isEditing = !_isEditing;
              });
            },
            child: Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Store Logo/Icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColor.primary, width: 2),
                ),
                child: Icon(Icons.store, size: 50, color: AppColor.primary),
              ),
            ),
            const SizedBox(height: 24),

            // Store Name
            _buildInfoField(
              label: 'Store Name',
              icon: Icons.store_outlined,
              controller: _storeNameController,
              isEditing: _isEditing,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),

            // Owner Name
            _buildInfoField(
              label: 'Owner Name',
              icon: Icons.person_outline,
              controller: _ownerNameController,
              isEditing: _isEditing,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),

            // Phone
            _buildInfoField(
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              controller: _phoneController,
              isEditing: _isEditing,
              isDarkMode: isDarkMode,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Email
            _buildInfoField(
              label: 'Email Address',
              icon: Icons.email_outlined,
              controller: _emailController,
              isEditing: _isEditing,
              isDarkMode: isDarkMode,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Address
            _buildInfoField(
              label: 'Store Address',
              icon: Icons.location_on_outlined,
              controller: _addressController,
              isEditing: _isEditing,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),

            // GST/PAN Number
            _buildInfoField(
              label: 'GST/PAN Number',
              icon: Icons.receipt_outlined,
              controller: _gstController,
              isEditing: _isEditing,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),

            // Business Hours Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColor.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Hours',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBusinessHourRow('Monday - Friday', '9:00 AM - 8:00 PM', isDarkMode),
                  _buildBusinessHourRow('Saturday', '10:00 AM - 6:00 PM', isDarkMode),
                  _buildBusinessHourRow('Sunday', 'Closed', isDarkMode),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tax Settings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColor.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tax Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTaxRow('VAT Rate', '13%', isDarkMode),
                  _buildTaxRow('Service Charge', '10%', isDarkMode),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isEditing,
    required bool isDarkMode,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColor.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditing ? AppColor.primary : (isDarkMode ? AppColor.darkBorder : AppColor.secondary.withOpacity(0.3)),
        ),
      ),
      child: TextFormField(
        controller: controller,
        enabled: isEditing,
        keyboardType: keyboardType,
        style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
          prefixIcon: Icon(icon, color: AppColor.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildBusinessHourRow(String day, String hours, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? AppColor.darkText : AppColor.neutral,
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              color: day == 'Sunday' ? AppColor.error : (isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColor.darkText : AppColor.neutral,
            ),
          ),
        ],
      ),
    );
  }

  void _saveStoreSettings() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store settings saved successfully!'),
          backgroundColor: AppColor.success,
        ),
      );
    }
  }
}