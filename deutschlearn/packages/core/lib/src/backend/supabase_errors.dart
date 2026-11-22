import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../failure.dart';

/// Converts Supabase/network exceptions into [AppFailure]s.
AppFailure mapSupabaseError(Object error) {
  if (error is AppFailure) return error;
  if (error is SocketException || error is TimeoutException || error is AuthRetryableFetchException) {
    return AppFailure(FailureKind.network, error.toString());
  }
  if (error is AuthException) {
    final code = error.code ?? '';
    final kind = switch (code) {
      'invalid_credentials' => FailureKind.invalidCredentials,
      'email_not_confirmed' => FailureKind.emailNotConfirmed,
      'user_already_exists' || 'email_exists' => FailureKind.emailInUse,
      'weak_password' => FailureKind.weakPassword,
      'over_request_rate_limit' || 'over_email_send_rate_limit' => FailureKind.rateLimited,
      _ => error.statusCode == '400' && error.message.contains('Invalid login')
          ? FailureKind.invalidCredentials
          : FailureKind.unknown,
    };
    return AppFailure(kind, error.message);
  }
  if (error is PostgrestException) {
    return AppFailure(_kindForPgCode(error.code), error.message);
  }
  if (error is FunctionException) {
    final details = error.details;
    final kindName = details is Map ? details['error'] : null;
    final kind = switch ((error.status, kindName)) {
      (400, 'invalid_format') => FailureKind.invalidCodeFormat,
      (401, _) || (403, _) => FailureKind.forbidden,
      (404, 'code_not_found') => FailureKind.codeNotFound,
      (404, _) => FailureKind.notFound,
      (409, _) => FailureKind.alreadyLinked,
      (429, _) => FailureKind.rateLimited,
      _ => FailureKind.unknown,
    };
    return AppFailure(kind, '${error.status} $details');
  }
  return AppFailure(FailureKind.unknown, error.toString());
}

FailureKind _kindForPgCode(String? code) => switch (code) {
  '42501' => FailureKind.forbidden,
  'P0404' => FailureKind.codeNotFound,
  'P0409' => FailureKind.alreadyLinked,
  'P0429' => FailureKind.rateLimited,
  _ => FailureKind.unknown,
};

/// Runs [action] and rethrows any error as an [AppFailure].
Future<T> guardSupabase<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e) {
    throw mapSupabaseError(e);
  }
}
