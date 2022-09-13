import 'package:flutter/material.dart';
import 'package:very_good_infinite_list/src/callback_debouncer.dart';
import 'package:very_good_infinite_list/src/infinite_list_binder.dart';

/// The type definition for the [InfiniteList.itemBuilder].
typedef ItemBuilder = Widget Function(BuildContext context, int index);


Widget defaultInfiniteListLoadingBuilder(BuildContext buildContext) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

Widget defaultInfiniteListErrorBuilder(BuildContext buildContext) {
  return const Center(
    child: Text('Error'),
  );
}

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
class InfiniteList extends StatefulWidget with InfiniteListWidget {
  /// {@macro infinite_list}
  const InfiniteList({
    super.key,
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
        )

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

  /// {@template scroll_extent_threshold}
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
  /// {@endtemplate}
  @override
  final double scrollExtentThreshold;

  /// {@template debounce_duration}
  /// The duration with which calls to [onFetchData] will be debounced.
  ///
  /// Is set to a duration of 100 milliseconds by default and cannot be `null`.
  /// {@endtemplate}
  @override
  final Duration debounceDuration;

  /// Indicates if the list should be reversed.
  ///
  /// If set to `true`, the list of items, [loadingBuilder] and [errorBuilder]
  /// will be rendered from bottom to top.
  final bool reverse;

  /// {@template item_count}
  /// The amount of items that need to be rendered by the [itemBuilder].
  ///
  /// Is required and cannot be `null`.
  /// {@endtemplate}
  @override
  final int itemCount;

  /// Indicates if new items are currently being loaded.
  ///
  /// While set to `true`, the [onFetchData] callback will not be triggered
  /// and the [loadingBuilder] will be rendered.
  ///
  /// Is set to `false` by default and cannot be `null`.
  @override
  final bool isLoading;

  /// Indicates if an error has occurred.
  ///
  /// While set to `true`, the [onFetchData] callback will not be triggered
  /// and the [errorBuilder] will be rendered.
  ///
  /// Is set to `false` by default and cannot be `null`.
  @override
  final bool hasError;

  /// Indicates if the end of the data source has been reached and no more
  /// data can be fetched.
  ///
  /// While set to `true`, the [onFetchData] callback will not be triggered.
  ///
  /// Is set to `false` by default and cannot be `null`.
  @override
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
  @override
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
  State<InfiniteList> createState() => _InfiniteListState();
}

/// The state of an [InfiniteList].
///
/// Is only used for internal purposes. Do not use this class directly.
class _InfiniteListState extends State<InfiniteList> with InfiniteListStateBind {
  ScrollController? _internalScrollController;
  late ScrollController _scrollController;

  @override
  ScrollPosition? get scrollPosition =>
      _scrollController.hasClients ? _scrollController.position : null;

  @override
  void initState() {
    super.initState();
    _updateScrollController();
  }

  @override
  void didUpdateWidget(InfiniteList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.scrollController != oldWidget.scrollController) {
      detachFromPosition();
      _updateScrollController();
      attachToPosition();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _internalScrollController?.dispose();
  }

  void _updateScrollController() {
    _internalScrollController?.dispose();
    _scrollController = widget.scrollController ??
        (_internalScrollController ??= ScrollController());
  }

  WidgetBuilder get _loadingBuilder =>
      widget.loadingBuilder ?? defaultInfiniteListLoadingBuilder;

  WidgetBuilder get _errorBuilder =>
      widget.errorBuilder ?? defaultInfiniteListErrorBuilder;

  @override
  double get precedingScrollExtent => 0;

  @override
  Widget build(BuildContext context) {
    final showEmpty = !widget.isLoading &&
        widget.itemCount == 0 &&
        widget.emptyBuilder != null;
    final showBottomWidget = showEmpty || widget.isLoading || widget.hasError;
    final showSeparator = widget.separatorBuilder != null;
    final separatorCount = !showSeparator ? 0 : widget.itemCount - 1;

    final effectiveItemCount =
        (!hasItems ? 0 : widget.itemCount + separatorCount) +
            (showBottomWidget ? 1 : 0);
    final lastItemIndex = effectiveItemCount - 1;

    return ListView.builder(
      controller: _scrollController,
      physics: widget.physics,
      reverse: widget.reverse,
      padding: widget.padding,
      itemCount: effectiveItemCount,
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
