import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  int _step = 1;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorText = null;
    });

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorText = 'Please enter your registered email.';
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _errorText = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.requestPasswordOtp(
      email: email,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      setState(() {
        _step = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } else {
      setState(() {
        _errorText = result.message;
      });
    }
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorText = null;
    });

    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() {
        _errorText = 'Please enter the OTP from your email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.verifyPasswordOtp(
      email: _emailController.text.trim(),
      otp: otp,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      setState(() {
        _step = 3;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } else {
      setState(() {
        _errorText = result.message;
      });
    }
  }

  Future<void> _updatePassword() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorText = null;
    });

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorText = 'Please enter and confirm your new password.';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorText = 'Passwords do not match.';
      });
      return;
    }

    if (newPassword.length < 8) {
      setState(() {
        _errorText = 'Password must be at least 8 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.updatePassword(
      email: _emailController.text.trim(),
      newPassword: newPassword,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      Navigator.of(context).pop();
    } else {
      setState(() {
        _errorText = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                    maxWidth: 520,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RapidCareLogo(),
                        const SizedBox(height: 24),
                        Text(
                          'Forgot Password',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: const Color(0xFF0D4C9A),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _step == 1
                              ? 'Step 1 Of 3: Enter Registered Email'
                              : _step == 2
                                  ? 'Step 2 Of 3: Enter OTP From Email'
                                  : 'Step 3 Of 3: Set New Password',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFF4A4A4A),
                              ),
                        ),
                        const SizedBox(height: 34),
                        const _RequiredLabel(label: 'Registered Email'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          readOnly: _step > 1,
                          decoration: const InputDecoration(
                            hintText: 'John@example.com',
                          ),
                        ),
                        if (_step == 2) ...[
                          const SizedBox(height: 24),
                          const _RequiredLabel(label: 'OTP Code'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: 'Enter OTP',
                            ),
                          ),
                        ],
                        if (_step == 3) ...[
                          const SizedBox(height: 24),
                          const _RequiredLabel(label: 'Enter new password'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: _obscureNewPassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: '************',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF9EA3AE),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _RequiredLabel(label: 'Confirm password'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: '************',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF9EA3AE),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                        if (_errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorText!,
                            style: const TextStyle(color: Color(0xFFD32F2F)),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : _step == 1
                                    ? _requestOtp
                                    : _step == 2
                                        ? _verifyOtp
                                        : _updatePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D4C9A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _step == 1
                                        ? 'Get OTP'
                                        : _step == 2
                                            ? 'Submit'
                                            : 'Update Password',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Back To Login',
                                style: TextStyle(color: Color(0xFF0D4C9A)),
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading || _step == 3 ? null : _requestOtp,
                              child: const Text(
                                'Resend OTP',
                                style: TextStyle(color: Color(0xFF0D4C9A)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }
}

class _RapidCareLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'rapid',
                style: TextStyle(
                  color: Color(0xFF0D4C9A),
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                ),
              ),
              const TextSpan(
                text: 'Care',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'EMERGENCY SOS ASSISTANCE',
          style: TextStyle(
            color: Color(0xFF9EA3AE),
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4A4A4A),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          '*',
          style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
