import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:login_secure/reset_pw.dart';
import 'forgot.dart';
import 'models/otp_service.dart';

import 'widgets/custom_alert.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String email;
  const VerificationCodeScreen({super.key, required this.email});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final TextEditingController _otpCtrl = TextEditingController();

  bool verifying = false;
  bool resending = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  // ✅ VERIFY OTP CODE (NO EMAIL LINK)
  Future<void> _verify() async {
    final code = _otpCtrl.text.trim();

    if (code.length != 6) {
      CustomAlert.show(
        context: context,
        type: AlertType.warning,
        title: 'Invalid Code',
        message: 'Please enter the 6-digit code.',
      );
      return;
    }

    setState(() => verifying = true);

    final ok = await OtpService.verifyOtp(widget.email, code);

    if (!mounted) return;
    setState(() => verifying = false);

    if (ok) {
      CustomAlert.show(
        context: context,
        type: AlertType.success,
        title: 'Verified',
        message: 'OTP verified successfully!',
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(email: widget.email),
            ),
          );
        },
      );
    } else {
      CustomAlert.show(
        context: context,
        type: AlertType.error,
        title: 'Invalid OTP',
        message: 'The code is incorrect or expired.',
      );
    }
  }

  // 🔁 RESEND OTP EMAIL
  Future<void> _resend() async {
    setState(() => resending = true);

    await OtpService.sendOtp(widget.email);

    if (!mounted) return;
    setState(() => resending = false);

    CustomAlert.show(
      context: context,
      type: AlertType.info,
      title: 'OTP Sent',
      message: 'A new code has been sent to your email.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/login.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ResetPw(email:  widget.email),
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),

                    const Text(
                      'Enter Verification Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'A 6-digit code was sent to:\n${widget.email}',
                      style: const TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: resending ? null : _resend,
                      child: Text(
                        resending ? 'Resending...' : 'Resend Code',
                        style: const TextStyle(color: Colors.lightBlueAccent),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // OTP INPUT
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 6,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '------',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 6,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: verifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          verifying ? 'VERIFYING...' : 'VERIFY',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
