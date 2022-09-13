import 'dart:async';

import 'package:flutter/foundation.dart';

/// {@template callback_debouncer}
/// A model used for debouncing callbacks.
///
/// Is only used internally and should not be used explicitly.
/// {@endtemplate}
class CallbackDebouncer {
  /// {@macro callback_debouncer}
  CallbackDebouncer(this._delay);

  final Duration _delay;
  Timer? _timer;

  /// Calls the given [callback] after the given duration has passed.
  void call(VoidCallback callback) {
    if (_delay == Duration.zero) {
      callback();
    } else {
      _timer?.cancel();
      _timer = Timer(_delay, callback);
    }
  }

  /// Stops any running timers and disposes this instance.
  void dispose() {
    _timer?.cancel();
  }
}
