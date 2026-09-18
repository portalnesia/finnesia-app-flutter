/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/widgets.dart';
import 'package:pos/bootstrap.dart';

/// Serves [AppServices] to every screen below it, and rebuilds what read them when they change.
///
/// This is the app's dependency injection, and it is only this: a test hands a screen fake
/// services by putting them in an `AppScope`, not by replacing a singleton.
class AppScope extends InheritedNotifier<AppServices> {
  const AppScope({
    super.key,
    required AppServices services,
    required super.child,
  }) : super(notifier: services);

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw StateError(
        'There is no AppScope above this widget: wrap the app in AppScope(services: ...).',
      );
    }
    // Never null: the constructor takes the services as a required, non-null argument.
    return scope.notifier!;
  }
}
