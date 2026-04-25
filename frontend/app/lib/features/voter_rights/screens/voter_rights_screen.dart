import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/user_provider.dart';
import '../../../services/new_features_api_service.dart';
import '../../../shared/components/loaders.dart';
import '../../../shared/widgets/primary_button.dart';

class VoterRightsScreen extends ConsumerStatefulWidget {
  const VoterRightsScreen({super.key});

  @override
  ConsumerState<VoterRightsScreen> createState() => _VoterRightsScreenState();
}

class _VoterRightsScreenState extends ConsumerState<VoterRightsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _guides = [];
  List<dynamic> _helplines = [];
  late TabController _tabController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = ref.read(userProvider).value;

      final guides = await NewFeaturesApiService.getVoterRightsGuides();

      List<dynamic> helplines = [];
      if (user != null && user.firebaseUid != null) {
        final helplinesData =
            await NewFeaturesApiService.getHelplines(user.firebaseUid!);
        helplines = helplinesData['helplines'] ?? [];
      }

      setState(() {
        _guides = guides['guides'] ?? [];
        _helplines = helplines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot call $phoneNumber')),
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
        appBar: AppBar(title: const Text('Voter Rights & Help')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Could not load voter rights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your connection and try again.',
                  style: TextStyle(fontSize: 14, color: AppColors.ink3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Retry',
                  onPressed: _loadData,
                  icon: Icons.refresh,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Voter Rights & Help'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Emergency', icon: Icon(Icons.emergency)),
            Tab(text: 'Rights', icon: Icon(Icons.gavel)),
            Tab(text: 'Helplines', icon: Icon(Icons.phone)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmergencyTab(),
          _buildRightsTab(),
          _buildHelplinesTab(),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab() {
    final emergencyGuides = _guides
        .where((g) => g['category'] == 'emergency')
        .toList()
      ..sort((a, b) => (b['priority'] ?? 0).compareTo(a['priority'] ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.emergency, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'At the booth and facing an issue? Tap a scenario below for immediate help.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Common Issues',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...emergencyGuides.map((guide) => _EmergencyCard(guide: guide)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.phone_in_talk,
                  size: 40,
                  color: AppColors.orange,
                ),
                const SizedBox(height: 12),
                const Text(
                  'ECI 24/7 Helpline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1950',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Call Now',
                  onPressed: () => _makePhoneCall('1950'),
                  icon: Icons.phone,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightsTab() {
    final rightsGuides =
        _guides.where((g) => g['category'] == 'rights').toList();
    final accessibilityGuides =
        _guides.where((g) => g['category'] == 'accessibility').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Voting Rights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...rightsGuides.map((guide) => _RightsCard(guide: guide)),
          const SizedBox(height: 24),
          const Text(
            'Accessibility Rights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...accessibilityGuides.map((guide) => _RightsCard(guide: guide)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Did you know?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'You have the right to verify your vote on the VVPAT screen for 7 seconds before it drops into the sealed box.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplinesTab() {
    final primaryHelplines = _helplines
        .where((h) => h['isPrimary'] == true)
        .toList()
      ..sort((a, b) => (a['priority'] ?? 0).compareTo(b['priority'] ?? 0));
    final otherHelplines =
        _helplines.where((h) => h['isPrimary'] != true).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency Contacts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...primaryHelplines.map((helpline) => _HelplineCard(
                helpline: helpline,
                isPrimary: true,
                onCall: () => _makePhoneCall(helpline['phone']),
              )),
          const SizedBox(height: 24),
          if (otherHelplines.isNotEmpty) ...[
            const Text(
              'Other Contacts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...otherHelplines.map((helpline) => _HelplineCard(
                  helpline: helpline,
                  isPrimary: false,
                  onCall: () => _makePhoneCall(helpline['phone']),
                )),
          ],
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final Map<String, dynamic> guide;

  const _EmergencyCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    final steps = (guide['quickSteps'] as List<dynamic>?)?.length ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: '${guide['title'] ?? 'Emergency guide'}. $steps steps to resolve. Tap for details.',
        child: InkWell(
        onTap: () => _showGuideDetail(context, guide),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide['title'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(guide['quickSteps'] as List<dynamic>?)?.length ?? 0} steps to resolve',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.red,
              ),
            ],
          ),
        ), // Container
        ), // InkWell
      ), // Semantics
    );
  }

  void _showGuideDetail(BuildContext context, Map<String, dynamic> guide) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    guide['title'] ?? 'Help Guide',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Steps:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...((guide['quickSteps'] as List<dynamic>?) ?? [])
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 20),
            if (guide['content'] != null) ...[
              const Text(
                'Detailed Information:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                guide['content'],
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.ink3,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Call 1950 for Help',
              onPressed: () async {
                final uri = Uri(scheme: 'tel', path: '1950');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: Icons.phone,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _RightsCard extends StatelessWidget {
  final Map<String, dynamic> guide;

  const _RightsCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guide['title'] ?? 'Right',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            guide['content'] ?? '',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.ink3,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if ((guide['quickSteps'] as List<dynamic>?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (guide['quickSteps'] as List<dynamic>)
                  .take(3)
                  .map((step) => Chip(
                        label: Text(
                          step.toString(),
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor:
                            AppColors.orange.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _HelplineCard extends StatelessWidget {
  final Map<String, dynamic> helpline;
  final bool isPrimary;
  final VoidCallback onCall;

  const _HelplineCard({
    required this.helpline,
    required this.isPrimary,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.orange.withValues(alpha: 0.1)
            : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary
              ? AppColors.orange.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppColors.orange.withValues(alpha: 0.2)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPrimary ? Icons.phone_in_talk : Icons.phone,
              color: isPrimary ? AppColors.orange : AppColors.ink3,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  helpline['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? AppColors.orange : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  helpline['purpose'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.ink3,
                  ),
                ),
                if (helpline['phone'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    helpline['phone'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onCall,
            tooltip: 'Call ${helpline['name'] ?? 'helpline'} at ${helpline['phone'] ?? ''}',
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.phone,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
