import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:very_good_infinite_list/src/callback_debouncer.dart';
import 'package:very_good_infinite_list/src/defaults.dart';
import 'package:very_good_infinite_list/src/infinite_list.dart';

/// The sliver version of [InfiniteList].
///
/// {@macro infinite_list}
///
/// As a infinite list, it is supposed to be the last sliver in the current
/// [ScrollView]. Otherwise, re-fetching data will have an unintuitive behavior.
class SliverInfiniteList extends StatelessWidget {
  /// Constructs a [SliverInfiniteList].
  const SliverInfiniteList({
    super.key,
    required this.itemCount,
    required this.onFetchData,
    required this.itemBuilder,
    this.scrollExtentThreshold = defaultScrollExtentThreshold,
    this.debounceDuration = defaultDebounceDuration,
    this.isLoading = false,
    this.hasError = false,
    this.hasReachedMax = false,
    this.loadingBuilder,
    this.errorBuilder,
    this.separatorBuilder,
    this.emptyBuilder,
  }) : assert(
          scrollExtentThreshold >= 0.0,
          'scrollExtentThreshold must be greater than or equal to 0.0',
        );

  /// {@macro scroll_extent_threshold}
  final double scrollExtentThreshold;

  /// {@macro debounce_duration}
  final Duration debounceDuration;

  /// {@macro item_count}
  final int itemCount;

  /// {@macro is_loading}
  final bool isLoading;

  /// {@macro has_error}
  final bool hasError;

  /// {@macro has_reached_max}
  final bool hasReachedMax;

  /// {@macro on_fetch_data}
  final VoidCallback onFetchData;

  /// {@macro empty_builder}
  final WidgetBuilder? emptyBuilder;

  /// {@macro loading_builder}
  final WidgetBuilder? loadingBuilder;

  /// {@macro error_builder}
  final WidgetBuilder? errorBuilder;

  /// {@macro separator_builder}
  final WidgetBuilder? separatorBuilder;

  /// {@macro item_builder}
  final ItemBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        return _SliverInfiniteListInternal(
          itemCount: itemCount,
          onFetchData: onFetchData,
          itemBuilder: itemBuilder,
          scrollExtentThreshold: scrollExtentThreshold,
          debounceDuration: debounceDuration,
          isLoading: isLoading,
          hasError: hasError,
          hasReachedMax: hasReachedMax,
          precedingScrollExtent: constraints.precedingScrollExtent,
          loadingBuilder: loadingBuilder,
          errorBuilder: errorBuilder,
          separatorBuilder: separatorBuilder,
          emptyBuilder: emptyBuilder,
        );
      },
    );
  }
}

class _SliverInfiniteListInternal extends StatefulWidget {
  const _SliverInfiniteListInternal({
    required this.itemCount,
    required this.onFetchData,
    required this.itemBuilder,
    required this.scrollExtentThreshold,
    required this.debounceDuration,
    required this.isLoading,
    required this.hasError,
    required this.hasReachedMax,
    required this.precedingScrollExtent,
    this.loadingBuilder,
    this.errorBuilder,
    this.separatorBuilder,
    this.emptyBuilder,
  });

  final double scrollExtentThreshold;

  final Duration debounceDuration;

  final int itemCount;

  final bool isLoading;

  final bool hasError;

  final bool hasReachedMax;

  final VoidCallback onFetchData;

  /// See [SliverConstraints.precedingScrollExtent]
  final double precedingScrollExtent;

  final WidgetBuilder? loadingBuilder;

  final WidgetBuilder? errorBuilder;

  final WidgetBuilder? separatorBuilder;

  final ItemBuilder itemBuilder;

  final WidgetBuilder? emptyBuilder;

  @override
  State<_SliverInfiniteListInternal> createState() =>
      _SliverInfiniteListInternalState();
}

class _SliverInfiniteListInternalState
    extends State<_SliverInfiniteListInternal> {
  late final CallbackDebouncer debounce;

  ScrollPosition? scrollPosition;

  @override
  void initState() {
    super.initState();
    debounce = CallbackDebouncer(widget.debounceDuration);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      attemptFetch();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    detachFromPosition();
    scrollPosition = Scrollable.of(context)?.position;
    attachToPosition();
  }

  @override
  void didUpdateWidget(_SliverInfiniteListInternal oldWidget) {
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
    // position to trigger a data fetch. It may cause unintuitive behaviors
    // when there is any sliver after this one.
    final maxScroll = scrollPosition.maxScrollExtent;

    final currentScroll = scrollPosition.pixels - widget.precedingScrollExtent;
    return currentScroll >= (maxScroll - widget.scrollExtentThreshold);
  }

  WidgetBuilder get loadingBuilder =>
      widget.loadingBuilder ?? defaultInfiniteListLoadingBuilder;

  WidgetBuilder get errorBuilder =>
      widget.errorBuilder ?? defaultInfiniteListErrorBuilder;

  @override
  Widget build(BuildContext context) {
    final hasItems = widget.itemCount != 0;

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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: effectiveItemCount,
        (context, index) {
          if (index == lastItemIndex && showBottomWidget) {
            if (widget.hasError) {
              return errorBuilder(context);
            } else if (widget.isLoading) {
              return loadingBuilder(context);
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
      ),
    );
  }
}
