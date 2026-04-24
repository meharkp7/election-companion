import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/core/services/error_service.dart';

void main() {
  group('ErrorService', () {
    late ErrorService errorService;

    setUp(() {
      errorService = ErrorService();
    });

    group('handleError', () {
      test('should handle SocketException as network error', () {
        final socketException = SocketException('No internet');
        final appError = errorService.handleError(socketException);

        expect(appError.type, equals(AppErrorType.network));
        expect(appError.message, equals('No internet connection'));
      });

      test('should handle HttpException as server error', () {
        final httpException = HttpException('404 Not Found');
        final appError = errorService.handleError(httpException);

        expect(appError.type, equals(AppErrorType.server));
        expect(appError.message, equals('HTTP error: 404 Not Found'));
        expect(appError.code, equals('404 Not Found'));
      });

      test('should handle FormatException as validation error', () {
        final formatException = FormatException('Invalid format');
        final appError = errorService.handleError(formatException);

        expect(appError.type, equals(AppErrorType.validation));
        expect(appError.message, equals('Invalid data format'));
      });

      test('should handle TimeoutException as network error', () {
        final timeoutException =
            TimeoutException('Request timeout', const Duration(seconds: 30));
        final appError = errorService.handleError(timeoutException);

        expect(appError.type, equals(AppErrorType.network));
        expect(appError.message, equals('Request timed out'));
      });

      test('should handle unknown error as unknown error type', () {
        final unknownError = Exception('Unknown error');
        final appError = errorService.handleError(unknownError);

        expect(appError.type, equals(AppErrorType.unknown));
        expect(appError.message, equals('Unknown error'));
      });

      test('should return existing AppError unchanged', () {
        final existingError = const AppError(
          message: 'Existing error',
          type: AppErrorType.validation,
        );

        final appError = errorService.handleError(existingError);

        expect(appError, equals(existingError));
      });
    });

    group('userFriendlyMessage', () {
      test('should return appropriate message for network error', () {
        const appError = AppError(
          message: 'Network failed',
          type: AppErrorType.network,
        );

        expect(appError.userFriendlyMessage,
            equals('Please check your internet connection and try again.'));
      });

      test('should return appropriate message for authentication error', () {
        const appError = AppError(
          message: 'Auth failed',
          type: AppErrorType.authentication,
        );

        expect(appError.userFriendlyMessage,
            equals('Please log in again to continue.'));
      });

      test('should return original message for validation error', () {
        const appError = AppError(
          message: 'Invalid input',
          type: AppErrorType.validation,
        );

        expect(appError.userFriendlyMessage, equals('Invalid input'));
      });

      test('should return appropriate message for server error', () {
        const appError = AppError(
          message: 'Server error',
          type: AppErrorType.server,
        );

        expect(appError.userFriendlyMessage,
            equals('Server error occurred. Please try again later.'));
      });

      test('should return appropriate message for unknown error', () {
        const appError = AppError(
          message: 'Unknown error',
          type: AppErrorType.unknown,
        );

        expect(appError.userFriendlyMessage,
            equals('Something went wrong. Please try again.'));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        const appError = AppError(
          message: 'Test error',
          type: AppErrorType.validation,
          code: 'VALIDATION_ERROR',
        );

        expect(
            appError.toString(),
            equals(
                'AppError(message: Test error, type: validation, code: VALIDATION_ERROR)'));
      });
    });
  });
}
