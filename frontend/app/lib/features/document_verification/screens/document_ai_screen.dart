import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../providers/user_provider.dart';
import '../../../services/features_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Document AI Verification Screen
/// AI-powered document validation before booth visit
class DocumentAIScreen extends ConsumerStatefulWidget {
  const DocumentAIScreen({super.key});

  @override
  ConsumerState<DocumentAIScreen> createState() => _DocumentAIScreenState();
}

class _DocumentAIScreenState extends ConsumerState<DocumentAIScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _validationResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    _validateDocuments();
  }

  Future<void> _validateDocuments() async {
    try {
      final user = ref.read(userProvider).value;
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid;

      if (firebaseUid == null) {
        throw Exception("User not logged in");
      }

      final result = await FeaturesApiService.validateAllDocuments(firebaseUid);

      setState(() {
        _validationResult = result;
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
        title: const Text('Document Check'),
        backgroundColor: AppColors.surface,
        elevation: 0,
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
            'Validation Failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _validateDocuments,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final allValid = _validationResult?['allValid'] ?? false;
    final results =
        _validationResult?['results'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: allValid
                    ? [AppColors.green, AppColors.green.withOpacity(0.8)]
                    : [Colors.orange, Colors.orange.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  allValid ? Icons.verified_user : Icons.warning_amber,
                  size: 56,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  allValid ? 'Ready for Booth Visit!' : 'Action Required',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  allValid
                      ? 'All your documents are validated. You\'re ready to vote!'
                      : 'Some documents need attention before you visit the polling booth.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Document status cards
          _buildDocumentCard(
            'Aadhaar Card',
            results['aadhaar'] ?? {},
            Icons.credit_card,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildDocumentCard(
            'Voter ID (EPIC)',
            results['voter_id'] ?? {},
            Icons.how_to_vote,
            AppColors.orange,
          ),
          const SizedBox(height: 24),

          // AI Analysis
          if (!allValid) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        'AI Suggestions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...results.entries.expand((entry) {
                    final docResult = entry.value as Map<String, dynamic>;
                    final suggestions =
                        docResult['suggestions'] as List<dynamic>? ?? [];
                    return suggestions.map((s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.arrow_right,
                                  size: 20, color: Colors.orange[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  s.toString(),
                                  style: TextStyle(color: Colors.orange[900]),
                                ),
                              ),
                            ],
                          ),
                        ));
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Action buttons
          if (!allValid)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/upload-documents'),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload/Fix Documents'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
    String title,
    Map<String, dynamic> result,
    IconData icon,
    Color color,
  ) {
    final canProceed = result['canProceed'] ?? false;
    final warning = result['warning'] as String?;
    final issues = result['issues'] as List<dynamic>? ?? [];
    final confidence = result['confidence'] as num?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canProceed ? AppColors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (confidence != null)
                      Text(
                        'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ink.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: canProceed
                      ? AppColors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  canProceed ? '✅ Valid' : '⚠️ Issues',
                  style: TextStyle(
                    color: canProceed ? AppColors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (warning != null || issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (warning != null)
                    Text(
                      '⚠️ $warning',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[800],
                      ),
                    ),
                  ...issues.map((issue) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• $issue',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[700],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
