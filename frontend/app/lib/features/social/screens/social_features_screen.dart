import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/user_provider.dart';
import '../../../services/new_features_api_service.dart';
import '../../../shared/components/loaders.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/components/secondary_button.dart';

class SocialFeaturesScreen extends ConsumerStatefulWidget {
  const SocialFeaturesScreen({super.key});

  @override
  ConsumerState<SocialFeaturesScreen> createState() => _SocialFeaturesScreenState();
}

class _SocialFeaturesScreenState extends ConsumerState<SocialFeaturesScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _carpools = [];
  Map<String, dynamic>? _iVotedRecord;
  Map<String, dynamic>? _communityStats;
  late TabController _tabController;

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
      if (user == null || user.firebaseUid == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get I Voted record
      final iVoted = await NewFeaturesApiService.getIVotedRecord(user.firebaseUid!);

      // Get community stats
      final constituency = user.boothName != null ? _extractConstituency(user.boothName!) : 'Delhi';
      final stats = await NewFeaturesApiService.getCommunityStats(constituency ?? 'Delhi', user.state);

      setState(() {
        _iVotedRecord = iVoted['record'];
        _communityStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _findCarpools() async {
    final user = ref.read(userProvider).value;
    if (user == null) return;
 
    final constituency = user.boothName != null ? _extractConstituency(user.boothName!) : null;
 
    setState(() => _isLoading = true);
    try {
      final carpools = await NewFeaturesApiService.findCarpools(
        user.boothName ?? '',
        constituency ?? '',
        user.state,
      );
      setState(() {
        _carpools = carpools['carpools'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _recordIVoted() async {
    final user = ref.read(userProvider).value;
    if (user == null || user.firebaseUid == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await NewFeaturesApiService.recordIVoted(
        user.firebaseUid!,
        {
          'boothName': user.boothName,
          'verifiedVia': 'voter_app',
          'sharePublicly': true,
        },
      );

      setState(() {
        _iVotedRecord = result['record'];
        _isLoading = false;
      });

      if (mounted) {
        _showBadgeDialog(result['badge']);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showBadgeDialog(Map<String, dynamic>? badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _parseColor(badge?['colors']?['bg']) ?? AppColors.orange,
                    _parseColor(badge?['colors']?['bg'])?.withOpacity(0.8) ?? AppColors.orange.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.how_to_vote,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              badge?['title'] ?? 'Proud Voter',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge?['message'] ?? 'I exercised my democratic right!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.ink3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Share with friends and inspire them to vote!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Share',
                    onPressed: () {
                      Navigator.pop(context);
                      _shareOnWhatsApp();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareOnWhatsApp() async {
    const text = 'I voted today! 🇮🇳 Exercise your democratic right. Every vote counts! #IVoted #IndiaVotes';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _offerRide() async {
    final user = ref.read(userProvider).value;
    if (user == null || user.firebaseUid == null) return;

    setState(() => _isLoading = true);
    try {
      await NewFeaturesApiService.createCarpool(
        user.firebaseUid!,
        {
          'boothName': user.boothName ?? 'Local Booth',
          'constituency': _extractConstituency(user.boothName ?? '') ?? 'Delhi',
          'state': user.state,
          'rideType': 'offer',
          'seatsAvailable': 3,
          'departureTime': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
          'notes': 'Driving to the booth. Happy to help!',
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carpool offer created successfully!')),
        );
        _findCarpools();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating carpool: $e')),
        );
      }
    }
  }

  String? _extractConstituency(String boothName) {
    final parts = boothName.split(',');
    if (parts.length >= 2) {
      return parts[parts.length - 2].trim();
    }
    return null;
  }

  Color? _parseColor(String? colorStr) {
    if (colorStr == null) return null;
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: AppLoader());
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Community & Social'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'I Voted', icon: Icon(Icons.how_to_vote)),
            Tab(text: 'Carpool', icon: Icon(Icons.directions_car)),
            Tab(text: 'Community', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIVotedTab(),
          _buildCarpoolTab(),
          _buildCommunityTab(),
        ],
      ),
    );
  }

  Widget _buildIVotedTab() {
    final hasVoted = _iVotedRecord != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (!hasVoted) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.orange,
                    AppColors.orange.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.how_to_vote,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Have you voted?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Record your vote and get your "I Voted" badge! Share it with friends and inspire them to vote.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _recordIVoted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'I Voted! 🎉',
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
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.green,
                    AppColors.green.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You Voted! 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Badge: ${_iVotedRecord?['badge']?['title'] ?? 'Proud Voter'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Voted at: ${_iVotedRecord?['formattedVoteTime'] ?? 'Today'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'View Badge',
                          onPressed: () => _showBadgeDialog(_iVotedRecord?['badge']),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Share',
                          onPressed: _shareOnWhatsApp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why share your vote?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _BenefitItem(
                  icon: Icons.trending_up,
                  text: 'Inspire friends and family to vote',
                ),
                _BenefitItem(
                  icon: Icons.group_add,
                  text: 'Increase voter turnout in your area',
                ),
                _BenefitItem(
                  icon: Icons.emoji_events,
                  text: 'Earn badges and achievements',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarpoolTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_car,
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
                        'Carpool to your booth',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share rides with fellow voters going to the same polling station. Save money and reduce traffic!',
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
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Find Carpools Near Me',
            onPressed: _findCarpools,
            icon: Icons.search,
          ),
          const SizedBox(height: 20),
          if (_carpools.isNotEmpty) ...[
            const Text(
              'Available Carpools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._carpools.map((c) => _CarpoolCard(carpool: c)),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.local_taxi,
                    size: 60,
                    color: AppColors.ink3,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No carpools found yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.ink3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to offer a ride!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.ink3.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SecondaryButton(
            label: 'Offer a Ride',
            onPressed: _offerRide,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_communityStats != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.purple,
                    AppColors.purple.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Constituency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_communityStats!['constituency'] ?? 'Unknown'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _CommunityStat(
                          value: '${_communityStats!['votedCount'] ?? 0}',
                          label: 'Voters',
                          icon: Icons.how_to_vote,
                        ),
                      ),
                      Expanded(
                        child: _CommunityStat(
                          value: '${_communityStats!['activeCarpools'] ?? 0}',
                          label: 'Carpools',
                          icon: Icons.directions_car,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_communityStats!['message'] != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: AppColors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _communityStats!['message'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 60,
                      color: AppColors.ink3,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Community stats will appear here',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your profile to see stats',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.share,
            title: 'Share Booth Location',
            subtitle: 'Send to family & friends',
            onTap: () {
              // Share booth location
            },
          ),
          _ActionCard(
            icon: Icons.group,
            title: 'Invite Friends',
            subtitle: 'Get them to download the app',
            onTap: () {
              // Invite friends
            },
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarpoolCard extends StatelessWidget {
  final Map<String, dynamic> carpool;

  const _CarpoolCard({required this.carpool});

  @override
  Widget build(BuildContext context) {
    final isOffer = carpool['rideType'] == 'offer';
    final availableSeats = carpool['seatsAvailable'] ?? 0;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOffer ? AppColors.green.withOpacity(0.2) : AppColors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOffer ? 'OFFERING RIDE' : 'NEED RIDE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOffer ? AppColors.green : AppColors.blue,
                  ),
                ),
              ),
              const Spacer(),
              if (isOffer)
                Row(
                  children: [
                    const Icon(Icons.event_seat, size: 16, color: AppColors.ink3),
                    const SizedBox(width: 4),
                    Text(
                      '$availableSeats seats',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            carpool['boothName'] ?? 'Unknown Booth',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Departure: ${carpool['formattedDepartureTime'] ?? 'TBD'}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.ink3,
            ),
          ),
          if (carpool['meetingPoint'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Meeting: ${carpool['meetingPoint']}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.ink3,
              ),
            ),
          ],
          const SizedBox(height: 12),
          PrimaryButton(
            label: isOffer ? 'Join Ride' : 'Offer Ride',
            onPressed: () {
              // Join or offer ride
            },
          ),
        ],
      ),
    );
  }
}

class _CommunityStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _CommunityStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
