import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:very_good_infinite_list/src/infinite_list_binder.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

class SliverInfiniteList extends StatelessWidget {
  const SliverInfiniteList({
    super.key,
    required this.itemCount,
    required this.onFetchData,
    required this.itemBuilder,
    this.scrollExtentThreshold = 400.0,
    this.debounceDuration = const Duration(milliseconds: 100),
    this.isLoading = false,
    this.hasError = false,
    this.hasReachedMax = false,
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

  final WidgetBuilder? loadingBuilder;

  final WidgetBuilder? errorBuilder;

  final WidgetBuilder? separatorBuilder;

  final ItemBuilder itemBuilder;

  final WidgetBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(builder: (context, constraints) {
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
    });
  }
}

class _SliverInfiniteListInternal extends StatefulWidget
    with InfiniteListWidget {
  const _SliverInfiniteListInternal({
    super.key,
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

  @override
  final double scrollExtentThreshold;

  @override
  final Duration debounceDuration;

  @override
  final int itemCount;

  @override
  final bool isLoading;

  @override
  final bool hasError;

  @override
  final bool hasReachedMax;

  @override
  final VoidCallback onFetchData;

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
    extends State<_SliverInfiniteListInternal> with InfiniteListStateBind {
  @override
  ScrollPosition? scrollPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    detachFromPosition();
    scrollPosition = Scrollable.of(context)?.position;
    attachToPosition();
  }

  WidgetBuilder get _loadingBuilder =>
      widget.loadingBuilder ?? defaultInfiniteListLoadingBuilder;

  WidgetBuilder get _errorBuilder =>
      widget.errorBuilder ?? defaultInfiniteListErrorBuilder;

  @override
  double get precedingScrollExtent => widget.precedingScrollExtent;

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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: effectiveItemCount,
        (context, index) {
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
      ),
    );
  }
}
