import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../providers/user_provider.dart';

class AadhaarEkycResult {
  final bool success;
  final String? maskedAadhaar;
  final String? transactionId;
  final Map<String, dynamic>? demographicData;
  final String? error;

  AadhaarEkycResult({
    required this.success,
    this.maskedAadhaar,
    this.transactionId,
    this.demographicData,
    this.error,
  });
}

class VerificationController extends AsyncNotifier<bool> {
  String? _currentUserId;

  @override
  Future<bool> build() async {
    // Get current user ID from userProvider
    final user = ref.read(userProvider).value;
    _currentUserId = user?.firebaseUid;
    return false;
  }

  /// Reports that the user's name was found on the electoral roll.
  /// Backend transitions to READY_TO_VOTE (or VERIFICATION with find_booth action).
  Future<void> confirmVerified({bool boothKnown = true}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(userProvider.notifier).submitVerification(
            verificationStatus: 'verified',
            boothKnown: boothKnown,
          );
      return true;
    });
  }

  /// Reports an issue with verification (name not found, wrong details, etc.).
  /// Backend transitions to ISSUE_RESOLVER.
  Future<void> reportIssue() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(userProvider.notifier).submitVerification(
            verificationStatus: 'issue',
          );
      return true;
    });
  }

  // ==========================================
  // AADHAAR E-KYC
  // ==========================================

  /// Initiate Aadhaar E-KYC - sends OTP to registered mobile
  Future<AadhaarEkycResult> initiateAadhaarEKYC(String aadhaarNumber) async {
    state = const AsyncLoading();
    
    try {
      final user = ref.read(userProvider).value;
      final userId = user?.firebaseUid ?? _currentUserId;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await ApiService.post(
        '/verification/aadhaar/initiate',
        {
          'userId': userId,
          'aadhaarNumber': aadhaarNumber,
        },
      );

      final result = AadhaarEkycResult(
        success: true,
        maskedAadhaar: response['data']['maskedAadhaar'],
        transactionId: response['data']['transactionId'],
      );

      state = const AsyncValue.data(true);
      return result;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Verify Aadhaar OTP and complete E-KYC
  Future<AadhaarEkycResult> verifyAadhaarOTP(String otp) async {
    state = const AsyncLoading();
    
    try {
      final user = ref.read(userProvider).value;
      final userId = user?.firebaseUid ?? _currentUserId;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await ApiService.post(
        '/verification/aadhaar/verify-otp',
        {
          'userId': userId,
          'otp': otp,
        },
      );

      // Update user provider with verified status
      if (response['success'] == true) {
        await ref.read(userProvider.notifier).submitVerification(
          verificationStatus: 'verified',
          boothKnown: true,
        );
      }

      final result = AadhaarEkycResult(
        success: response['success'] ?? false,
        demographicData: response['demographicData'],
      );

      state = const AsyncValue.data(true);
      return result;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  // ==========================================
  // VOTER ID (EPIC) VERIFICATION
  // ==========================================

  /// Verify Voter ID (EPIC) number with ECI
  Future<Map<String, dynamic>> verifyVoterID(
    String epicNumber,
    String userState,
  ) async {
    state = const AsyncLoading();
    
    try {
      final user = ref.read(userProvider).value;
      final userId = user?.firebaseUid ?? _currentUserId;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await ApiService.post(
        '/verification/voter-id',
        {
          'userId': userId,
          'epicNumber': epicNumber,
          'state': userState,
        },
      );

      // User is already updated by backend
      state = const AsyncValue.data(true);
      return response;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final verificationControllerProvider =
    AsyncNotifierProvider<VerificationController, bool>(
  VerificationController.new,
);
