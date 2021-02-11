# Very Good Infinite List

[![Very Good Ventures][very_good_ventures_logo]][very_good_ventures_link]

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![pub package][pub_badge]][pub_link]
[![License: MIT][license_badge]][license_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_badge_link]

---

A Very Good Infinite List Widget created by [Very Good Ventures][very_good_ventures_link].

`InfiniteList` comes in handy when building features like activity feeds, news feeds, or anywhere else where you need to lazily fetch and render content for users to consume.

## Example

<a href="https://github.com/VeryGoodOpenSource/very_good_infinite_list/blob/main/example/lib/main.dart"><img src="https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_infinite_list/main/art/infinite_list.gif" height="400"/></a>

## Usage

A basic `InfiniteList` requires two parameters:

- `itemLoader` which is responsible for asynchronously fetching the content
- `builder` which is responsible for returning a `Widget` given a specific item (result)

```dart
import 'package:flutter/material.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

void main() => runApp(MyApp());

Future<List<String>> _itemLoader(int limit, {int start = 0}) {
  return Future.delayed(
    const Duration(seconds: 1),
    () => List.generate(limit, (index) => 'Item ${start + index}'),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Infinite List')),
        body: InfiniteList<String>(
          itemLoader: _itemLoader,
          builder: InfiniteListBuilder<String>(
            success: (context, item) => ListTile(title: Text(item)),
          ),
        ),
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
  itemLoader: _itemLoader,
  builder: InfiniteListBuilder<String>(...),
  bottomLoader: (context) {
    // Return a custom widget which will be rendered at the bottom of the list
    // while more content is being loaded.
  },
  errorLoader: (context, retry, error) {
    // Return a custom widget which will be rendered when `itemLoader`
    // throws a generic `Exception` and there is prior content loaded.
    // `retry` can be invoked to attempt to reload the content.
  },
  // How long to wait between attempts to load items.
  // Defaults to 100ms.
  debounceDuration: Duration.zero,
  // What percentage of the screen should be scrolled before
  // attempting to load additional items.
  // Defaults to 0.7 (70% from the top).
  scrollOffsetThreshold: 0.5,
);
```

#### InfiniteListBuilder

`InfiniteListBuilder` has multiple optional parameters which allow you to render different widgets in response to various states that the `InfiniteList` can be in.

```dart
InfiniteList<String>(
  itemLoader: _itemLoader,
  builder: InfiniteListBuilder<String>(
    empty: (context) {
      // Return a custom widget when `itemLoader` returns an empty list
      // and there is no prior content.
    },
    loading: (context) {
      // Return a custom widget when `itemLoader` is in the process of
      // fetching results and there is no prior content
    },
    success: (context, item) {
      // Return a custom widget when `itemLoader` has returned content.
      // Here item refers to a specific result.
      // This builder will be called multiple times as different results
      // come into view.
    },
    error: (context, retry, error) {
      // Return a custom widget when `itemLoader` throws an `InfiniteListException`.
      // `error` will also be called when `itemLoader` throws any `Exception`
      // if there is no prior content.
    },
  ),
);
```

Refer to the [example](https://github.com/VeryGoodOpenSource/very_good_infinite_list/blob/main/example/lib/main.dart) to see both basic and complex usage of `InfiniteList`.

[ci_badge]: https://github.com/VeryGoodOpenSource/very_good_infinite_list/workflows/ci/badge.svg
[ci_link]: https://github.com/VeryGoodOpenSource/very_good_infinite_list/actions
[coverage_badge]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_infinite_list/main/coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[pub_badge]: https://img.shields.io/pub/v/very_good_infinite_list.svg
[pub_link]: https://pub.dartlang.org/packages/very_good_infinite_list
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_badge_link]: https://pub.dev/packages/very_good_analysis
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_logo]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_analysis/main/assets/vgv_logo.png
