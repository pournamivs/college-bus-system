import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

class StudentOtpVerificationDialog extends StatefulWidget {
  final String initialPhone;

  const StudentOtpVerificationDialog({super.key, required this.initialPhone});

  static Future<bool?> show(BuildContext context, {required String initialPhone}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StudentOtpVerificationDialog(initialPhone: initialPhone),
    );
  }

  @override
  State<StudentOtpVerificationDialog> createState() => _StudentOtpVerificationDialogState();
}

class _StudentOtpVerificationDialogState extends State<StudentOtpVerificationDialog> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  bool _otpSent = false;
  String? _verificationId;
  int _timerSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhone.replaceAll('+91', '').replaceAll('+', '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _timerSeconds = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatPhoneNumber(String phone) {
    phone = phone.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (phone.startsWith('+91')) return phone;
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '+91$phone';
  }

  Future<void> _sendCode() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty || rawPhone.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit phone number');
      return;
    }
    final formattedPhone = _formatPhoneNumber(rawPhone);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.message ?? 'Verification failed';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _otpSent = true;
            _verificationId = verificationId;
          });
          _startTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send OTP: $e';
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_verificationId == null) return;
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid OTP. Please try again.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification error: $e';
      });
    }
  }

  Future<void> _signInWithCredential(AuthCredential credential) async {
    try {
      // Sign in the user with Firebase (to authorize tracking backend requests)
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Save the verification flag in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isOtpVerified', true);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Return true to indicate successful verification
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification failed. Please try again.';
      });
    }
  }

  Widget _buildOTPBox(int index) {
    return Container(
      width: 40,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _otpFocusNodes[index].hasFocus ? AppColors.primary : AppColors.divider,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const Icon(Icons.security_rounded, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                "Secure Tracking",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent 
                    ? "Enter the code sent to your phone" 
                    : "Verify your phone number to track the bus.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              if (!_otpSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    prefixText: "+91 ",
                    counterText: "",
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) => _buildOTPBox(index)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _timerSeconds > 0
                          ? "Resend code in 00:${_timerSeconds.toString().padLeft(2, '0')}"
                          : "Didn't receive the code?",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    if (_timerSeconds == 0)
                      TextButton(
                        onPressed: _sendCode,
                        child: const Text("Resend"),
                      ),
                  ],
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _otpSent ? 'Verify & View Track' : 'Get OTP',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _otpSent = false;
                      for (var c in _otpControllers) { c.clear(); }
                    });
                  },
                  child: const Text("Change Phone Number"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
