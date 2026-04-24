import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/user_provider.dart';
import '../../../services/new_features_api_service.dart';
import '../../../shared/components/loaders.dart';
import '../../../shared/widgets/primary_button.dart';

class PollingDayKitScreen extends ConsumerStatefulWidget {
  const PollingDayKitScreen({super.key});

  @override
  ConsumerState<PollingDayKitScreen> createState() => _PollingDayKitScreenState();
}

class _PollingDayKitScreenState extends ConsumerState<PollingDayKitScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _checklistData;
  Map<String, dynamic>? _slipData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = ref.read(userProvider).value;
      if (user == null || user.firebaseUid == null) return;

      final checklist =
          await NewFeaturesApiService.getChecklist(user.firebaseUid!);
      final slip = await NewFeaturesApiService.getVoterSlip(user.firebaseUid!);

      setState(() {
        _checklistData = checklist['checklist'];
        _slipData = slip['slip'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateChecklistItem(String key, bool value) async {
    try {
      final user = ref.read(userProvider).value;
      if (user == null || user.firebaseUid == null) return;

      // Optimistic update
      setState(() {
        _checklistData ??= {};
        _checklistData![key] = value;
      });

      await NewFeaturesApiService.updateChecklist(
          user.firebaseUid!, {key: value});
    } catch (e) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating checklist: $e')),
        );
      }
    }
  }

  void _showPanicButtonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What issue are you facing?'),
            const SizedBox(height: 16),
            _PanicOption(
              icon: Icons.people_outline,
              label: 'Booth Crowding',
              onTap: () => _triggerPanic('crowding'),
            ),
            _PanicOption(
              icon: Icons.security,
              label: 'Safety Concern',
              onTap: () => _triggerPanic('safety'),
            ),
            _PanicOption(
              icon: Icons.electrical_services,
              label: 'EVM Issue',
              onTap: () => _triggerPanic('evm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerPanic(String reason) async {
    Navigator.pop(context);
    try {
      final user = ref.read(userProvider).value;
      await NewFeaturesApiService.triggerPanicButton(user!.firebaseUid!, reason, null);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Help is on the way'),
            content: Text(
                'Your report for $reason has been logged. Election officials and nearby volunteers have been notified.'),
            actions: [
              PrimaryButton(
                label: 'Got it',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: AppLoader());
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $_error')),
      );
    }

    final checklist = _checklistData ?? {};
    
    // Calculate completion percentage locally for better responsiveness
    final items = [
      checklist['hasEpic'] ?? false,
      checklist['hasPhotoId'] ?? false,
      checklist['hasVoterSlip'] ?? false,
      checklist['phoneCharged'] ?? false,
      checklist['knowsBoothLocation'] ?? false,
      checklist['checkedDocumentsNightBefore'] ?? false,
    ];
    final completedCount = items.where((item) => item == true).length;
    final completion = ((completedCount / items.length) * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Polling Day Kit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency, color: Colors.red),
            onPressed: _showPanicButtonDialog,
            tooltip: 'Emergency Help',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: completion == 100
                                ? AppColors.green.withOpacity(0.15)
                                : AppColors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            completion == 100
                                ? Icons.check_circle
                                : Icons.checklist,
                            color: completion == 100
                                ? AppColors.green
                                : AppColors.orange,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                completion == 100
                                    ? 'All Set!'
                                    : 'Preparation Checklist',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$completion% complete',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: completion / 100,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completion == 100 ? AppColors.green : AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Checklist Items
              const Text(
                'Your Checklist',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _ChecklistItem(
                icon: Icons.badge_outlined,
                title: 'Voter ID Ready',
                subtitle: 'EPIC card or alternative ID prepared',
                isChecked: checklist['hasEpic'] ?? false,
                onToggle: (v) => _updateChecklistItem('hasEpic', v),
              ),
              _ChecklistItem(
                icon: Icons.description_outlined,
                title: 'Documents Ready',
                subtitle: 'All required documents collected',
                isChecked: checklist['hasPhotoId'] ?? false,
                onToggle: (v) => _updateChecklistItem('hasPhotoId', v),
              ),
              _ChecklistItem(
                icon: Icons.confirmation_number_outlined,
                title: 'Voter Slip',
                subtitle: 'Downloaded or printed voter slip',
                isChecked: checklist['hasVoterSlip'] ?? false,
                onToggle: (v) => _updateChecklistItem('hasVoterSlip', v),
              ),
              _ChecklistItem(
                icon: Icons.battery_charging_full,
                title: 'Phone Charged',
                subtitle: 'Power bank and cable ready',
                isChecked: checklist['phoneCharged'] ?? false,
                onToggle: (v) => _updateChecklistItem('phoneCharged', v),
              ),
              _ChecklistItem(
                icon: Icons.location_on_outlined,
                title: 'Booth Located',
                subtitle: 'Route to polling station confirmed',
                isChecked: checklist['knowsBoothLocation'] ?? false,
                onToggle: (v) => _updateChecklistItem('knowsBoothLocation', v),
              ),
              _ChecklistItem(
                icon: Icons.nightlight_outlined,
                title: 'Night Before Check',
                subtitle: 'Final verification performed',
                isChecked: checklist['checkedDocumentsNightBefore'] ?? false,
                onToggle: (v) =>
                    _updateChecklistItem('checkedDocumentsNightBefore', v),
              ),

              const SizedBox(height: 24),

              // Voter Slip Card
              if (_slipData != null) ...[
                const Text(
                  'Your Voter Slip',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _SlipInfoRow(
                        label: 'Voter Name',
                        value: _slipData!['voterName'] ?? 'Loading...',
                      ),
                      _SlipInfoRow(
                        label: 'EPIC Number',
                        value: _slipData!['epicNumber'] ?? 'Loading...',
                      ),
                      _SlipInfoRow(
                        label: 'Booth',
                        value: _slipData!['pollingStationName'] ?? 'Loading...',
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      TextButton.icon(
                        onPressed: () {
                          // Show full slip
                        },
                        icon: const Icon(Icons.qr_code, color: Colors.white),
                        label: const Text(
                          'View Full Digital Slip',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Panic Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'Facing issues at the booth?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Quickly report issues to officials or get emergency help.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _showPanicButtonDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Get Emergency Help',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isChecked;
  final ValueChanged<bool> onToggle;

  const _ChecklistItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onToggle(!isChecked),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                isChecked ? AppColors.green.withOpacity(0.1) : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isChecked
                  ? AppColors.green.withOpacity(0.3)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isChecked
                      ? AppColors.green.withOpacity(0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isChecked ? AppColors.green : AppColors.ink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isChecked ? AppColors.green : AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isChecked,
                onChanged: (v) => onToggle(v ?? false),
                activeColor: AppColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlipInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SlipInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanicOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PanicOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(label),
      onTap: onTap,
    );
  }
}
