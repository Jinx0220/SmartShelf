import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../model/user_model.dart';
import '../utils/colors.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final storeNameController = TextEditingController();
  final storeAddressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    storeNameController.dispose();
    storeAddressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
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
          icon: Icon(Icons.arrow_back_ios, color: AppColor.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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

              // Full Name
              Text(
                "Full Name",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.neutral,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: fullNameController,
                style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person_outline, color: AppColor.secondary),
                  hintText: "Enter your full name",
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),

              const SizedBox(height: 18),

              // Email
              Text(
                "Email Address",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.neutral,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined, color: AppColor.secondary),
                  hintText: "Enter your email",
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),

              const SizedBox(height: 18),

              // Store Name
              Text(
                "Store Name",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.neutral,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: storeNameController,
                style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.storefront_outlined, color: AppColor.secondary),
                  hintText: "Enter your store name",
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),

              const SizedBox(height: 18),

              // Store Address
              Text(
                "Store Address",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.neutral,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: storeAddressController,
                style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppColor.secondary),
                  hintText: "Enter your store address",
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),

              const SizedBox(height: 18),

              // Password
              Text(
                "Password",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.neutral,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline, color: AppColor.secondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColor.secondary,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                  hintText: "Create password",
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),

              const SizedBox(height: 18),

              // Confirm Password
              Text(
                "Confirm Password",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.neutral,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: confirmPasswordController,
                obscureText: hideConfirmPassword,
                style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline, color: AppColor.secondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hideConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColor.secondary,
                    ),
                    onPressed: () {
                      setState(() {
                        hideConfirmPassword = !hideConfirmPassword;
                      });
                    },
                  ),
                  hintText: "Confirm password",
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),

              const SizedBox(height: 30),

              // Create Account Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: vm.loading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColor.primary,
                  ),
                )
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () async {
                    final fullName = fullNameController.text.trim();
                    final email = emailController.text.trim();
                    final storeName = storeNameController.text.trim();
                    final storeAddress = storeAddressController.text.trim();
                    final password = passwordController.text;
                    final confirmPassword = confirmPasswordController.text;

                    if (fullName.isEmpty) {
                      Fluttertoast.showToast(
                        msg: "Please enter your full name",
                      );
                      return;
                    }

                    if (email.isEmpty || !email.contains("@")) {
                      Fluttertoast.showToast(
                        msg: "Please enter a valid email",
                      );
                      return;
                    }

                    if (storeName.isEmpty) {
                      Fluttertoast.showToast(
                        msg: "Please enter your store name",
                      );
                      return;
                    }

                    if (storeAddress.isEmpty) {
                      Fluttertoast.showToast(
                        msg: "Please enter your store address",
                      );
                      return;
                    }

                    if (password.length < 6) {
                      Fluttertoast.showToast(
                        msg: "Password must be at least 6 characters",
                      );
                      return;
                    }

                    if (password != confirmPassword) {
                      Fluttertoast.showToast(
                        msg: "Passwords do not match",
                      );
                      return;
                    }

                    final user = UserModel(
                      fullName: fullName,
                      email: email,
                      storeName: storeName,
                      storeAddress: storeAddress,
                    );

                    final success = await vm.register(
                      user: user,
                      password: password,
                    );

                    if (!mounted) return;

                    if (success) {
                      Fluttertoast.showToast(
                        msg: "Account created successfully.",
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmailVerificationScreen(
                            email: email,
                          ),
                        ),
                      );
                    } else {
                      Fluttertoast.showToast(
                        msg: vm.error ?? "Registration failed",
                      );
                    }
                  },
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
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
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

              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    vm.error!,
                    style: GoogleFonts.manrope(
                      color: AppColor.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}