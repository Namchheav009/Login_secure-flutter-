import 'dart:ui';
import 'package:flutter/material.dart';
import 'GetOTP.dart';
import 'database/app_db.dart';
import 'models/otp_service.dart';
import 'widgets/custom_alert.dart';

class ResetPw extends StatefulWidget {
  const ResetPw({super.key});

  @override
  State<ResetPw> createState() => _ResetPwState();
}

class _ResetPwState extends State<ResetPw> {
  final emailController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  Future<void> _sendResetCode() async {
    final email = emailController.text.trim();

    // 🔴 EMPTY EMAIL
    if (email.isEmpty) {
      CustomAlert.show(
        context: context,
        type: AlertType.warning,
        title: 'Warning',
        message: 'Please enter your email address',
      );
      return;
    }

    // 🔴 INVALID EMAIL
    if (!_isValidEmail(email)) {
      CustomAlert.show(
        context: context,
        type: AlertType.error,
        title: 'Invalid Email',
        message: 'Please enter a valid email format',
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = await AppDB.instance.getUserByEmail(email);

      if (!mounted) return;
      setState(() => loading = false);

      // 🔴 EMAIL NOT FOUND
      if (user == null) {
        CustomAlert.show(
          context: context,
          type: AlertType.error,
          title: 'Oops...',
          message: 'Email not found in our system',
        );
        return;
      }

      // ✅ SEND OTP
      await OtpService.sendOtp(email);

      if (!mounted) return;

      // ✅ SUCCESS ALERT
      CustomAlert.show(
        context: context,
        type: AlertType.success,
        title: 'Success',
        message: 'OTP sent successfully. Check your email!',
        onOk: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerificationCodeScreen(email: email),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);

      CustomAlert.show(
        context: context,
        type: AlertType.error,
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),

                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.25),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Enter your email and we'll send you an OTP code.",
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),

                  const SizedBox(height: 50),

                  // Glass Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Address',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: emailController,
                              enabled: !loading,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.white,
                                ),
                                hintText: 'Enter your email',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: loading ? null : _sendResetCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            )
                          : const Text(
                              'SEND RESET CODE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Color.fromARGB(255, 247, 203, 81),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
