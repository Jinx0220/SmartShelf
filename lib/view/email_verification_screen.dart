// File: lib/view/email_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../utils/colors.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  bool checking = false;
  bool _isResending = false;
  String? _errorMessage;

  Future<void> checkVerification() async {
    setState(() {
      checking = true;
      _errorMessage = null;
    });

    final vm = context.read<AuthViewModel>();

    try {
      // 🟢 FIX: Check email verification status
      final verified = await vm.checkEmailVerified();

      if (!mounted) return;

      setState(() {
        checking = false;
      });

      if (verified) {
        Fluttertoast.showToast(
          msg: "✅ Email verified successfully!",
          backgroundColor: AppColor.success,
          textColor: Colors.white,
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
              (route) => false,
        );
      } else {
        // 🟢 Show more helpful message
        setState(() {
          _errorMessage = "⚠️ Your email has not been verified yet. Please check your inbox and click the verification link. If you don't see it, check your spam folder.";
        });

        Fluttertoast.showToast(
          msg: "Email not verified yet. Please check your inbox.",
          backgroundColor: AppColor.warning,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      setState(() {
        checking = false;
        _errorMessage = "Error checking verification: ${e.toString()}";
      });
    }
  }

  Future<void> resendEmail() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final vm = context.read<AuthViewModel>();

    try {
      await vm.resendVerificationEmail();

      if (!mounted) return;

      Fluttertoast.showToast(
        msg: "📧 Verification email sent successfully! Please check your inbox.",
        backgroundColor: AppColor.success,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );

      // 🟢 Show a helpful message
      setState(() {
        _errorMessage = "✅ A new verification link has been sent to ${widget.email}. Please check your inbox (and spam folder).";
      });
    } catch (e) {
      if (!mounted) return;

      String errorMsg = e.toString().replaceFirst("Exception: ", "");

      // 🟢 Check for rate limit
      if (errorMsg.contains("too-many-requests")) {
        errorMsg = "⚠️ Too many resend attempts. Please wait 5-10 minutes and try again.";
      } else if (errorMsg.contains("user-not-found")) {
        errorMsg = "⚠️ User not found. Please register again.";
      }

      Fluttertoast.showToast(
        msg: errorMsg,
        backgroundColor: AppColor.error,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );

      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 80,
                      color: AppColor.primary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    "Verify Your Email",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "A verification link has been sent to:",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: AppColor.secondary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColor.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🟢 ERROR / INFO MESSAGE
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _errorMessage!.contains('✅')
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _errorMessage!.contains('✅')
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _errorMessage!.contains('✅')
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: _errorMessage!.contains('✅')
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: _errorMessage!.contains('✅')
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                            child: Icon(
                              Icons.close,
                              color: _errorMessage!.contains('✅')
                                  ? Colors.green
                                  : Colors.red,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      "Open your email inbox and click the verification link.\n\nAfter verifying your email, return here and tap the button below.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppColor.secondary,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Check Verification Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: checking ? null : checkVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                      child: checking
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                          : Text(
                        "I've Verified My Email",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Resend Button
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton(
                      onPressed: _isResending ? null : resendEmail,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColor.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isResending
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColor.primary,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        "Resend Verification Email",
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                            (route) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      "Back to Login",
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColor.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}