# Very Good Infinite List

[![Very Good Ventures][logo_white]][very_good_ventures_link_dark]
[![Very Good Ventures][logo_black]][very_good_ventures_link_light]

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![pub package][pub_badge]][pub_link]
[![License: MIT][license_badge]][license_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_badge_link]

---

A library for easily displaying paginated data, created by [Very Good Ventures][very_good_ventures_link].

`InfiniteList` comes in handy when building features like activity feeds, news feeds, or anywhere else where you need to lazily fetch and render content for users to consume.

## Example

<a href="https://github.com/VeryGoodOpenSource/very_good_infinite_list/blob/main/example/lib/main.dart"><img src="https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_infinite_list/main/art/infinite_list.gif" height="400"/></a>

## Usage

The `InfiniteList` API is very similar to that of `ListView.builder`. A basic implementation requires four parameters:

- An `itemCount` that represents the amount of items that should be rendered using the `itemBuilder`.
- An `itemBuilder` that is responsible for returning a widget for every index of the `itemCount`.
- An `hasReachedMax` flag that indicates if any more data is available.
- An `onFetchData` callback that's triggered whenever new data should be fetched.

## Example

```dart
import 'package:flutter/material.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
 var _items = <String>[];
  var _isLoading = false;

  void _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _items = List.generate(_items.length + 10, (i) => 'Item $i');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Example'),
      ),
      body: InfiniteList(
        itemCount: _items.length,
        hasReachedMax: false,
        isLoading: _isLoading,
        onFetchData: _fetchData,
        separatorBuilder: (context) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            title: Text(_items[index]),
          );
        },
      ),
    );
  }
}
```

### Customizations

#### InfiniteList

`InfiniteList` has multiple optional parameters which allow you to customize the loading and error behavior.

```dart
InfiniteList<String>(
  itemCount: 3,
  hasReachedMax: false,
  onFetchData: () => _fetchData(),
  itemBuilder: (context, index) => ListTile(title: Text('$index')),

  // An optional [ScrollController] this [InfiniteList] will attach to.
  // It's used to detect when the list has scrolled to the appropriate position
  // to call [onFetchData].
  //
  // Is optional and mostly used only for testing. If set to `null`, an
  // internal [ScrollController] is used instead.
  scrollController: _scrollController,

  // Indicates if new items are currently being loaded.
  //
  // While set to `true`, the [onFetchData] callback will not be triggered
  // and the [loadingBuilder] will be rendered.
  //
  // Is set to `false` by default and cannot be `null`.
  isLoading: false,

  // Indicates if an error has occurred.
  //
  // While set to `true`, the [onFetchData] callback will not be triggered
  // and the [errorBuilder] will be rendered.
  //
  // Is set to `false` by default and cannot be `null`.
  hasError: false,

  // Indicates if the list should be reversed.
  //
  // If set to `true`, the list of items, [loadingBuilder] and [errorBuilder]
  // will be rendered from bottom to top.
  reverse: false,

  // The duration with which calls to [onFetchData] will be debounced.
  //
  // Is set to a duration of 100 milliseconds by default and cannot be `null`.
  debounceDuration: const Duration(milliseconds: 100),

  // The offset, in pixels, that the [scrollController] must be scrolled over
  // to trigger [onFetchData].
  //
  // This is useful for fetching data _before_ the user has scrolled all the
  // way to the end of the list, so the fetching mechanism is more well hidden.
  //
  // For example, if this is set to `400.0` (the default), [onFetchData] will
  // be called when the list is scrolled `400.0` pixels away from the bottom
  // (or the top if [reverse] is `true`).
  //
  // This value must be `0.0` or greater, is set to `400.0` by default and
  // cannot be `null`.
  scrollExtentThreshold: 400.0,

  // The amount of space by which to inset the list of items.
  //
  // Is optional and can be `null`.
  padding: const EdgeInsets.all(16.0),

  // An optional builder that's shown when the list of items is empty.
  //
  // If `null`, nothing is shown.
  emptyBuilder: () => const Center(child: Text('No items.')),

  // An optional builder that's shown at the end of the list when [isLoading]
  // is `true`.
  //
  // If `null`, a default builder is used that renders a centered
  // [CircularProgressIndicator].
  loadingBuilder: () => const Center(child: CircularProgressIndicator()),

  // An optional builder that's shown when [hasError] is not `null`.
  //
  // If `null`, a default builder is used that renders the text `"Error"`.
  errorBuilder: () => const Center(child: Text('Error')),

  // An optional builder that, when provided, is used to show a widget in
  // between every pair of items.
  //
  // If the [itemBuilder] returns a [ListTile], this is commonly used to render
  // a [Divider] between every tile.
  //
  // Is optional and can be `null`.
  separatorBuilder: () => const Divider(),
);
```

Refer to the [example](https://github.com/VeryGoodOpenSource/very_good_infinite_list/blob/main/example/lib/main.dart) to see both basic and complex usage of `InfiniteList`.

[ci_badge]: https://github.com/VeryGoodOpenSource/very_good_infinite_list/workflows/ci/badge.svg
[ci_link]: https://github.com/VeryGoodOpenSource/very_good_infinite_list/actions
[coverage_badge]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_infinite_list/main/coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[pub_badge]: https://img.shields.io/pub/v/very_good_infinite_list.svg
[pub_link]: https://pub.dartlang.org/packages/very_good_infinite_list
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_badge_link]: https://pub.dev/packages/very_good_analysis
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
