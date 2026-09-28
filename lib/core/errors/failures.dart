/// Typed failures; repositories map Dio/exception -> Failure.
/// UI maps Failure -> user-friendly message matching design error states.
sealed class Failure {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? fields;
  const ValidationFailure(super.message, {super.code, this.fields});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message, {super.code});
}

String userMessage(Failure f) => f.message;
