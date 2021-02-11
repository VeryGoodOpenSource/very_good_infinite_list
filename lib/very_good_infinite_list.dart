library very_good_infinite_list;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Exception which can be thrown by the [ItemLoader] and
/// will trigger the `error` [WidgetBuilder] within the
/// [InfiniteListBuilder].
class InfiniteListException implements Exception {}

/// Function which given a [limit] and [start] is responsible for returning
/// a Future of [List<T>]. [ItemLoader] is used by [InfiniteList] to request
/// content lazily.
///
/// * [limit] is the number of items you'd like to fetch.
/// * [start] is an optional offset which defaults to 0.
typedef ItemLoader<T> = Future<List<T>> Function(int limit, {int start});

/// Function which returns a [Widget] given a [context], [retry], and [error].
/// Used by [InfiniteList] to render widgets in response to exceptions thrown
/// by [ItemLoader].
typedef ErrorBuilder = Widget Function(
  BuildContext context,
  VoidCallback retry,
  Object error,
);

/// {@template on_error}
/// Function which is called whenever an exception is thrown by
/// the [ItemLoader]. It can be used to perform a side-effect in response
/// to any exception.
/// {@endtemplate}
typedef OnError = void Function(
  BuildContext context,
  VoidCallback retry,
  Object error,
);

/// {@template infinite_list_builder}
/// A collection of [WidgetBuilder]s which are invoked based on the
/// various states that the [InfiniteList] can be in.
/// {@endtemplate}
class InfiniteListBuilder<T> {
  /// {@macro infinite_list_builder}
  const InfiniteListBuilder({
    @required this.success,
    WidgetBuilder loading,
    ErrorBuilder error,
    WidgetBuilder empty,
  })  : _loading = loading,
        _error = error,
        _empty = empty;

  final WidgetBuilder _loading;

  /// [WidgetBuilder] which is invoked when the [InfiniteList]
  /// is rendered while content is being fetched by the [ItemLoader].
  WidgetBuilder get loading {
    return _loading ??
        (_) => const Center(
              key: Key('__default_loading__'),
              child: CircularProgressIndicator(),
            );
  }

  /// [WidgetBuilder] which is invoked when the [InfiniteList]
  /// is rendered when content has been successfully
  /// retrieved from the [ItemLoader].
  final Widget Function(BuildContext, T) success;

  final ErrorBuilder _error;

  /// [WidgetBuilder] which is invoked when the [InfiniteList]
  /// is rendered and an [InfiniteListException]
  /// has been thrown by the [ItemLoader].
  ErrorBuilder get error {
    return _error ??
        (_, retry, error) {
          return _DefaultError(
            key: const Key('__default_error__'),
            retry: retry,
            error: error,
          );
        };
  }

  final WidgetBuilder _empty;

  /// [WidgetBuilder] which is invoked when the [InfiniteList]
  /// is rendered and the [ItemLoader] has returned an empty list.
  WidgetBuilder get empty =>
      _empty ?? (_) => const SizedBox(key: Key('__default_empty__'));
}

/// {@template infinite_list}
/// A widget which renders an infinite list
/// using an [ItemLoader] and [InfiniteListBuilder].
///
/// ```dart
///
/// ```
///
/// {@endtemplate}
class InfiniteList<T> extends StatefulWidget {
  /// {@macro infinite_list}
  const InfiniteList({
    Key key,
    @required this.itemLoader,
    @required this.builder,
    WidgetBuilder bottomLoader,
    ErrorBuilder errorLoader,
    this.debounce,
    this.onError,
    double scrollOffsetThreshold,
  })  : assert(itemLoader != null),
        assert(builder != null),
        _bottomLoader = bottomLoader,
        _errorLoader = errorLoader,
        _scrollOffsetThreshold = scrollOffsetThreshold ?? 0.9,
        super(key: key);

  /// {@macro infinite_list_builder}
  final InfiniteListBuilder<T> builder;

  /// The instance of an [ItemLoader] which is used by the [InfiniteList]
  /// to lazily fetch content.
  final ItemLoader<T> itemLoader;

  final WidgetBuilder _bottomLoader;

  /// [WidgetBuilder] which is responsible for rendering the bottom loader
  /// widget which is rendered when the user scrolls to the bottom of the list
  /// while new content is being loaded.
  WidgetBuilder get bottomLoader {
    return _bottomLoader ??
        (_) => const Center(
              key: Key('__default_bottom_loader__'),
              child: CircularProgressIndicator(),
            );
  }

  final ErrorBuilder _errorLoader;

  /// [WidgetBuilder] which is responsible for rendering the bottom loader
  /// widget which is rendered when additional content is unable to be loaded
  /// due to an exception.
  ///
  /// A `retry` callback is available to retry the failed request.
  ErrorBuilder get errorLoader =>
      _errorLoader ??
      (_, retry, __) => _DefaultErrorLoader(
            key: const Key('__default_error_loader__'),
            retry: retry,
          );

  /// {@macro on_error}
  final OnError onError;

  /// Debounce duration for the [itemLoader].
  /// Defaults to `const Duration(milliseconds: 300)`.
  final Duration debounce;

  final double _scrollOffsetThreshold;

  @override
  _InfiniteListState<T> createState() => _InfiniteListState<T>();
}

class _InfiniteListState<T> extends State<InfiniteList<T>> {
  final _scrollController = ScrollController();
  _ListCubit<T> _cubit;
  _Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = _Debouncer(delay: widget.debounce);
    _cubit = _ListCubit<T>(itemLoader: widget.itemLoader)..fetch();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _cubit.close();
    _debouncer?.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<_ListCubit<T>, _ListState<T>>(
      cubit: _cubit,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status.isFailure) {
          widget.onError?.call(context, _cubit.fetch, state.exception.value);
        }
      },
      builder: (context, state) {
        final itemCount = state.hasReachedMax == false
            ? state.items.length + 1
            : state.items.length;

        if (state.status == _ListStatus.loading) {
          return widget.builder.loading(context);
        }

        if (state.items.isEmpty) {
          return state.exception != _ListException.none
              ? widget.builder.error(
                  context,
                  _cubit.fetch,
                  state.exception.value,
                )
              : widget.builder.empty(context);
        }

        if (state.exception.value is InfiniteListException) {
          return widget.builder.error(
            context,
            _cubit.fetch,
            state.exception.value,
          );
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return index >= state.items.length
                ? state.exception != _ListException.none
                    ? widget.errorLoader(
                        context,
                        _cubit.fetch,
                        state.exception.value,
                      )
                    : widget.bottomLoader(context)
                : widget.builder.success(context, state.items[index]);
          },
        );
      },
    );
  }

  void _onScroll() {
    if (_isBottom) {
      _debouncer(_cubit.fetch);
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * widget._scrollOffsetThreshold);
  }
}

class _DefaultError extends StatelessWidget {
  const _DefaultError({
    Key key,
    this.error,
    this.retry,
  }) : super(key: key);

  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$error',
            style: theme.textTheme.headline4.copyWith(color: theme.errorColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: retry,
          ),
        ],
      ),
    );
  }
}

class _DefaultErrorLoader extends StatelessWidget {
  const _DefaultErrorLoader({Key key, @required this.retry}) : super(key: key);
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(icon: const Icon(Icons.refresh), onPressed: retry),
    );
  }
}

enum _ListStatus { loading, success, failure }

extension on _ListStatus {
  bool get isFailure => this == _ListStatus.failure;
}

class _ListException implements Exception {
  const _ListException(this.value);
  final Object value;

  static const none = _ListException(null);
}

class _ListState<T> {
  const _ListState({
    this.currentIndex = 0,
    this.items = const [],
    this.status = _ListStatus.loading,
    this.hasReachedMax = false,
    this.exception = _ListException.none,
  });

  final int currentIndex;
  final List<T> items;
  final _ListStatus status;
  final bool hasReachedMax;
  final _ListException exception;

  _ListState<T> copyWith({
    @required _ListStatus status,
    int currentIndex,
    List<T> items,
    bool hasReachedMax,
    _ListException exception,
  }) {
    return _ListState<T>(
      currentIndex: currentIndex ?? this.currentIndex,
      items: items ?? this.items,
      status: status,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      exception: exception ?? this.exception,
    );
  }
}

class _ListCubit<T> extends Cubit<_ListState<T>> {
  _ListCubit({@required this.itemLoader}) : super(_ListState<T>());

  final ItemLoader<T> itemLoader;

  void fetch({int limit = 20}) async {
    if (state.hasReachedMax) return;

    if (state.currentIndex == 0 && state.items.isEmpty) {
      emit(state.copyWith(status: _ListStatus.loading));
    }

    if (state.status.isFailure) {
      if (state.exception.value is InfiniteListException) {
        emit(
          state.copyWith(
            exception: _ListException.none,
            status: _ListStatus.loading,
          ),
        );
      } else {
        emit(
          state.copyWith(
            exception: _ListException.none,
            status: state.items.isEmpty ? _ListStatus.loading : state.status,
          ),
        );
      }
    }

    try {
      final items = await itemLoader(limit, start: state.currentIndex);

      if (items == null || items.isEmpty) {
        return emit(state.copyWith(
          hasReachedMax: true,
          status: _ListStatus.success,
        ));
      }

      emit(
        _ListState(
          currentIndex: state.currentIndex + items.length,
          items: List.of(state.items)..addAll(items),
          status: _ListStatus.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: _ListStatus.failure,
          exception: _ListException(e),
        ),
      );
    }
  }
}

class _Debouncer {
  _Debouncer({Duration delay})
      : _delay = delay ?? const Duration(milliseconds: 300);

  final Duration _delay;
  Timer _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(_delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
