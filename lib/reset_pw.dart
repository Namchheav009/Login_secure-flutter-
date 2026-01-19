import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:login_secure/sigin.dart';
import 'GetOTP.dart';
import 'models/otp_service.dart';
import 'widgets/custom_alert.dart';

class ResetPw extends StatefulWidget {
  final String email;
  const ResetPw({Key? key, required this.email}) : super(key: key);

  @override
  State<ResetPw> createState() => _ResetPwState();
}

class _ResetPwState extends State<ResetPw> {
  late TextEditingController _emailController;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      CustomAlert.show(
        context: context,
        type: AlertType.warning,
        title: 'Warning',
        message: 'Please enter your email address',
      );
      return;
    }

    if (!email.contains('@')) {
      CustomAlert.show(
        context: context,
        type: AlertType.warning,
        title: 'Invalid Email',
        message: 'Please enter a valid email address',
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await OtpService.sendOtp(email);

      if (!mounted) return;
      setState(() => _sending = false);

      CustomAlert.show(
        context: context,
        type: AlertType.success,
        title: 'OTP Sent',
        message: 'A verification code has been sent to your email.',
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerificationCodeScreen(email: email),
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _sending = false);
      CustomAlert.show(
        context: context,
        type: AlertType.error,
        title: 'Error',
        message: 'Failed to send OTP: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  IconButton(
                    onPressed: () => Navigator.push(context, 
                    MaterialPageRoute(builder:
                     (_) => const SignInScreen())),  
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Enter your email to receive a verification code',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.white,
                                ),
                                hintText: 'Email address',
                                hintStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.25),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _sending ? null : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.35,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  _sending ? 'SENDING...' : 'SEND CODE',
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
