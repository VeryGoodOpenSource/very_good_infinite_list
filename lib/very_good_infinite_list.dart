import 'dart:async';

import 'package:flutter/material.dart';

/// The type definition for the [InfiniteList.itemBuilder].
typedef ItemBuilder = Widget Function(BuildContext context, int index);

/// {@macro infinite_list}
/// A widget that makes it easy to declaratively load and display paginated data
/// as a list.
///
/// When the list is scrolled to the end, the [onFetchData] callback will be
/// called.
///
/// When there are too few items to fill the widget's allocated space,
/// [onFetchData] will be called automatically.
///
/// The [itemCount], [hasReachedMax], [onFetchData] and [itemBuilder] must be
/// provided and cannot be `null`.
/// {@endtemplate}
class InfiniteList extends StatefulWidget {
  /// {@macro infinite_list}
  const InfiniteList({
    Key? key,
    required this.itemCount,
    required this.onFetchData,
    required this.itemBuilder,
    this.scrollController,
    this.physics,
    this.scrollExtentThreshold = 400.0,
    this.debounceDuration = const Duration(milliseconds: 100),
    this.reverse = false,
    this.isLoading = false,
    this.hasError = false,
    this.hasReachedMax = false,
    this.padding,
    this.emptyBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.separatorBuilder,
  })  : assert(
          scrollExtentThreshold >= 0.0,
          'scrollExtentThreshold must be greater than or equal to 0.0',
        ),
        super(key: key);

  /// An optional [ScrollController] this [InfiniteList] will attach to.
  /// It's used to detect when the list has scrolled to the appropriate position
  /// to call [onFetchData].
  ///
  /// Is optional and mostly used only for testing. If set to `null`, an
  /// internal [ScrollController] is used instead.
  final ScrollController? scrollController;

  /// An optional [ScrollPhysics] this [InfiniteList] will use.
  ///
  /// If set to `null`, the default [ScrollPhysics] will be used instead.
  final ScrollPhysics? physics;

  /// The offset, in pixels, that the [scrollController] must be scrolled over
  /// to trigger [onFetchData].
  ///
  /// This is useful for fetching data _before_ the user has scrolled all the
  /// way to the end of the list, so the fetching mechanism is more well hidden.
  ///
  /// For example, if this is set to `400.0` (the default), [onFetchData] will
  /// be called when the list is scrolled `400.0` pixels away from the bottom
  /// (or the top if [reverse] is `true`).
  ///
  /// This value must be `0.0` or greater, is set to `400.0` by default and
  /// cannot be `null`.
  final double scrollExtentThreshold;

  /// The duration with which calls to [onFetchData] will be debounced.
  ///
  /// Is set to a duration of 100 milliseconds by default and cannot be `null`.
  final Duration debounceDuration;

  /// Indicates if the list should be reversed.
  ///
  /// If set to `true`, the list of items, [loadingBuilder] and [errorBuilder]
  /// will be rendered from bottom to top.
  final bool reverse;

  /// The amount of items that need to be rendered by the [itemBuilder].
  ///
  /// Is required and cannot be `null`.
  final int itemCount;

  /// Indicates if new items are currently being loaded.
  ///
  /// While set to `true`, the [onFetchData] callback will not be triggered
  /// and the [loadingBuilder] will be rendered.
  ///
  /// Is set to `false` by default and cannot be `null`.
  final bool isLoading;

  /// Indicates if an error has occurred.
  ///
  /// While set to `true`, the [onFetchData] callback will not be triggered
  /// and the [errorBuilder] will be rendered.
  ///
  /// Is set to `false` by default and cannot be `null`.
  final bool hasError;

  /// Indicates if the end of the data source has been reached and no more
  /// data can be fetched.
  ///
  /// While set to `true`, the [onFetchData] callback will not be triggered.
  ///
  /// Is set to `false` by default and cannot be `null`.
  final bool hasReachedMax;

  /// The callback method that's called whenever the list is scrolled to the end
  /// (meaning the top when [reverse] is `true`, or the bottom otherwise).
  ///
  /// In normal operation, this method should trigger new data to be fetched and
  /// [isLoading] to be set to `true`.
  ///
  /// Exactly when this is called depends on the [scrollExtentThreshold].
  /// Additionally, every call to this will be debounced by the provided
  /// [debounceDuration].
  ///
  /// Is required and cannot be `null`.
  final VoidCallback onFetchData;

  /// The amount of space by which to inset the list of items.
  ///
  /// Is optional and can be `null`.
  final EdgeInsets? padding;

  /// An optional builder that's shown when the list of items is empty.
  ///
  /// If `null`, nothing is shown.
  final WidgetBuilder? emptyBuilder;

  /// An optional builder that's shown at the end of the list when [isLoading]
  /// is `true`.
  ///
  /// If `null`, a default builder is used that renders a centered
  /// [CircularProgressIndicator].
  final WidgetBuilder? loadingBuilder;

  /// An optional builder that's shown when [hasError] is not `null`.
  ///
  /// If `null`, a default builder is used that renders the text `"Error"`.
  final WidgetBuilder? errorBuilder;

  /// An optional builder that, when provided, is used to show a widget in
  /// between every pair of items.
  ///
  /// If the [itemBuilder] returns a [ListTile], this is commonly used to render
  /// a [Divider] between every tile.
  ///
  /// Is optional and can be `null`.
  final WidgetBuilder? separatorBuilder;

  /// The builder used to build a widget for every index of the `itemCount`.
  ///
  /// Is required and cannot be `null`.
  final ItemBuilder itemBuilder;

  @override
  InfiniteListState createState() => InfiniteListState();
}

/// The state of an [InfiniteList].
///
/// Is only used for internal purposes. Do not use this class directly.
@protected
@visibleForTesting
class InfiniteListState extends State<InfiniteList> {
  late final CallbackDebouncer _debounce;

  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _debounce = CallbackDebouncer(widget.debounceDuration);
    _initScrollController();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _attemptFetch();
    });
  }

  @override
  void didUpdateWidget(InfiniteList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.scrollController != oldWidget.scrollController) {
      _initScrollController();
    }

    if (widget.itemCount != oldWidget.itemCount ||
        widget.hasReachedMax != oldWidget.hasReachedMax) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        _attemptFetch();
      });
    }
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_attemptFetch);
    if (widget.scrollController == null) {
      _scrollController?.dispose();
    }
    _debounce.dispose();
    super.dispose();
  }

  void _initScrollController() {
    _scrollController?.removeListener(_attemptFetch);
    _scrollController?.dispose();

    _scrollController = (widget.scrollController ?? ScrollController())
      ..addListener(_attemptFetch);
  }

  void _attemptFetch() {
    if (_isAtEnd &&
        !widget.hasReachedMax &&
        !widget.isLoading &&
        !widget.hasError) {
      _debounce(widget.onFetchData);
    }
  }

  bool get _isAtEnd {
    if (widget.itemCount == 0) {
      return true;
    }

    if (!_scrollController!.hasClients) {
      return false;
    }

    final maxScroll = _scrollController!.position.maxScrollExtent;
    final currentScroll = _scrollController!.offset;
    return currentScroll >= (maxScroll - widget.scrollExtentThreshold);
  }

  WidgetBuilder get _loadingBuilder =>
      widget.loadingBuilder ??
      (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      };

  WidgetBuilder get _errorBuilder =>
      widget.errorBuilder ??
      (context) {
        return const Center(
          child: Text('Error'),
        );
      };

  @override
  Widget build(BuildContext context) {
    final hasItems = widget.itemCount != 0;

    final showEmpty = !widget.isLoading &&
        widget.itemCount == 0 &&
        widget.emptyBuilder != null;
    final showBottomWidget = showEmpty || widget.isLoading || widget.hasError;
    final showSeparator = widget.separatorBuilder != null;
    final separatorCount = !showSeparator ? 0 : widget.itemCount - 1;

    final itemCount = (!hasItems ? 0 : widget.itemCount + separatorCount) +
        (showBottomWidget ? 1 : 0);
    final lastItemIndex = itemCount - 1;

    return ListView.builder(
      controller: _scrollController,
      physics: widget.physics,
      reverse: widget.reverse,
      padding: widget.padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == lastItemIndex && showBottomWidget) {
          if (widget.hasError) {
            return _errorBuilder(context);
          } else if (widget.isLoading) {
            return _loadingBuilder(context);
          } else {
            return widget.emptyBuilder!(context);
          }
        } else {
          if (showSeparator && index.isOdd) {
            return widget.separatorBuilder!(context);
          } else {
            final itemIndex = !showSeparator ? index : (index / 2).floor();
            return widget.itemBuilder(context, itemIndex);
          }
        }
      },
    );
  }
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
