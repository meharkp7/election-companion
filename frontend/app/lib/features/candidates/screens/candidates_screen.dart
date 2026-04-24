import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/colors.dart';
import '../../../providers/user_provider.dart';
import '../../../services/features_api_service.dart';

/// Candidate Intelligence Screen
/// Shows constituency-specific candidates with AI-powered analysis
class CandidatesScreen extends ConsumerStatefulWidget {
  const CandidatesScreen({super.key});

  @override
  ConsumerState<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends ConsumerState<CandidatesScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _candidatesData;
  String? _error;
  int _selectedCandidateIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    try {
      final user = ref.read(userProvider).value;
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid;

      if (firebaseUid == null) {
        throw Exception("User not logged in");
      }

      final data =
          await FeaturesApiService.getMyConstituencyCandidates(firebaseUid);

      setState(() {
        _candidatesData = data;
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
        title: const Text('Your Candidates'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.compare),
            onPressed: _showComparison,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
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
            'Failed to load candidates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(fontSize: 14, color: Colors.red[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadCandidates,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final candidates = _candidatesData?['candidates'] as List<dynamic>? ?? [];
    final constituency =
        _candidatesData?['constituency'] ?? 'Your Constituency';
    final state = _candidatesData?['state'] ?? '';

    if (candidates.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.orange, AppColors.orange.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'AI-POWERED ANALYSIS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                constituency,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                state,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${candidates.length} Candidates • Compare backgrounds, track records, and integrity',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Candidate selector
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final candidate = candidates[index];
              final isSelected = index == _selectedCandidateIndex;

              return GestureDetector(
                onTap: () => setState(() => _selectedCandidateIndex = index),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.orange : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.orange : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        candidate['partySymbol'] ?? '🏛️',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        candidate['party'] ?? 'IND',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Candidate details
        Expanded(
          child: _buildCandidateDetails(candidates[_selectedCandidateIndex]),
        ),
      ],
    );
  }

  Widget _buildCandidateDetails(Map<String, dynamic> candidate) {
    final name = candidate['name'] ?? 'Unknown';
    final party = candidate['party'] ?? 'Independent';
    final age = candidate['age'] ?? 'N/A';
    final education = candidate['education'] ?? 'Not available';
    final profession = candidate['profession'] ?? 'Not available';
    final criminalCases = candidate['criminalCases'] ?? 0;
    final attendance = candidate['attendancePercentage'];
    final assets = candidate['assetsDeclared'];
    final aiSummary = candidate['aiSummary'] ?? 'No analysis available';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name & Party
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    candidate['partySymbol'] ?? '🏛️',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '$party • $age years',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.ink.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // AI Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AI Analysis',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  aiSummary,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.ink.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Key Stats
          Row(
            children: [
              _buildStatCard(
                criminalCases > 0 ? '⚠️' : '✅',
                criminalCases > 0 ? '$criminalCases Cases' : 'Clean Record',
                criminalCases > 0 ? 'Criminal Cases' : 'No Criminal Record',
                criminalCases > 0 ? Colors.red : AppColors.green,
              ),
              const SizedBox(width: 12),
              if (attendance != null)
                _buildStatCard(
                  '📊',
                  '$attendance%',
                  'Attendance',
                  AppColors.blue,
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Background
          _buildSection('Background', [
            _buildInfoRow('Education', education),
            _buildInfoRow('Profession', profession),
          ]),
          const SizedBox(height: 20),

          // Financials
          if (assets != null)
            _buildSection('Financial Declaration', [
              _buildInfoRow(
                  'Assets', '₹${(assets / 1000000).toStringAsFixed(1)}M'),
              if (candidate['liabilitiesDeclared'] != null)
                _buildInfoRow('Liabilities',
                    '₹${(candidate['liabilitiesDeclared'] / 1000000).toStringAsFixed(1)}M'),
            ]),
          const SizedBox(height: 20),

          // Parliamentary Performance (if incumbent)
          if (candidate['debatesParticipated'] != null &&
              candidate['debatesParticipated'] > 0)
            _buildSection('Parliamentary Performance', [
              _buildInfoRow('Debates', '${candidate['debatesParticipated']}'),
              _buildInfoRow(
                  'Questions Asked', '${candidate['questionsAsked'] ?? 0}'),
              if (attendance != null)
                _buildInfoRow('Attendance', '$attendance%'),
            ]),

          const SizedBox(height: 30),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showFullProfile(candidate),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Full Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addToComparison(candidate['id']),
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Compare'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    side: BorderSide(color: AppColors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.ink.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.ink.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No candidates found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.ink.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your profile to see candidates\nfor your constituency',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.ink.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showComparison() {
    final candidates = _candidatesData?['candidates'] as List<dynamic>? ?? [];
    if (candidates.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 2 candidates to compare')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/compare-candidates',
      arguments: candidates.map((c) => c['id'] as String).toList(),
    );
  }

  void _showFullProfile(Map<String, dynamic> candidate) {
    // Navigate to detailed profile
    Navigator.pushNamed(
      context,
      '/candidate-profile',
      arguments: candidate['id'],
    );
  }

  void _addToComparison(String candidateId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to comparison')),
    );
  }
}
