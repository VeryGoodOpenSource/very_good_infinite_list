import 'package:flutter/widgets.dart';
import 'package:very_good_infinite_list/src/infinite_list.dart';
import 'package:very_good_infinite_list/src/loading_indicator.dart';

/// The type definition for the [InfiniteList.itemBuilder].
typedef ItemBuilder = Widget Function(BuildContext context, int index);

/// Default value to [InfiniteList.loadingBuilder].
/// Renders a centered [InfiniteListLoadingIndicator].
Widget defaultInfiniteListLoadingBuilder(BuildContext buildContext) {
  return const Center(child: InfiniteListLoadingIndicator());
}

/// Default value to [InfiniteList.loadingBuilder].
/// Renders a centered [Text] "error".
Widget defaultInfiniteListErrorBuilder(BuildContext buildContext) {
  return const Center(child: Text('Error'));
}

/// Default value to [InfiniteList.debounceDuration].
const defaultDebounceDuration = Duration(milliseconds: 100);
