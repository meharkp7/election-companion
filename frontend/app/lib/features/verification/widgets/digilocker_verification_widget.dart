import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/accessibility_utils.dart';
import '../../../providers/user_provider.dart';
import '../../../services/digilocker_service.dart';
import '../../../shared/widgets/accessible_widgets.dart';

/// DigiLocker verification widget for secure eAadhaar verification
class DigiLockerVerificationWidget extends ConsumerStatefulWidget {
  final VoidCallback? onVerified;

  const DigiLockerVerificationWidget({
    super.key,
    this.onVerified,
  });

  @override
  ConsumerState<DigiLockerVerificationWidget> createState() =>
      _DigiLockerVerificationWidgetState();
}

class _DigiLockerVerificationWidgetState
    extends ConsumerState<DigiLockerVerificationWidget> {
  bool _isLoading = false;
  bool _isLinked = false;
  Map<String, dynamic>? _eaadhaarData;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final user = ref.read(userProvider).value;
    if (user?.firebaseUid == null) return;

    setState(() => _isLoading = true);

    final status = await DigiLockerService.getStatus(user!.firebaseUid!);

    if (mounted) {
      setState(() {
        _isLinked = status['linked'] == true;
        _isLoading = false;
      });

      if (_isLinked) {
        _fetchEAadhaar();
      }
    }
  }

  Future<void> _initiateDigiLockerAuth() async {
    final user = ref.read(userProvider).value;
    if (user?.firebaseUid == null) return;

    setState(() => _isLoading = true);

    final result = await DigiLockerService.initiateAuth(user!.firebaseUid!);

    if (result['success'] == true) {
      final launched = await DigiLockerService.launchDigiLockerAuth(
        result['authUrl'],
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open DigiLocker. Please try again.'),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to initiate DigiLocker')),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEAadhaar() async {
    final user = ref.read(userProvider).value;
    if (user?.firebaseUid == null) return;

    setState(() => _isLoading = true);

    final eaadhaar = await DigiLockerService.getEAadhaar(user!.firebaseUid!);

    if (mounted) {
      setState(() {
        _eaadhaarData = eaadhaar;
        _isLoading = false;
      });

      if (eaadhaar['available'] == true) {
        widget.onVerified?.call();
        AccessibilityUtils.announceToScreenReader(
          context,
          'Successfully verified with DigiLocker eAadhaar',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      label: 'DigiLocker Verification',
      backgroundColor: AppColors.blue.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: AppColors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verify with DigiLocker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Secure eAadhaar verification via Government DigiLocker',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_eaadhaarData?['available'] == true)
            _buildVerifiedState()
          else if (_isLinked)
            _buildLinkedState()
          else
            _buildUnlinkedState(),
        ],
      ),
    );
  }

  Widget _buildUnlinkedState() {
    return Column(
      children: [
        const AccessibleAlert(
          message: 'Link your DigiLocker account to automatically verify your identity using eAadhaar',
          type: AlertType.info,
        ),
        const SizedBox(height: 12),
        AccessibleButton(
          label: 'Link DigiLocker',
          semanticLabel: 'Link DigiLocker account for verification',
          hint: 'Opens DigiLocker app or website for secure authentication',
          icon: Icons.link,
          onPressed: _initiateDigiLockerAuth,
        ),
      ],
    );
  }

  Widget _buildLinkedState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DigiLocker linked successfully',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_eaadhaarData == null)
          AccessibleButton(
            label: 'Fetch eAadhaar',
            semanticLabel: 'Fetch eAadhaar from DigiLocker',
            icon: Icons.download,
            onPressed: _fetchEAadhaar,
          )
        else
          const Text(
            'eAadhaar not available in your DigiLocker',
            style: TextStyle(color: Colors.orange),
          ),
      ],
    );
  }

  Widget _buildVerifiedState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: AppColors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Identity Verified',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Via DigiLocker eAadhaar',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_eaadhaarData?['name'] != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                _buildInfoRow('Name', _eaadhaarData!['name'] ?? 'N/A'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.ink3,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
