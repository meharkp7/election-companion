class BaseState<T> {
  final bool isLoading;
  final bool isRefreshing;
  final T? data;
  final String? error;
  final bool hasError;
  final bool isEmpty;
  final String? successMessage;
  final bool hasSuccess;

  const BaseState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.data,
    this.error,
    this.hasError = false,
    this.isEmpty = false,
    this.successMessage,
    this.hasSuccess = false,
  });

  bool get isIdle => !isLoading && !isRefreshing && !hasError && !hasSuccess;
  bool get hasData => data != null;
  bool get canLoadMore => !isLoading && !isRefreshing && !hasError;

  BaseState<T> copyWith({
    bool? isLoading,
    bool? isRefreshing,
    T? data,
    String? error,
    bool? hasError,
    bool? isEmpty,
    String? successMessage,
    bool? hasSuccess,
  }) {
    return BaseState<T>(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      data: data ?? this.data,
      error: error ?? this.error,
      hasError: hasError ?? this.hasError,
      isEmpty: isEmpty ?? this.isEmpty,
      successMessage: successMessage ?? this.successMessage,
      hasSuccess: hasSuccess ?? this.hasSuccess,
    );
  }
}

class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? error;
  final bool hasError;
  final bool hasReachedMax;
  final int currentPage;
  final int pageSize;
  final int totalCount;

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.error,
    this.hasError = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.pageSize = 10,
    this.totalCount = 0,
  });

  bool get isIdle => !isLoading && !isRefreshing && !isLoadingMore && !hasError;
  bool get isEmpty => items.isEmpty && !isLoading;
  bool get canLoadMore => !hasReachedMax && !isLoadingMore && !isLoading;
  int get totalPages => (totalCount / pageSize).ceil();

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? error,
    bool? hasError,
    bool? hasReachedMax,
    int? currentPage,
    int? pageSize,
    int? totalCount,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      hasError: hasError ?? this.hasError,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class AsyncOperationState<T> {
  final bool isRunning;
  final T? result;
  final String? error;
  final bool hasError;
  final String? successMessage;
  final bool hasSuccess;

  const AsyncOperationState({
    this.isRunning = false,
    this.result,
    this.error,
    this.hasError = false,
    this.successMessage,
    this.hasSuccess = false,
  });

  bool get isIdle => !isRunning && !hasError && !hasSuccess;
  bool get canExecute => !isRunning;

  AsyncOperationState<T> copyWith({
    bool? isRunning,
    T? result,
    String? error,
    bool? hasError,
    String? successMessage,
    bool? hasSuccess,
  }) {
    return AsyncOperationState<T>(
      isRunning: isRunning ?? this.isRunning,
      result: result ?? this.result,
      error: error ?? this.error,
      hasError: hasError ?? this.hasError,
      successMessage: successMessage ?? this.successMessage,
      hasSuccess: hasSuccess ?? this.hasSuccess,
    );
  }
}

class FormState {
  final bool isSubmitting;
  final bool isValid;
  final Map<String, String> errors;
  final Map<String, dynamic> data;
  final String? generalError;
  final String? successMessage;

  const FormState({
    this.isSubmitting = false,
    this.isValid = false,
    this.errors = const {},
    this.data = const {},
    this.generalError,
    this.successMessage,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasGeneralError => generalError != null;
  bool get hasSuccessMessage => successMessage != null;
  bool get canSubmit => isValid && !isSubmitting;

  FormState copyWith({
    bool? isSubmitting,
    bool? isValid,
    Map<String, String>? errors,
    Map<String, dynamic>? data,
    String? generalError,
    String? successMessage,
  }) {
    return FormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isValid: isValid ?? this.isValid,
      errors: errors ?? this.errors,
      data: data ?? this.data,
      generalError: generalError ?? this.generalError,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}
