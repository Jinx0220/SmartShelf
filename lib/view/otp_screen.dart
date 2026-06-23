import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'login_screen.dart';
import 'navigation_screen.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  final bool fromRegister;
  final bool isResetPassword;

  const OTPScreen({
    super.key,
    required this.phoneNumber,
    this.fromRegister = false,
    this.isResetPassword = false,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  int timerSeconds = 60;
  bool canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().clearError();
    });
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && timerSeconds > 0) {
        setState(() {
          timerSeconds--;
          _startTimer();
        });
      } else if (mounted) {
        setState(() {
          canResend = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColor.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sms_outlined,
                    size: 50,
                    color: AppColor.primary,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  widget.isResetPassword ? "Reset Password" : "Verify Your Number",
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.isResetPassword
                      ? "Enter the OTP sent to your phone to reset password"
                      : "We have sent a 6-digit verification code to",
                  style: GoogleFonts.manrope(
                    color: AppColor.secondary,
                    fontSize: 14,
                  ),
                ),
                if (!widget.isResetPassword) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.phoneNumber,
                    style: GoogleFonts.manrope(
                      color: AppColor.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 50,
                      child: TextField(
                        controller: otpControllers[index],
                        focusNode: focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColor.neutral,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColor.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                          }
                          if (value.isEmpty && index > 0) {
                            FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: vm.loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: () async {
                      String otp = otpControllers.map((c) => c.text).join();
                      if (otp.length != 6) {
                        Fluttertoast.showToast(msg: "Please enter the 6-digit OTP");
                        return;
                      }

                      bool success;
                      if (widget.isResetPassword) {
                        success = await vm.verifyOTPForReset(otp);
                        if (success && mounted) {
                          Fluttertoast.showToast(msg: "OTP Verified. Please reset your password.");
                          // Navigate to reset password screen or show dialog
                          _showResetPasswordDialog(context, vm);
                        }
                      } else {
                        success = await vm.verifyOTP(otp);
                        if (success && mounted) {
                          Fluttertoast.showToast(msg: "Verification Successful");
                          if (widget.fromRegister) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          }
                        }
                      }
                      if (!success && mounted) {
                        Fluttertoast.showToast(msg: vm.error ?? "Invalid OTP. Please try again.");
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
                      widget.isResetPassword ? "Verify & Reset" : "Verify OTP",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: GoogleFonts.manrope(
                        color: AppColor.secondary,
                        fontSize: 14,
                      ),
                    ),
                    if (!canResend)
                      Text(
                        "Resend in ${timerSeconds}s",
                        style: GoogleFonts.manrope(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    if (canResend)
                      GestureDetector(
                        onTap: () async {
                          setState(() {
                            timerSeconds = 60;
                            canResend = false;
                            _startTimer();
                          });
                          // Clear OTP fields
                          for (var controller in otpControllers) {
                            controller.clear();
                          }
                          FocusScope.of(context).requestFocus(focusNodes[0]);

                          if (widget.isResetPassword) {
                            await context.read<AuthViewModel>().sendPasswordResetOTP(widget.phoneNumber);
                          } else {
                            await context.read<AuthViewModel>().registerWithPhone(widget.phoneNumber, '', '', '');
                          }
                          Fluttertoast.showToast(msg: "OTP resent to ${widget.phoneNumber}");
                        },
                        child: Text(
                          "Resend OTP",
                          style: GoogleFonts.manrope(
                            color: AppColor.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 40),
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

  void _showResetPasswordDialog(BuildContext context, AuthViewModel vm) {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isVisible = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Reset Password",
          style: GoogleFonts.spaceGrotesk(
            color: AppColor.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: !isVisible,
              decoration: InputDecoration(
                labelText: "New Password",
                labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                suffixIcon: IconButton(
                  onPressed: () {
                    isVisible = !isVisible;
                  },
                  icon: Icon(
                    isVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: !isVisible,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.manrope(color: AppColor.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (newPassword.isEmpty || newPassword.length < 6) {
                Fluttertoast.showToast(msg: "Password must be at least 6 characters");
                return;
              }
              if (newPassword != confirmPassword) {
                Fluttertoast.showToast(msg: "Passwords do not match");
                return;
              }

              final success = await vm.resetPassword(widget.phoneNumber, newPassword);
              if (success && mounted) {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to login
                Fluttertoast.showToast(msg: "Password reset successful. Please login.");
              } else if (mounted) {
                Fluttertoast.showToast(msg: vm.error ?? "Failed to reset password");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              "Reset Password",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}