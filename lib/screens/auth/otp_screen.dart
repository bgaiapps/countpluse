import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.destination,
    required this.isRegistrationFlow,
    this.name,
    this.email,
    this.phone,
  });

  final String destination;
  final bool isRegistrationFlow;
  final String? name;
  final String? email;
  final String? phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _resendCooldownSeconds = 30;
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendSecondsRemaining = _resendCooldownSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSecondsRemaining = _resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _resendSecondsRemaining = 0);
        return;
      }
      setState(() => _resendSecondsRemaining -= 1);
    });
  }

  void _clearOtpFields() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  String _friendlyOtpError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('invalid or expired otp') ||
        message.contains('otp verification failed') ||
        message.contains('invalid otp')) {
      return 'Invalid OTP';
    }
    return 'Unable to verify OTP. Please try again.';
  }

  void _submitIfComplete() {
    final isComplete = _controllers.every((c) => c.text.trim().length == 1);
    if (isComplete) {
      _verifyOtp();
    }
  }

  Future<void> _finishAuth(AuthUser user) async {
    final effectiveName = user.name.isNotEmpty ? user.name : (widget.name ?? '');
    final effectiveEmail =
        user.email.isNotEmpty ? user.email : (widget.email ?? widget.destination);
    final effectivePhone =
        user.phone.isNotEmpty ? user.phone : (widget.phone ?? '');
    await SessionService.saveSession(
      token: user.token,
      userId: user.userId,
      name: effectiveName,
      email: effectiveEmail,
      phone: effectivePhone,
    );
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter 4 digits')));
      return;
    }
    final email = (widget.email ?? widget.destination).trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing email for verification')),
      );
      return;
    }
    setState(() => _isVerifying = true);
    try {
      final user = await AuthService.verifyOtp(email: email, otp: otp);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP verified successfully')),
      );
      await _finishAuth(user);
    } catch (e) {
      if (!mounted) return;
      _clearOtpFields();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyOtpError(e))));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending || _resendSecondsRemaining > 0) return;
    final email = (widget.email ?? widget.destination).trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing email for resend')),
      );
      return;
    }

    setState(() => _isResending = true);
    try {
      if (widget.isRegistrationFlow) {
        await AuthService.register(
          name: (widget.name ?? '').trim(),
          email: email,
          phone: (widget.phone ?? '').trim(),
        );
      } else {
        await AuthService.login(email: email);
      }
      if (!mounted) return;
      _clearOtpFields();
      _startResendCooldown();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent again')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to resend OTP right now')),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text('OTP Verification', style: AppTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AppPageBackground(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter OTP', style: AppTypography.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'We sent a 4 digit code to ${widget.destination}.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 56,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineSmall,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      _submitIfComplete();
                    },
                    decoration: InputDecoration(
                      hintText: '•',
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                child: _isVerifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify OTP'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: _resendSecondsRemaining > 0
                  ? Text(
                      'Resend OTP in ${_resendSecondsRemaining}s',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : TextButton(
                      onPressed: _isResending ? null : _resendOtp,
                      child: _isResending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Resend OTP'),
                    ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
