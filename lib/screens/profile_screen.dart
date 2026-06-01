import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @overridet
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController(text: 'Ashish Chaudhary');
  final _emailController = TextEditingController(text: 'ashish@smartshelf.com');
  final _phoneController = TextEditingController(text: '+977 9800000000');
  final _addressController = TextEditingController(text: 'Kathmandu, Nepal');

  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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
          'Profile Information',
          style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
        ),
        backgroundColor: isDarkMode ? AppColor.darkSurface : Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  // Save changes
                  _saveProfile();
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
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColor.primary, width: 3),
                    ),
                    child: const CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.transparent,
                      child: Icon(Icons.person, size: 50, color: AppColor.primary),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name
            _buildInfoField(
              label: 'Full Name',
              icon: Icons.person_outline,
              controller: _nameController,
              isEditing: _isEditing,
              isDarkMode: isDarkMode,
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

            // Address
            _buildInfoField(
              label: 'Address',
              icon: Icons.location_on_outlined,
              controller: _addressController,
              isEditing: _isEditing,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),

            // Stats Section
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
                    'Account Statistics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Member Since', 'January 2024', isDarkMode),
                  _buildStatRow('Total Sales', 'NPR 45,230', isDarkMode),
                  _buildStatRow('Products Sold', '342 units', isDarkMode),
                  _buildStatRow('Orders Placed', '28', isDarkMode),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Change Password Button
            if (!_isEditing)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showChangePasswordDialog(context, isDarkMode),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Change Password'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppColor.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
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

  Widget _buildStatRow(String label, String value, bool isDarkMode) {
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

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColor.success,
        ),
      );
    }
  }

  void _showChangePasswordDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColor.darkSurface : Colors.white,
        title: Text(
          'Change Password',
          style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
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
                const SnackBar(content: Text('Password changed successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}