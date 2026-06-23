import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isVisible = false;
  bool isConfirmedPasswordVisible = false;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
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
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: AppColor.primary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "Create Account",
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColor.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Sign up to start managing your inventory",
                      style: GoogleFonts.manrope(
                        color: AppColor.secondary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "Full Name",
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColor.neutral,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: fullNameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
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
                const SizedBox(height: 16),
                Text(
                  "Email Address",
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColor.neutral,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
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
                const SizedBox(height: 16),
                Text(
                  "Phone Number",
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColor.neutral,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '+977',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: AppColor.neutral,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: "Enter Your Phone Number",
                            hintStyle: GoogleFonts.manrope(color: AppColor.secondary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Password",
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColor.neutral,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: !isVisible,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isVisible = !isVisible;
                        });
                      },
                      icon: Icon(
                        isVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    hintText: "Create a password",
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
                const SizedBox(height: 16),
                Text(
                  "Confirm Password",
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColor.neutral,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !isConfirmedPasswordVisible,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isConfirmedPasswordVisible = !isConfirmedPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isConfirmedPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    hintText: "Confirm your password",
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: vm.loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: () async {
                      final fullName = fullNameController.text.trim();
                      final email = emailController.text.trim();
                      final phone = phoneController.text.trim();
                      final password = passwordController.text.trim();
                      final confirmPassword = confirmPasswordController.text.trim();

                      if (fullName.isEmpty) {
                        Fluttertoast.showToast(msg: "Please enter your full name");
                        return;
                      }
                      if (email.isEmpty || !email.contains('@')) {
                        Fluttertoast.showToast(msg: "Please enter a valid email");
                        return;
                      }
                      if (phone.isEmpty || phone.length != 10) {
                        Fluttertoast.showToast(msg: "Please enter a valid 10-digit phone number");
                        return;
                      }
                      if (password.isEmpty || password.length < 6) {
                        Fluttertoast.showToast(msg: "Password must be at least 6 characters");
                        return;
                      }
                      if (password != confirmPassword) {
                        Fluttertoast.showToast(msg: "Passwords do not match");
                        return;
                      }

                      final success = await vm.registerWithPhone(
                        phone: phone,
                        fullName: fullName,
                        email: email,
                        password: password,
                      );

                      if (success && mounted) {
                        Fluttertoast.showToast(msg: "Registration Successful! Please verify OTP.");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OTPScreen(
                              phoneNumber: phone,
                              fromRegister: true,
                              isResetPassword: false,
                            ),
                          ),
                        );
                      } else if (mounted) {
                        Fluttertoast.showToast(msg: vm.error ?? "Registration failed");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      "Sign Up",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Sign In",
                        style: GoogleFonts.manrope(
                          color: AppColor.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      vm.error!,
                      style: GoogleFonts.manrope(
                        color: AppColor.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}