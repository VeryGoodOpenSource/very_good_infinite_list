import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:very_good_infinite_list/src/infinite_list.dart';
import 'package:very_good_infinite_list/src/sliver_infinite_list.dart';

/// A mixin on [StatefulWidget] that defines the basic propeties of a widget
/// in which its state mixes with [InfiniteListStateBind].
///
/// See also:
/// - [InfiniteList] a self contained [ListView] that uses
/// [InfiniteListStateBind] to display paginated data.
/// - [SliverInfiniteList] a sliver that uses [InfiniteListStateBind] to
/// display paginated data.
mixin InfiniteListWidget on StatefulWidget {
  /// {@macro scroll_extent_threshold}
  double get scrollExtentThreshold;

  /// {@macro debounce_duration}
  Duration get debounceDuration;

  /// {@macro item_count}
  int get itemCount;

  /// {@macro is_loading}
  bool get isLoading;

  /// {@macro has_error}
  bool get hasError;

  /// {@macro has_reached_max}
  bool get hasReachedMax;

  /// {@macro on_fetch_data}
  VoidCallback get onFetchData;
}

mixin InfiniteListStateBind<WidgetType extends InfiniteListWidget>
    on State<WidgetType> {
  late final CallbackDebouncer debounce;

  ScrollPosition? get scrollPosition;

  @override
  void initState() {
    super.initState();
    debounce = CallbackDebouncer(widget.debounceDuration);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      attachToPosition();
      attemptFetch();
    });
  }

  @override
  void didUpdateWidget(covariant WidgetType oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount ||
        widget.hasReachedMax != oldWidget.hasReachedMax) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        attemptFetch();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    debounce.dispose();
    detachFromPosition();
  }

  void attachToPosition() {
    scrollPosition?.addListener(attemptFetch);
  }

  void detachFromPosition() {
    scrollPosition?.removeListener(attemptFetch);
  }

  void attemptFetch() {
    if (isAtEnd &&
        !widget.hasReachedMax &&
        !widget.isLoading &&
        !widget.hasError) {
      debounce(widget.onFetchData);
    }
  }

  bool get isAtEnd {
    if (widget.itemCount == 0) {
      return true;
    }

    final scrollPosition = this.scrollPosition;
    if (scrollPosition == null) {
      return false;
    }

    // This considers the end of the scrollable content as the
    final maxScroll = scrollPosition.maxScrollExtent;
    final currentScroll = scrollPosition.pixels - precedingScrollExtent;

    return currentScroll >= (maxScroll - widget.scrollExtentThreshold);
  }

  bool get hasItems => widget.itemCount != 0;

  double get precedingScrollExtent;
}

/// {@template callback_debouncer}
/// A model used for debouncing callbacks.
///
/// Is only used internally and should not be used explicitly.
/// {@endtemplate}
@visibleForTesting
class CallbackDebouncer {
  /// {@macro callback_debouncer}
  CallbackDebouncer(this._delay);

  final Duration _delay;
  Timer? _timer;

  /// Calls the given [callback] after the given duration has passed.
  @visibleForTesting
  void call(VoidCallback callback) {
    if (_delay == Duration.zero) {
      callback();
    } else {
      _timer?.cancel();
      _timer = Timer(_delay, callback);
    }
  }

  /// Stops any running timers and disposes this instance.
  @visibleForTesting
  void dispose() {
    _timer?.cancel();
  }
}
