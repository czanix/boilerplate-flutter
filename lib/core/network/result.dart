/// Result Pattern — sem exceção para fluxo de negócio.
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final int? statusCode;
  const Failure(this.message, {this.statusCode});
}
