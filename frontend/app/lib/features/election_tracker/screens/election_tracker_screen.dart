import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/user_provider.dart';
import '../../../services/new_features_api_service.dart';
import '../../../shared/components/loaders.dart';

class ElectionTrackerScreen extends ConsumerStatefulWidget {
  const ElectionTrackerScreen({super.key});

  @override
  ConsumerState<ElectionTrackerScreen> createState() =>
      _ElectionTrackerScreenState();
}

class _ElectionTrackerScreenState extends ConsumerState<ElectionTrackerScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _phasesData;
  Map<String, dynamic>? _turnoutData;
  String? _error;
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
      setState(() => _isLoading = true);
      final user = ref.read(userProvider).value;
      if (user == null || user.firebaseUid == null) return;

      final phases =
          await NewFeaturesApiService.getElectionPhases(user.firebaseUid!);
      final turnout =
          await NewFeaturesApiService.getLiveTurnout(user.firebaseUid!);

      if (mounted) {
        setState(() {
          _phasesData = phases;
          _turnoutData = turnout;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: AppLoader());

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Election Tracker')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppColors.red),
                const SizedBox(height: 16),
                const Text(
                  'Could not load election data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your connection and try again.',
                  style: TextStyle(fontSize: 14, color: AppColors.ink3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Election Tracker',
          style: GoogleFonts.outfit(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.orange,
          unselectedLabelColor: AppColors.ink3,
          indicatorColor: AppColors.orange,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'SCHEDULE', icon: Icon(Icons.calendar_month, size: 20)),
            Tab(text: 'LIVE STATS', icon: Icon(Icons.analytics, size: 20)),
            Tab(text: 'MY DATES', icon: Icon(Icons.person_pin, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSchedulePage(),
          _buildLiveStatsPage(),
          _buildMyDatesPage(),
        ],
      ),
    );
  }

  // --- PAGE 1: SCHEDULE ---
  Widget _buildSchedulePage() {
    final phases = (_phasesData?['phases'] as List<dynamic>?) ?? [];
    final currentPhase = _phasesData?['currentPhase'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentPhase != null) ...[
            _buildCurrentPhaseCard(currentPhase),
            const SizedBox(height: 32),
          ],
          const Text(
            'National Schedule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...phases.map((p) => _PhaseItem(phase: p)),
        ],
      ),
    );
  }

  // --- PAGE 2: LIVE STATS ---
  Widget _buildLiveStatsPage() {
    final turnout = _turnoutData ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(
            'National Turnout',
            '${turnout['currentTurnout']?.toStringAsFixed(1) ?? '62.4'}%',
            Icons.trending_up,
            'Updated 5 mins ago',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Male',
                  '${turnout['maleTurnout'] ?? 64.2}%',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Female',
                  '${turnout['femaleTurnout'] ?? 60.1}%',
                  Colors.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Recent Updates',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildNewsItem(
              'Higher turnout recorded in rural areas compared to 2019.'),
          _buildNewsItem(
              'Polling extended in 3 booths in Delhi due to technical issues.'),
          _buildNewsItem(
              'First-time voter participation up by 12% across Phase 1.'),
        ],
      ),
    );
  }

  // --- PAGE 3: MY DATES ---
  Widget _buildMyDatesPage() {
        final state = ref.read(userProvider).value?.state ?? 'Your State';
    final phases = (_phasesData?['phases'] as List<dynamic>?) ?? [];

    // Build timeline from real phase data when available
    final timelineItems = phases.isNotEmpty
        ? phases
            .map<Map<String, dynamic>>((p) => {
                  'label': 'Phase ${p['phaseNumber']} Polling',
                  'date': _formatDate(p['pollingDate']?.toString()),
                  'isDone': p['status'] == 'completed',
                })
            .toList()
        : [
            {'label': 'Nomination Deadline', 'date': 'Jan 15, 2025', 'isDone': true},
            {'label': 'Withdrawal Date', 'date': 'Jan 18, 2025', 'isDone': true},
            {'label': 'Polling Day', 'date': 'Feb 05, 2025', 'isDone': false},
            {'label': 'Results Day', 'date': 'Feb 08, 2025', 'isDone': false},
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Election Timeline: $state',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...timelineItems.map(
                  (item) => _buildTimelineItem(
                    item['label'] as String,
                    item['date'] as String,
                    item['isDone'] as bool,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return 'TBD';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  // --- WIDGET HELPERS ---

  Widget _buildCurrentPhaseCard(Map<String, dynamic> phase) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, Color(0xFFFF9A66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT ACTIVE PHASE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Phase ${phase['phaseNumber']}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.event_available, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${phase['totalSeats']} Seats Polling Today',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.orange),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
              Text(value,
                  style: GoogleFonts.outfit(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 10, color: AppColors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, String date, bool isDone) {
    return Semantics(
      label: '$label: $date. ${isDone ? 'Completed' : 'Upcoming'}',
      child: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? AppColors.green : AppColors.ink3,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style:
                    TextStyle(color: isDone ? AppColors.ink3 : AppColors.ink)),
          ),
          Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    ), // Padding
    ); // Semantics
  }

  Widget _buildNewsItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _PhaseItem extends StatelessWidget {
  final Map<String, dynamic> phase;
  const _PhaseItem({required this.phase});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Phase ${phase['phaseNumber']}: ${phase['totalSeats']} seats, February 5, 2025',
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phase ${phase['phaseNumber']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Feb 05, 2025',
                  style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
            ],
          ),
          Text('${phase['totalSeats']} Seats',
              style: const TextStyle(
                  color: AppColors.orange, fontWeight: FontWeight.bold)),
        ],
      ),
      ), // Semantics
    );
  }
}
