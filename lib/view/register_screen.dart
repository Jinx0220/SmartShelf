// File: lib/view/register_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../model/user_model.dart';
import '../utils/colors.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final storeNameController = TextEditingController();
  final storeAddressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  // 🟢 ADD: Local error state
  String? _localError;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<AuthViewModel>();

    // 🟢 Clear previous errors
    setState(() {
      _localError = null;
    });

    final user = UserModel(
      fullName: fullNameController.text.trim(),
      email: emailController.text.trim(),
      storeName: storeNameController.text.trim(),
      storeAddress: storeAddressController.text.trim(),
    );

    final success = await vm.register(
      user: user,
      password: passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // 1. Show success message first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // 2. WAIT for the user to see it
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // 3. Navigate
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: emailController.text.trim(),
          ),
        ),
      );
    } else {
      // 🟢 FIX: Get error from ViewModel
      String errorMsg = vm.error ?? "Registration failed";

      // 🟢 Check for "too-many-requests" error
      if (errorMsg.contains("too-many-requests") ||
          errorMsg.contains("blocked all requests") ||
          errorMsg.contains("unusual activity")) {
        errorMsg = "⚠️ Too many attempts from this device. Please wait 10-15 minutes and try again, or switch to mobile data.";
      }

      // 🟢 Set local error for banner
      setState(() {
        _localError = errorMsg;
      });

      // Show the actual error from the Repo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.background,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColor.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "Create Account",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "Create your SmartShelf account",
                    style: GoogleFonts.manrope(
                      color: AppColor.secondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // 🟢 ADD: Error Banner
                if (_localError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _localError!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _localError = null;
                              });
                            },
                            child: const Icon(Icons.close, color: Colors.red, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Full Name
                _buildLabel("Full Name"),
                TextFormField(
                  controller: fullNameController,
                  style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
                  decoration: _buildInputDecoration("Enter your full name", Icons.person_outline),
                  validator: (value) => value == null || value.trim().isEmpty ? "Please enter your full name" : null,
                ),
                const SizedBox(height: 18),

                // Email
                _buildLabel("Email Address"),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
                  decoration: _buildInputDecoration("Enter your email", Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return "Please enter your email";
                    if (!value.contains("@")) return "Please enter a valid email";
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Store Name
                _buildLabel("Store Name"),
                TextFormField(
                  controller: storeNameController,
                  style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
                  decoration: _buildInputDecoration("Enter your store name", Icons.storefront_outlined),
                  validator: (value) => value == null || value.trim().isEmpty ? "Please enter your store name" : null,
                ),
                const SizedBox(height: 18),

                // Store Address
                _buildLabel("Store Address"),
                TextFormField(
                  controller: storeAddressController,
                  style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
                  decoration: _buildInputDecoration("Enter your store address", Icons.location_on_outlined),
                  validator: (value) => value == null || value.trim().isEmpty ? "Please enter your store address" : null,
                ),
                const SizedBox(height: 18),

                // Password
                _buildLabel("Password"),
                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
                  decoration: _buildInputDecoration("Create password", Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility : Icons.visibility_off,
                        color: AppColor.secondary,
                      ),
                      onPressed: () => setState(() => hidePassword = !hidePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter a password";
                    if (value.length < 6) return "Password must be at least 6 characters";
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Confirm Password
                _buildLabel("Confirm Password"),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: hideConfirmPassword,
                  style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
                  decoration: _buildInputDecoration("Confirm password", Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        hideConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: AppColor.secondary,
                      ),
                      onPressed: () => setState(() => hideConfirmPassword = !hideConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value != passwordController.text) return "Passwords do not match";
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: vm.loading
                      ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _handleRegister,
                    child: Text(
                      "Create Account",
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        color: AppColor.secondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Sign In",
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                // 🟢 Keep this for ViewModel error display (as backup)
                if (vm.error != null && _localError == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text(
                        vm.error!,
                        style: GoogleFonts.manrope(color: AppColor.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColor.neutral,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColor.secondary),
      hintText: hint,
      hintStyle: GoogleFonts.manrope(color: AppColor.secondary),
      filled: true,
      fillColor: Colors.grey.shade100,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColor.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColor.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColor.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}