import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../../core/theme/colors.dart';
import '../../../providers/user_provider.dart';
import '../../../services/new_features_api_service.dart';
import '../../../shared/components/loaders.dart';

class ElectionResultsScreen extends ConsumerStatefulWidget {
  const ElectionResultsScreen({super.key});

  @override
  ConsumerState<ElectionResultsScreen> createState() =>
      _ElectionResultsScreenState();
}

class _ElectionResultsScreenState extends ConsumerState<ElectionResultsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _myResults;
  Map<String, dynamic>? _partyPerformance;
  Map<String, dynamic>? _turnoutAnalysis;
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final userValue = ref.read(userProvider);
      final user = userValue.value;
      if (user == null || user.firebaseUid == null) {
        setState(() => _isLoading = false);
        return;
      }

      final state = (user.state.isNotEmpty) ? user.state : 'National';

      final myResults = await NewFeaturesApiService.getMyConstituencyResults(
          user.firebaseUid!);
      final partyPerf = await NewFeaturesApiService.getPartyPerformance(state);
      final turnout = await NewFeaturesApiService.getTurnoutAnalysis(state);

      setState(() {
        _myResults = myResults;
        _partyPerformance = partyPerf;
        _turnoutAnalysis = turnout;
        _isLoading = false;
      });

      // Start periodic refresh for live simulation
      _refreshTimer ??= Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) _loadData();
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        elevation: 0,
        backgroundColor: AppColors.surface,
        title: const Text(
          'Election Results',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.orange,
          unselectedLabelColor: AppColors.ink3,
          indicatorColor: AppColors.orange,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'My Area'),
            Tab(text: 'Parties'),
            Tab(text: 'Turnout'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyResultsTab(),
          _buildPartyPerformanceTab(),
          _buildTurnoutTab(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 40,
        color: AppColors.ink,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.red,
              alignment: Alignment.center,
              child: const Text(
                'LIVE FEED',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Counting progress: Centers report steady progress... Results updated... Vote share shifting...',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyResultsTab() {
    if (_myResults == null) {
      return const Center(child: Text('No results data available'));
    }

    final status = _myResults!['status'] ?? 'unknown';
    final winner = _myResults!['winner'];
    final turnout = _myResults!['turnout'];
    final candidates = (_myResults!['candidates'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConstituencyStatusCard(status),
          const SizedBox(height: 24),
          if (winner != null) _buildWinnerCard(winner),
          const SizedBox(height: 24),
          if (turnout != null) _buildTurnoutMiniStats(turnout),
          const SizedBox(height: 32),
          Text(
            'Candidate Standings',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          ...candidates.map((c) => _CandidateCard(candidate: c)),
        ],
      ),
    );
  }

  Widget _buildConstituencyStatusCard(String status) {
    final statusColor = _getStatusColor(status);
    final progress = _myResults!['progress'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    Icon(_getStatusIcon(status), color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _myResults!['constituency'] ?? 'Your Constituency',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (progress != null)
                Text(
                  '$progress%',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
            ],
          ),
          if (status == 'counting' && progress != null) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: double.parse(progress.toString()) / 100,
                backgroundColor: statusColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Counting in progress...',
                    style: TextStyle(fontSize: 11, color: AppColors.ink3)),
                Text('LIVE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWinnerCard(Map<String, dynamic> winner) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF388E3C), Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'PROJECTED WINNER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            winner['name'] ?? 'Unknown',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            winner['party'] ?? 'Unknown Party',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (winner['marginPercentage'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${winner['marginPercentage']?.toStringAsFixed(1)}% Lead',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTurnoutMiniStats(Map<String, dynamic> turnout) {
    return Row(
      children: [
        _ResultStatBox(
          label: 'Turnout',
          value: '${turnout['percentage']?.toStringAsFixed(1)}%',
          icon: Icons.people_outline,
        ),
        const SizedBox(width: 12),
        _ResultStatBox(
          label: 'Total Votes',
          value: '${turnout['votesPolled']}',
          icon: Icons.how_to_vote_outlined,
        ),
      ],
    );
  }

  Widget _buildPartyPerformanceTab() {
    if (_partyPerformance == null) {
      return const Center(child: Text('Data not available'));
    }

    final parties = (_partyPerformance!['parties'] as List<dynamic>?) ?? [];
    final totalSeats = _partyPerformance!['totalSeats'] ?? 543;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'National Seat Share',
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '2024 General Elections',
          style: TextStyle(color: AppColors.ink3, fontSize: 14),
        ),
        const SizedBox(height: 24),
        ...parties
            .map((p) => _PartyResultCard(party: p, totalSeats: totalSeats)),
      ],
    );
  }

  Widget _buildTurnoutTab() {
    if (_turnoutAnalysis == null) {
      return const Center(child: Text('Data not available'));
    }

    final data = _turnoutAnalysis!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTurnoutHeader(data['averageTurnout']),
          const SizedBox(height: 24),
          _buildExtremeCard(
              'Highest Turnout', data['highestTurnout'], AppColors.green),
          const SizedBox(height: 12),
          _buildExtremeCard(
              'Lowest Turnout', data['lowestTurnout'], AppColors.red),
          const SizedBox(height: 24),
          _buildStatRow('Total Registered', '${data['totalRegistered']}',
              Icons.person_add_outlined),
          _buildStatRow('Total Votes Cast', '${data['totalVotesCast']}',
              Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildTurnoutHeader(dynamic avg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.blue, Color(0xFF42A5F5)],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Average State Turnout',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${avg?.toStringAsFixed(1)}%',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtremeCard(String title, dynamic data, Color color) {
    if (data == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                data['constituency'] ?? 'Unknown',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          Text(
            '${data['percentage']}%',
            style: GoogleFonts.outfit(
                fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.ink3, size: 24),
          const SizedBox(width: 16),
          Text(label,
              style: const TextStyle(fontSize: 16, color: AppColors.ink)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.green;
      case 'counting':
        return AppColors.orange;
      case 'ongoing':
        return AppColors.blue;
      default:
        return AppColors.ink3;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.verified_rounded;
      case 'counting':
        return Icons.pending_actions_rounded;
      case 'ongoing':
        return Icons.play_circle_filled_rounded;
      default:
        return Icons.help_outline;
    }
  }
}

class _ResultStatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ResultStatBox(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.ink3, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style:
                  GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(color: AppColors.ink3, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Map<String, dynamic> candidate;

  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final isLeading = candidate['status'] == 'leading';
    final isWinner = candidate['status'] == 'won' || candidate['position'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWinner
              ? AppColors.green.withOpacity(0.3)
              : AppColors.border.withOpacity(0.5),
        ),
        boxShadow: [
          if (isWinner)
            BoxShadow(
              color: AppColors.green.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isWinner ? AppColors.green : AppColors.card,
            radius: 20,
            child: Text(
              '${candidate['position']}',
              style: TextStyle(
                color: isWinner ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate['name'] ?? 'Unknown',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  candidate['party'] ?? 'Independent',
                  style: TextStyle(color: AppColors.ink3, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${candidate['voteSharePercentage']}%',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (isLeading || isWinner)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isWinner ? AppColors.green : AppColors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isWinner ? 'WINNER' : 'LEADING',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartyResultCard extends StatelessWidget {
  final Map<String, dynamic> party;
  final int totalSeats;

  const _PartyResultCard({required this.party, required this.totalSeats});

  @override
  Widget build(BuildContext context) {
    final seats = party['seats'] ?? 0;
    final progress = seats / totalSeats;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                party['name'] ?? 'Unknown',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '$seats',
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getPartyColor(party['name']),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: _getPartyColor(party['name']).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPartyColor(String? name) {
    if (name == null) return AppColors.ink3;
    if (name.contains('Bhartiya')) return Colors.orange;
    if (name.contains('Congress')) return Colors.blue;
    if (name.contains('Socialist')) return Colors.red;
    if (name.contains('Dravida')) return Colors.black;
    if (name.contains('Trinamool')) return Colors.green;
    return AppColors.purple;
  }
}
