import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../verification_controller.dart';

/// Aadhaar E-KYC Verification Screen
/// Government-grade identity verification using UIDAI
class AadhaarVerificationScreen extends ConsumerStatefulWidget {
  const AadhaarVerificationScreen({super.key});

  @override
  ConsumerState<AadhaarVerificationScreen> createState() =>
      _AadhaarVerificationScreenState();
}

class _AadhaarVerificationScreenState
    extends ConsumerState<AadhaarVerificationScreen> {
  final _aadhaarController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _maskedAadhaar;

  @override
  void dispose() {
    _aadhaarController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _formatAadhaar(String value) {
    // Format: XXXX XXXX XXXX
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    final parts = <String>[];
    for (var i = 0; i < cleaned.length && i < 12; i += 4) {
      parts.add(cleaned.substring(i, i + 4 > cleaned.length ? cleaned.length : i + 4));
    }
    return parts.join(' ');
  }

  Future<void> _initiateEkyc() async {
    final aadhaar = _aadhaarController.text.replaceAll(RegExp(r'\s'), '');
    
    if (aadhaar.length != 12) {
      setState(() {
        _errorMessage = 'Please enter a valid 12-digit Aadhaar number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(verificationControllerProvider.notifier)
          .initiateAadhaarEKYC(aadhaar);

      setState(() {
        _isOtpSent = true;
        _maskedAadhaar = result.maskedAadhaar;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your Aadhaar-registered mobile number'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text;
    
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(verificationControllerProvider.notifier)
          .verifyAadhaarOTP(otp);

      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aadhaar verification successful!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to next screen or close
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Aadhaar e-KYC'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: AppColors.green,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Government-Grade Verification',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                          Text(
                            'Direct integration with UIDAI',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.green.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (!_isOtpSent) ...[
                // Step 1: Enter Aadhaar
                Semantics(
                  header: true,
                  child: Text(
                  'Step 1: Enter Aadhaar Number',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your 12-digit Aadhaar number will be used for secure e-KYC verification.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.ink.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // Aadhaar input
                Semantics(
                  textField: true,
                  label: 'Aadhaar number, required. 12 digits.',
                  hint: 'Enter your 12-digit Aadhaar number in format XXXX XXXX XXXX',
                  child: TextField(
                  controller: _aadhaarController,
                  keyboardType: TextInputType.number,
                  maxLength: 14, // 12 digits + 2 spaces
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = _formatAadhaar(newValue.text);
                      return TextEditingValue(
                        text: text,
                        selection: TextSelection.collapsed(offset: text.length),
                      );
                    }),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Aadhaar Number',
                    hintText: 'XXXX XXXX XXXX',
                    prefixIcon: const Icon(Icons.credit_card),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                ), // TextField
                ), // Semantics
                const SizedBox(height: 16),

                // Privacy note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Only masked Aadhaar (XXXX-XXXX-1234) is stored. Full number is hashed for security.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Step 2: Enter OTP
                Text(
                  'Step 2: Enter OTP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit OTP sent to your Aadhaar-registered mobile number ($_maskedAadhaar).',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.ink.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // OTP input
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'OTP',
                    hintText: '000000',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),

                // Resend OTP
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isOtpSent = false;
                      _otpController.clear();
                    });
                  },
                  child: const Text('Didn\'t receive OTP? Try again'),
                ),
              ],

              const Spacer(),

              // Error message
              if (_errorMessage != null) ...[
                Semantics(
                  liveRegion: true,
                  label: 'Error: $_errorMessage',
                  child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ), // Container
                ), // Semantics
                const SizedBox(height: 16),
              ],

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_isOtpSent ? _verifyOtp : _initiateEkyc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isOtpSent ? 'Verify OTP' : 'Send OTP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
