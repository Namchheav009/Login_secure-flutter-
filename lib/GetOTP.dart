import 'dart:ui';
import 'package:flutter/material.dart';
import 'models/otp_service.dart';
import 'forgot.dart';
import 'widgets/custom_alert.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String email;
  const VerificationCodeScreen({super.key, required this.email});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final otpController = TextEditingController();
  bool verifying = false;
  bool resending = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = otpController.text.trim();

    // ⚠ EMPTY OTP
    if (otp.isEmpty) {
      CustomAlert.show(
        context: context,
        type: AlertType.warning,
        title: 'Warning',
        message: 'Please enter the OTP code',
      );
      return;
    }

    setState(() => verifying = true);

    final ok = await OtpService.verifyOtp(widget.email, otp);

    if (!mounted) return;
    setState(() => verifying = false);

    if (ok) {
      // ✅ SUCCESS
      CustomAlert.show(
        context: context,
        type: AlertType.success,
        title: 'Verified',
        message: 'OTP verified successfully',
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
      // ❌ INVALID OTP
      CustomAlert.show(
        context: context,
        type: AlertType.error,
        title: 'Invalid Code',
        message: 'The OTP is invalid or expired',
      );
    }
  }

  Future<void> _resend() async {
    setState(() => resending = true);

    await OtpService.sendOtp(widget.email);

    if (!mounted) return;
    setState(() => resending = false);

    CustomAlert.show(
      context: context,
      type: AlertType.info,
      title: 'OTP Sent',
      message: 'A new OTP has been sent to your email',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Background
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

                    _circleIcon(Icons.arrow_back_ios, () {
                      Navigator.pop(context);
                    }),

                    const SizedBox(height: 80),

                    const Text(
                      'Verification Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Please enter the code sent to:\n${widget.email}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: resending ? null : _resend,
                        child: Text(
                          resending ? 'Resending...' : 'Resend Code',
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                      ),
                    ),

                    // 🧊 Glass OTP Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.white.withOpacity(0.18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Enter OTP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 14),

                              TextField(
                                controller: otpController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: '6-digit code',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withOpacity(0.15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          verifying ? 'VERIFYING...' : 'VERIFY',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.25),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
