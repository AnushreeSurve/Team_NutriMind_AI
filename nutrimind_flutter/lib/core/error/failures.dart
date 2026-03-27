/// Centralized failure representation for the app.
library;

class Failure {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  String toString() => 'Failure: $message (code: $statusCode)';
}
