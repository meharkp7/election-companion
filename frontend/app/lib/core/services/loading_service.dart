import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LoadingState {
  idle,
  loading,
  success,
  error,
}

class LoadingStateData<T> {
  final LoadingState state;
  final T? data;
  final String? error;
  final String? loadingMessage;

  const LoadingStateData({
    required this.state,
    this.data,
    this.error,
    this.loadingMessage,
  });

  LoadingStateData<T> copyWith({
    LoadingState? state,
    T? data,
    String? error,
    String? loadingMessage,
  }) {
    return LoadingStateData<T>(
      state: state ?? this.state,
      data: data ?? this.data,
      error: error ?? this.error,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }

  bool get isLoading => state == LoadingState.loading;
  bool get isSuccess => state == LoadingState.success;
  bool get isError => state == LoadingState.error;
  bool get isIdle => state == LoadingState.idle;
}

class LoadingNotifier<T> extends Notifier<LoadingStateData<T>> {
  @override
  LoadingStateData<T> build() {
    return const LoadingStateData(state: LoadingState.idle);
  }

  void setLoading([String? message]) {
    state = state.copyWith(
      state: LoadingState.loading,
      loadingMessage: message,
    );
  }

  void setSuccess(T data) {
    state = state.copyWith(
      state: LoadingState.success,
      data: data,
      error: null,
    );
  }

  void setError(String error) {
    state = state.copyWith(
      state: LoadingState.error,
      error: error,
      data: null,
    );
  }

  void setIdle() {
    state = const LoadingStateData(state: LoadingState.idle);
  }

  void reset() {
    state = const LoadingStateData(state: LoadingState.idle);
  }
}

// Provider for loading state
class LoadingServiceProvider<T> extends Notifier<LoadingStateData<T>> {
  @override
  LoadingStateData<T> build() {
    return const LoadingStateData(state: LoadingState.idle);
  }

  void setLoading([String? message]) {
    state = state.copyWith(
      state: LoadingState.loading,
      loadingMessage: message,
    );
  }

  void setSuccess(T data) {
    state = state.copyWith(
      state: LoadingState.success,
      data: data,
      error: null,
    );
  }

  void setError(String error) {
    state = state.copyWith(
      state: LoadingState.error,
      error: error,
      data: null,
    );
  }

  void setIdle() {
    state = const LoadingStateData(state: LoadingState.idle);
  }

  void reset() {
    state = const LoadingStateData(state: LoadingState.idle);
  }
}

// Enhanced loading widgets
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Theme.of(context).primaryColor,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: LoadingIndicator(
              message: loadingMessage ?? 'Loading...',
              size: 32.0,
            ),
          ),
      ],
    );
  }
}

// Utility functions for handling loading states
class LoadingUtils {
  static Widget handleLoadingState<T>(
    LoadingStateData<T> loadingState, {
    required Widget Function(T data) success,
    required Widget Function(String error) error,
    Widget? loading,
    String? loadingMessage,
    Widget? idle,
  }) {
    switch (loadingState.state) {
      case LoadingState.loading:
        return loading ?? LoadingIndicator(message: loadingMessage);
      case LoadingState.success:
        return success(loadingState.data as T);
      case LoadingState.error:
        return error(loadingState.error ?? 'Unknown error');
      case LoadingState.idle:
        return idle ?? const SizedBox.shrink();
    }
  }

  static Widget handleAsyncValue<T>(
    AsyncValue<T> asyncValue, {
    required Widget Function(T data) success,
    required Widget Function(Object error, StackTrace? stackTrace) error,
    Widget? loading,
  }) {
    return asyncValue.when(
      loading: () => loading ?? const LoadingIndicator(),
      error: error,
      data: success,
    );
  }
}
