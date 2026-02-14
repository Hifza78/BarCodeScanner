/// Result type for handling success/failure cases consistently
/// Following functional error handling pattern
sealed class Result<T> {
  const Result();

  /// Check if result is successful
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Get value if success, otherwise null
  T? get valueOrNull => isSuccess ? (this as Success<T>).value : null;

  /// Get error message if failure, otherwise null
  String? get errorOrNull => isFailure ? (this as Failure<T>).message : null;

  /// Transform the result value
  Result<R> map<R>(R Function(T value) transform) {
    if (this is Success<T>) {
      return Success(transform((this as Success<T>).value));
    }
    return Failure((this as Failure<T>).message, (this as Failure<T>).exception);
  }

  /// Handle both success and failure cases
  R when<R>({
    required R Function(T value) success,
    required R Function(String message, Exception? exception) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).value);
    }
    final f = this as Failure<T>;
    return failure(f.message, f.exception);
  }

  /// Execute action on success
  void onSuccess(void Function(T value) action) {
    if (this is Success<T>) {
      action((this as Success<T>).value);
    }
  }

  /// Execute action on failure
  void onFailure(void Function(String message, Exception? exception) action) {
    if (this is Failure<T>) {
      final f = this as Failure<T>;
      action(f.message, f.exception);
    }
  }
}

/// Successful result containing a value
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);
}

/// Failed result containing error information
final class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;

  const Failure(this.message, [this.exception]);
}

/// Extension for wrapping operations in Result
extension ResultExtensions<T> on Future<T> {
  /// Wrap a Future in a Result, catching any exceptions
  Future<Result<T>> toResult({String? errorMessage}) async {
    try {
      final value = await this;
      return Success(value);
    } on Exception catch (e) {
      return Failure(errorMessage ?? e.toString(), e);
    } catch (e) {
      return Failure(errorMessage ?? e.toString());
    }
  }
}

/// Helper to run operations safely and return Result
Future<Result<T>> runCatching<T>(
  Future<T> Function() operation, {
  String? errorMessage,
}) async {
  try {
    final value = await operation();
    return Success(value);
  } on Exception catch (e) {
    return Failure(errorMessage ?? e.toString(), e);
  } catch (e) {
    return Failure(errorMessage ?? e.toString());
  }
}
