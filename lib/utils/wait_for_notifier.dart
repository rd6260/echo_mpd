import 'dart:async';

import 'package:flutter/material.dart';

Future<T> waitForNotifier<T>(
  ValueNotifier<T> notifier, {
  bool Function(T value)? condition,
}) {
  final completer = Completer<T>();

  void listener() {
    final val = notifier.value;
    if (condition == null || condition(val)) {
      notifier.removeListener(listener);
      completer.complete(val);
    }
  }

  notifier.addListener(listener);

  // in case condition is already satisfied before listener was added
  if (condition != null && condition(notifier.value)) {
    notifier.removeListener(listener);
    completer.complete(notifier.value);
  }

  return completer.future;
}
