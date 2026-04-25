import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../services/features_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One-Tap Complaint & Escalation Screen
/// Quick complaint filing with auto-generated ECI forms
class ComplaintsScreen extends ConsumerStatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _templates = [];
  List<dynamic> _myComplaints = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid;

      if (firebaseUid == null) {
        throw Exception("User not logged in");
      }

      final templates =
          await FeaturesApiService.getComplaintTemplates(firebaseUid);
      final complaints = await FeaturesApiService.getMyComplaints(firebaseUid);

      setState(() {
        _templates = templates;
        _myComplaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fileComplaint(Map<String, dynamic> template) async {
    try {
      setState(() => _isLoading = true);

      final firebaseUid = FirebaseAuth.instance.currentUser?.uid;

      if (firebaseUid == null) {
        throw Exception("User not logged in");
      }

      final result = await FeaturesApiService.fileComplaint(
        firebaseUid,
        template['autoFill'],
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Complaint filed! Ref: ${result['eciReferenceNumber']}'),
            backgroundColor: AppColors.green,
          ),
        );

        // Refresh complaints list
        _loadData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('File Complaint'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New Complaint'),
            Tab(text: 'My Complaints'),
          ],
        ),
      ),
      body: _isLoading && _templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNewComplaintTab(),
                _buildMyComplaintsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showECIContacts(),
        icon: const Icon(Icons.phone),
        label: const Text('ECI Helpline'),
        backgroundColor: AppColors.orange,
      ),
    );
  }

  Widget _buildNewComplaintTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.redLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red[700], size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Facing an issue?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                      Text(
                        'File a complaint with Election Commission. Auto-generated forms with your details.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick templates
          Text(
            'Quick Complaint',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),

          ..._templates.map((template) => _buildTemplateCard(template)),

          const SizedBox(height: 24),

          // Escalation info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escalation Path',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEscalationStep(
                    '1', 'BLO', 'Booth Level Officer', 'Within 24 hours'),
                _buildEscalationStep(
                    '2',
                    'ERO',
                    'Electoral Registration Officer',
                    'If not resolved in 3 days'),
                _buildEscalationStep('3', 'CEO', 'Chief Electoral Officer',
                    'If not resolved in 7 days'),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: '${template['title'] ?? 'Complaint'}. ${template['description'] ?? ''}. Tap to view details or file.',
        child: InkWell(
        onTap: () => _showComplaintDetails(template),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                template['icon'] ?? '❓',
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template['title'] ?? 'Other Issue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template['description'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.ink.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _fileComplaint(template),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('File'),
              ),
            ],
          ),
        ),
      ), // InkWell
      ), // Semantics
    );
  }

  Widget _buildEscalationStep(
      String number, String code, String title, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$code - $title',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyComplaintsTab() {
    if (_myComplaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'No complaints filed yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.ink.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "New Complaint" to file a grievance',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.ink.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myComplaints.length,
      itemBuilder: (context, index) {
        final complaint = _myComplaints[index];
        return _buildComplaintCard(complaint);
      },
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final status = complaint['status'] ?? 'submitted';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final a11yLabel = '${_formatComplaintType(complaint['complaintType'])}. '
        'Status: ${status.toUpperCase()}. '
        'Reference: ${complaint['eciReferenceNumber'] ?? 'N/A'}. '
        'Filed: ${_formatDate(complaint['createdAt'])}.';

    return Semantics(
      label: a11yLabel,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                complaint['eciReferenceNumber'] ?? 'N/A',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.ink.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatComplaintType(complaint['complaintType']),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            complaint['description'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.ink.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filed: ${_formatDate(complaint['createdAt'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ink.withValues(alpha: 0.5),
                ),
              ),
              if (complaint['priority'] == 'high' ||
                  complaint['priority'] == 'urgent')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    complaint['priority'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      ), // Semantics
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return AppColors.green;
      case 'in_progress':
        return AppColors.blue;
      case 'acknowledged':
        return AppColors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.pending;
      case 'acknowledged':
        return Icons.thumb_up;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _formatComplaintType(String? type) {
    if (type == null) return 'General Issue';
    return type
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showComplaintDetails(Map<String, dynamic> template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scrollController,
              children: [
                Text(
                  template['title'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  template['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.ink.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Auto-filled Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (template['autoFill']['description'] ?? ''),
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _fileComplaint(template);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('File This Complaint'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showECIContacts() {
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
            const Text(
              'ECI Helpline',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildContactRow(Icons.phone, '1950', 'National Helpline'),
            _buildContactRow(Icons.phone, '1800-111-950', 'Toll Free'),
            _buildContactRow(Icons.language, 'eci.gov.in', 'Website'),
            const SizedBox(height: 20),
            const Text(
              'SMS COMPLAINT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const Text('Send SMS to 1950'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              // Copy to clipboard
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }
}
