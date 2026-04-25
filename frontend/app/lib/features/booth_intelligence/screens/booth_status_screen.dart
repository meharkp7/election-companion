import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../providers/user_provider.dart';
import '../../../services/features_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Real-Time Booth Intelligence Screen
/// Live queue status, best time to vote, crowd-sourced updates
class BoothStatusScreen extends ConsumerStatefulWidget {
  const BoothStatusScreen({super.key});

  @override
  ConsumerState<BoothStatusScreen> createState() => _BoothStatusScreenState();
}

class _BoothStatusScreenState extends ConsumerState<BoothStatusScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _boothData;
  Map<String, dynamic>? _bestTimeData;
  String? _error;
  bool _isReporting = false;

  @override
  void initState() {
    super.initState();
    _loadBoothData();
  }

  Future<void> _loadBoothData() async {
    try {
      final user = ref.read(userProvider).value;
      final boothName = user?.boothDetails?['boothName'] ?? 'Sample Booth';
      final constituency = user?.state ?? 'Delhi';
      final state = user?.state ?? 'Delhi';

      final boothStatus = await FeaturesApiService.getBoothStatus(
        boothName,
        constituency,
        state,
      );

      final bestTime = await FeaturesApiService.getBestTimeToVote(
        boothName,
        constituency,
        state,
      );

      setState(() {
        _boothData = boothStatus;
        _bestTimeData = bestTime;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Booth Status'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBoothData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
      floatingActionButton: Semantics(
        button: true,
        label: _isReporting ? 'Submitting report, please wait' : 'Report booth status',
        child: FloatingActionButton.extended(
        onPressed: _isReporting ? null : _showReportDialog,
        icon: _isReporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.report),
        label: Text(_isReporting ? 'Submitting...' : 'Report Status'),
        backgroundColor: AppColors.orange,
      ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load booth data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadBoothData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final boothName = _boothData?['boothName'] ?? 'Your Polling Booth';
    final constituency = _boothData?['constituency'] ?? '';
    final queueLength = _boothData?['queueLength'] ?? 'unknown';
    final waitTime = _boothData?['waitTimeMinutes'];
    final crowdLevel = _boothData?['crowdLevel'] ?? 3;
    // ignore: unused_local_variable
    final facilities = _boothData?['facilities'] as Map<String, dynamic>?;
    // ignore: unused_local_variable
    final issues = _boothData?['issues'] as List<dynamic>? ?? [];
    final isPrediction = _boothData?['isPrediction'] ?? false;
    final lastUpdated = _boothData?['lastUpdated'];

    // ignore: unused_local_variable
    final recommendations =
        _bestTimeData?['recommendations'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booth Header
          Semantics(
            header: true,
            label: '$boothName, $constituency. ${isPrediction ? 'Predicted data' : 'Live data'}${lastUpdated != null ? ', updated ${_formatTimeAgo(lastUpdated)}' : ''}',
            child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.orange, AppColors.orange.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPrediction ? Icons.history : Icons.live_tv,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPrediction ? 'PREDICTED' : 'LIVE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (lastUpdated != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Updated ${_formatTimeAgo(lastUpdated)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  boothName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  constituency,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ), // Semantics header
          // ignore: extra_positional_arguments_could_be_named
          const SizedBox(height: 24),

          // Current Status Card
          Semantics(
            liveRegion: true,
            label: 'Current queue: ${_formatQueueLength(queueLength)}${waitTime != null ? '. Estimated wait: $waitTime minutes' : ''}',
            child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getQueueColor(queueLength).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getQueueColor(queueLength).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getQueueIcon(queueLength),
                      size: 48,
                      color: _getQueueColor(queueLength),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _formatQueueLength(queueLength),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getQueueColor(queueLength),
                  ),
                ),
                if (waitTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Est. wait: $waitTime min',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.ink.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildCrowdIndicator(crowdLevel),
              ],
            ),
          ), // Container
        ), // Semantics liveRegion
        const SizedBox(height: 24),

        // Best Time to Vote
        if (recommendations.isNotEmpty) ...[
          Text(
            'Best Time to Vote',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          ...recommendations
              .take(2)
              .map((rec) => _buildRecommendationCard(rec)),
          const SizedBox(height: 24),
        ],

        // Facilities Status
        if (facilities != null) ...[
          Text(
            'Facilities Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFacilityChip(
                'EVM Working',
                facilities['evmWorking'] ?? true,
                Icons.how_to_vote,
              ),
              _buildFacilityChip(
                'Water',
                facilities['waterAvailable'] ?? true,
                Icons.water_drop,
              ),
              _buildFacilityChip(
                'Seating',
                facilities['seatingAvailable'] ?? false,
                Icons.chair,
              ),
              _buildFacilityChip(
                'Wheelchair Access',
                facilities['rampAccessible'] ?? true,
                Icons.accessible,
              ),
              _buildFacilityChip(
                'Parking',
                facilities['parkingAvailable'] ?? false,
                Icons.local_parking,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // Issues Reported
        if (issues.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber,
                        color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Issues Reported',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...issues.map((issue) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 16, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          Text(
                            issue.toString(),
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Alternative Booths
        _buildAlternativeBoothsSection(),
        const SizedBox(height: 40),
      ],
    ),
  );
  }

  Widget _buildCrowdIndicator(int level) {
    final colors = [
      Colors.green,
      Colors.lightGreen,
      Colors.yellow,
      Colors.orange,
      Colors.red,
    ];

    final labels = ['Empty', 'Light', 'Moderate', 'Heavy', 'Very Heavy'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Container(
              width: 24,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index < level ? colors[level - 1] : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          labels[level - 1],
          style: TextStyle(
            fontSize: 12,
            color: AppColors.ink.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.access_time,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec['timeRange'] ?? 'Recommended Time',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  rec['reason'] ?? 'Based on historical data',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (rec['confidence'] == 'high')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'HIGH CONF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildFacilityChip(String label, bool available, IconData icon) {
    return Semantics(
      label: '$label: ${available ? 'Available' : 'Not available'}',
      child: Chip(
      avatar: Icon(
        icon,
        size: 18,
        color: available ? AppColors.green : Colors.red,
      ),
      label: Text(label),
      backgroundColor: available
          ? AppColors.green.withValues(alpha: 0.1)
          : Colors.red.withValues(alpha: 0.1),
      side: BorderSide(
        color: available
            ? AppColors.green.withValues(alpha: 0.3)
            : Colors.red.withValues(alpha: 0.3),
      ),
      ), // Chip
    );
  }

  // ignore: unused_element
  Widget _buildAlternativeBoothsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(
                'Alternative Booths',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Nearby booths with shorter queues',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAlternatives,
            icon: const Icon(Icons.search),
            label: const Text('Find Better Options'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAlternatives() async {
    try {
      final user = ref.read(userProvider).value;
      final currentBooth = user?.boothDetails?['boothName'] ?? 'Current Booth';
      final constituency = user?.state ?? 'Delhi';
      final state = user?.state ?? 'Delhi';

      final alternatives = await FeaturesApiService.getAlternativeBooths(
        currentBooth,
        constituency,
        state,
      );

      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alternatives['message'] ?? 'Alternative Booths',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...(alternatives['alternatives'] as List<dynamic>? ?? [])
                    .map((booth) => ListTile(
                          leading: const Icon(Icons.how_to_vote,
                              color: AppColors.orange),
                          title: Text(booth['name'] ?? 'Booth'),
                          subtitle: Text(
                              'Wait: ${booth['status']?['waitTime'] ?? 'Unknown'} min'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                        )),
              ],
            ),
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

  void _showReportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return ReportBoothStatusForm(
            scrollController: scrollController,
            onSubmit: _submitReport,
          );
        },
      ),
    );
  }

  Future<void> _submitReport(Map<String, dynamic> reportData) async {
    setState(() => _isReporting = true);
    Navigator.pop(context);

    try {
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid;

      if (firebaseUid == null) {
        throw Exception("User not logged in");
      }

      await FeaturesApiService.reportBoothStatus(firebaseUid, reportData);

      setState(() => _isReporting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your report helps other voters.'),
            backgroundColor: AppColors.green,
          ),
        );

        // Refresh data
        _loadBoothData();
      }
    } catch (e) {
      setState(() => _isReporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getQueueColor(String queueLength) {
    switch (queueLength.toLowerCase()) {
      case 'none':
      case 'short':
        return AppColors.green;
      case 'medium':
        return Colors.orange;
      case 'long':
      case 'very_long':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getQueueIcon(String queueLength) {
    switch (queueLength.toLowerCase()) {
      case 'none':
        return Icons.sentiment_satisfied;
      case 'short':
        return Icons.people_outline;
      case 'medium':
        return Icons.people;
      case 'long':
        return Icons.groups;
      case 'very_long':
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  String _formatQueueLength(String queueLength) {
    final map = {
      'none': 'No Queue',
      'short': 'Short Queue',
      'medium': 'Medium Queue',
      'long': 'Long Queue',
      'very_long': 'Very Long Queue',
      'unknown': 'Status Unknown',
    };
    return map[queueLength.toLowerCase()] ?? queueLength;
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return timestamp;
    }
  }
}

class ReportBoothStatusForm extends StatefulWidget {
  final ScrollController scrollController;
  final Function(Map<String, dynamic>) onSubmit;

  const ReportBoothStatusForm({
    super.key,
    required this.scrollController,
    required this.onSubmit,
  });

  @override
  State<ReportBoothStatusForm> createState() => _ReportBoothStatusFormState();
}

class _ReportBoothStatusFormState extends State<ReportBoothStatusForm> {
  String _queueLength = 'medium';
  int _waitTime = 15;
  int _crowdLevel = 3;
  bool _evmWorking = true;
  bool _waterAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: widget.scrollController,
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
          const Text(
            'Report Booth Status',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Help other voters with real-time updates',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Queue Length
          const Text('Queue Length',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'none', label: Text('None')),
              ButtonSegment(value: 'short', label: Text('Short')),
              ButtonSegment(value: 'medium', label: Text('Medium')),
              ButtonSegment(value: 'long', label: Text('Long')),
            ],
            selected: {_queueLength},
            onSelectionChanged: (set) =>
                setState(() => _queueLength = set.first),
          ),
          const SizedBox(height: 20),

          // Wait Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wait Time',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$_waitTime min',
                  style: const TextStyle(color: AppColors.orange)),
            ],
          ),
          Slider(
            value: _waitTime.toDouble(),
            min: 0,
            max: 120,
            divisions: 24,
            onChanged: (v) => setState(() => _waitTime = v.round()),
          ),
          const SizedBox(height: 20),

          // Crowd Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Crowd Level',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$_crowdLevel/5',
                  style: const TextStyle(color: AppColors.orange)),
            ],
          ),
          Slider(
            value: _crowdLevel.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) => setState(() => _crowdLevel = v.round()),
          ),
          const SizedBox(height: 20),

          // Facilities
          const Text('Facilities Working?',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('EVM Machine'),
            value: _evmWorking,
            onChanged: (v) => setState(() => _evmWorking = v),
          ),
          SwitchListTile(
            title: const Text('Water Available'),
            value: _waterAvailable,
            onChanged: (v) => setState(() => _waterAvailable = v),
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSubmit({
                  'queueLength': _queueLength,
                  'waitTimeMinutes': _waitTime,
                  'crowdLevel': _crowdLevel,
                  'evmWorking': _evmWorking,
                  'waterAvailable': _waterAvailable,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Submit Report'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
