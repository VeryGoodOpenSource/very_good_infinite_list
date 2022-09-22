import 'package:flutter/material.dart';
import 'package:very_good_infinite_list/src/infinite_list.dart';

/// The type definition for the [InfiniteList.itemBuilder].
typedef ItemBuilder = Widget Function(BuildContext context, int index);

/// Default value to [InfiniteList.loadingBuilder].
/// Renders a centered [CircularProgressIndicator].
Widget defaultInfiniteListLoadingBuilder(BuildContext buildContext) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

/// Default value to [InfiniteList.loadingBuilder].
/// Renders a centered [Text] "error".
Widget defaultInfiniteListErrorBuilder(BuildContext buildContext) {
  return const Center(
    child: Text('Error'),
  );
}

/// Default value to [InfiniteList.scrollExtentThreshold].
const defaultScrollExtentThreshold = 400.0;

/// Default value to [InfiniteList.debounceDuration].
const defaultDebounceDuration = Duration(milliseconds: 100);
