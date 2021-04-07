import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The type definition for the [InfiniteList.itemBuilder].
typedef ItemBuilder<T> = Widget Function(BuildContext context, T item);

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
/// The [items], [hasReachedMax], [onFetchData] and [itemBuilder] must be
/// provided and cannot be `null`.
/// {@endtemplate}
class InfiniteList<T> extends StatefulWidget {
  /// {@macro infinite_list}
  const InfiniteList({
    Key key,
    this.scrollController,
    this.scrollExtentThreshold = 400.0,
    this.debounceDuration = const Duration(milliseconds: 100),
    this.reverse = false,
    @required this.items,
    this.isLoading = false,
    this.hasError = false,
    @required this.hasReachedMax,
    @required this.onFetchData,
    this.padding,
    this.emptyBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.separatorBuilder,
    @required this.itemBuilder,
  })  : assert(scrollExtentThreshold != null),
        assert(scrollExtentThreshold >= 0.0),
        assert(debounceDuration != null),
        assert(reverse != null),
        assert(items != null),
        assert(isLoading != null),
        assert(hasError != null),
        assert(hasReachedMax != null),
        assert(onFetchData != null),
        assert(itemBuilder != null),
        super(key: key);

  /// An optional [ScrollController] this [InfiniteList] will attach to.
  /// It's used to detect when the list has scrolled to the appropriate position
  /// to call [onFetchData].
  ///
  /// Is optional and mostly used only for testing. If set to `null`, an
  /// internal [ScrollController] is used instead.
  final ScrollController scrollController;

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

  /// The list of items that need to be rendered by the [itemBuilder].
  ///
  /// Is required and cannot be `null`.
  final List<T> items;

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
  /// Is required and cannot be `null`.
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
  final EdgeInsets padding;

  /// An optional builder that's shown when the list of [items] is empty.
  ///
  /// If `null`, nothing is shown.
  final WidgetBuilder emptyBuilder;

  /// An optional builder that's shown at the end of the list when [isLoading]
  /// is `true`.
  ///
  /// If `null`, a default builder is used that renders a centered
  /// [CircularProgressIndicator].
  final WidgetBuilder loadingBuilder;

  /// An optional builder that's shown when [hasError] is not `null`.
  ///
  /// If `null`, a default builder is used that renders the text `"Error"`.
  final WidgetBuilder errorBuilder;

  /// An optional builder that, when provided, is used to show a widget in
  /// between every pair of items.
  ///
  /// If the [itemBuilder] returns a [ListTile], this is commonly used to render
  /// a [Divider] between every tile.
  ///
  /// Is optional and can be `null`.
  final WidgetBuilder separatorBuilder;

  /// The builder used to build every element of [items].
  ///
  /// Is required and cannot be `null`.
  final ItemBuilder<T> itemBuilder;

  @override
  _InfiniteListState<T> createState() => _InfiniteListState<T>();
}

class _InfiniteListState<T> extends State<InfiniteList<T>> {
  _Debouncer _debounce;
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _debounce = _Debouncer(widget.debounceDuration);
    _initScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptFetch();
    });
  }

  @override
  void didUpdateWidget(InfiniteList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.scrollController != oldWidget.scrollController) {
      _initScrollController();
    }

    if (!listEquals(widget.items, oldWidget.items)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _attemptFetch();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.dispose();
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
    if (widget.items.isEmpty) {
      return true;
    }

    if (!_scrollController.hasClients) {
      return false;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
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
    return ListView(
      controller: _scrollController,
      reverse: widget.reverse,
      padding: widget.padding,
      children: [
        if (!widget.isLoading &&
            widget.items.isEmpty &&
            widget.emptyBuilder != null)
          widget.emptyBuilder(context)
        else
          for (var i = 0; i < widget.items.length; i++) ...[
            if (i != 0 && widget.separatorBuilder != null)
              widget.separatorBuilder(context),
            widget.itemBuilder(context, widget.items[i]),
          ],
        if (widget.hasError)
          _errorBuilder(context)
        else if (widget.isLoading)
          _loadingBuilder(context),
      ],
    );
  }
}

class _Debouncer {
  _Debouncer(this._delay);

  final Duration _delay;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(_delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
