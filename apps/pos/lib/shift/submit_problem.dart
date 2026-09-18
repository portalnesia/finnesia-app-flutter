/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/api_error.dart';

/// Why a write to the server did not work, as far as the screen can tell the cashier.
///
/// [message] is the server's own sentence when it refused (a refusal is the server's to explain).
/// [mayHaveSucceeded] is true when the answer was not a plain no: the write may have been made
/// anyway, and the cashier must not be told it was not (`plan/ui/findings.md` F34).
final class SubmitProblem {
  const SubmitProblem({this.message, required this.mayHaveSucceeded});

  /// No answer at all: the connection dropped, and nothing is known.
  const SubmitProblem.noAnswer() : this(mayHaveSucceeded: true);

  /// What the server answered instead of a yes.
  ///
  /// Only a 4xx is a refusal. A 5xx may have committed before it failed, and a 2xx that could not
  /// be read means the write was made: neither is "no".
  factory SubmitProblem.answered(ApiError failure) => SubmitProblem(
    message: failure.message,
    mayHaveSucceeded: !(failure.status >= 400 && failure.status < 500),
  );

  final String? message;
  final bool mayHaveSucceeded;
}
