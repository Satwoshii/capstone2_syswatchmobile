import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _otpSent = false;

  String? _errorMessage;

  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _isAllowedEmail(String value) {
    final email = value.trim().toLowerCase();

    final regex = RegExp(
      r'^[A-Za-z0-9._%+-]+@(gmail\.com|students\.nu-clark\.edu\.ph)$',
    );

    return regex.hasMatch(email);
  }

  void _startResendTimer(int seconds) {
    _resendTimer?.cancel();

    setState(() {
      _resendSeconds = seconds;
    });

    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_resendSeconds <= 1) {
          timer.cancel();

          setState(() {
            _resendSeconds = 0;
          });

          return;
        }

        setState(() {
          _resendSeconds--;
        });
      },
    );
  }

  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();

      final result = await ApiService.instance.requestOtp(email);

      if (!mounted) return;

      _emailController.text = result.email;
      _otpController.clear();

      setState(() {
        _otpSent = true;
      });

      _startResendTimer(result.resendAfterSeconds);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification code sent to ${result.email}',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
      });

      if (e.retryAfterSeconds != null &&
          e.retryAfterSeconds! > 0) {
        _startResendTimer(e.retryAfterSeconds!);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = await ApiService.instance.verifyOtp(
        email: _emailController.text.trim().toLowerCase(),
        code: _otpController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            user: user,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _changeEmail() {
    _resendTimer?.cancel();

    setState(() {
      _otpSent = false;
      _errorMessage = null;
      _resendSeconds = 0;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 64,
                        color: Color(0xFF25262B),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Syswatch Mobile Reporter',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        _otpSent
                            ? 'Enter the 6-digit verification code sent to your email.'
                            : 'Enter your NU Clark student email or Gmail address. Syswatch will send a one-time verification code.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(height: 26),

                      Form(
                        key: _emailFormKey,
                        child: TextFormField(
                          controller: _emailController,
                          enabled: !_otpSent && !_loading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [
                            AutofillHints.email,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Email address',
                            hintText:
                            'name@students.nu-clark.edu.ph',
                            prefixIcon: const Icon(
                              Icons.alternate_email,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            final email = (value ?? '').trim();

                            if (email.isEmpty) {
                              return 'Enter your email address.';
                            }

                            if (!_isAllowedEmail(email)) {
                              return 'Use your NU Clark student email or Gmail address.';
                            }

                            return null;
                          },
                          onFieldSubmitted: (_) {
                            if (!_otpSent && !_loading) {
                              _sendOtp();
                            }
                          },
                        ),
                      ),

                      if (!_otpSent) ...[
                        const SizedBox(height: 16),

                        SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _loading ? null : _sendOtp,
                            icon: const Icon(
                              Icons.send_outlined,
                            ),
                            label: const Text(
                              'Send OTP',
                            ),
                          ),
                        ),
                      ],

                      if (_otpSent) ...[
                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                            _loading ? null : _changeEmail,
                            child: const Text(
                              'Change Email',
                            ),
                          ),
                        ),

                        Form(
                          key: _otpFormKey,
                          child: TextFormField(
                            controller: _otpController,
                            enabled: !_loading,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 27,
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Verification code',
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              final otp = (value ?? '').trim();

                              if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                                return 'Enter the 6-digit OTP.';
                              }

                              return null;
                            },
                            onFieldSubmitted: (_) {
                              if (!_loading) {
                                _verifyOtp();
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            onPressed:
                            _loading ? null : _verifyOtp,
                            icon: const Icon(
                              Icons.verified_user_outlined,
                            ),
                            label: const Text(
                              'Verify OTP',
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        TextButton(
                          onPressed:
                          _loading || _resendSeconds > 0
                              ? null
                              : _sendOtp,
                          child: Text(
                            _resendSeconds > 0
                                ? 'Resend OTP in $_resendSeconds seconds'
                                : 'Resend OTP',
                          ),
                        ),
                      ],

                      if (_loading) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),

                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      const Text(
                        'Syswatch only asks for your email address and verification code. It never asks for your email password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}