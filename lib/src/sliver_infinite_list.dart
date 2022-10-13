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
class SliverInfiniteList extends StatefulWidget {
  /// Constructs a [SliverInfiniteList].
  const SliverInfiniteList({
    super.key,
    required this.itemCount,
    required this.onFetchData,
    required this.itemBuilder,
    this.debounceDuration = defaultDebounceDuration,
    this.isLoading = false,
    this.hasError = false,
    this.hasReachedMax = false,
    this.loadingBuilder,
    this.errorBuilder,
    this.separatorBuilder,
    this.emptyBuilder,
  });

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
  State<SliverInfiniteList> createState() => _SliverInfiniteListState();
}

class _SliverInfiniteListState extends State<SliverInfiniteList> {
  late final CallbackDebouncer debounce;

  int? _lastFetchedIndex;

  @override
  void initState() {
    super.initState();
    debounce = CallbackDebouncer(widget.debounceDuration);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      attemptFetch();
    });
  }

  @override
  void didUpdateWidget(SliverInfiniteList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasReachedMax != oldWidget.hasReachedMax) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        attemptFetch();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    debounce.dispose();
  }

  void attemptFetch() {
    if (!widget.hasReachedMax && !widget.isLoading && !widget.hasError) {
      debounce(widget.onFetchData);
    }
  }

  void onBuiltLast(int lastItemIndex) {
    if (_lastFetchedIndex != lastItemIndex) {
      _lastFetchedIndex = lastItemIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        attemptFetch();
      });
    }
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
          if (index == lastItemIndex) {
            onBuiltLast(lastItemIndex);
          }
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
