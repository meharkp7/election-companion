import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AppErrorType {
  network,
  authentication,
  validation,
  server,
  unknown,
}

class AppError {
  final String message;
  final AppErrorType type;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    required this.type,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'AppError(message: $message, type: $type, code: $code)';
  }

  String get userFriendlyMessage {
    switch (type) {
      case AppErrorType.network:
        return 'Please check your internet connection and try again.';
      case AppErrorType.authentication:
        return 'Please log in again to continue.';
      case AppErrorType.validation:
        return message;
      case AppErrorType.server:
        return 'Server error occurred. Please try again later.';
      case AppErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
}

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  void logError(AppError error) {
    if (kDebugMode) {
      debugPrint('ERROR: ${error.toString()}');
      if (error.stackTrace != null) {
        debugPrint('STACK TRACE: ${error.stackTrace}');
      }
    }
    // In production, you would send this to a logging service like Firebase Crashlytics
  }

  AppError handleError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) {
      logError(error);
      return error;
    }

    AppError appError;

    if (error is SocketException) {
      appError = AppError(
        message: 'No internet connection',
        type: AppErrorType.network,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error is HttpException) {
      appError = AppError(
        message: 'HTTP error: ${error.message}',
        type: AppErrorType.server,
        code: error.message,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error is FormatException) {
      appError = AppError(
        message: 'Invalid data format',
        type: AppErrorType.validation,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error is TimeoutException) {
      appError = AppError(
        message: 'Request timed out',
        type: AppErrorType.network,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else {
      appError = AppError(
        message: error.toString(),
        type: AppErrorType.unknown,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    logError(appError);
    return appError;
  }

  void showSnackBar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.userFriendlyMessage),
        backgroundColor: _getErrorColor(error.type),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Color _getErrorColor(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return Colors.orange;
      case AppErrorType.authentication:
        return Colors.red;
      case AppErrorType.validation:
        return Colors.amber;
      case AppErrorType.server:
        return Colors.red;
      case AppErrorType.unknown:
        return Colors.grey;
    }
  }
}

// Extension to make error handling easier
extension ErrorHandling on Future {
  Future<T> handleError<T>(Function(AppError) onError) async {
    try {
      return await this as T;
    } catch (error, stackTrace) {
      final appError = ErrorService().handleError(error, stackTrace);
      onError(appError);
      throw appError;
    }
  }
}
