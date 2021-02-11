# Very Good Infinite List

[![Very Good Ventures][very_good_ventures_logo]][very_good_ventures_link]

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![pub package][pub_badge]][pub_link]
[![License: MIT][license_badge]][license_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_badge_link]

---

A Very Good Infinite List Widget used internally at [Very Good Ventures][very_good_ventures_link].

## Usage

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

[ci_badge]: https://github.com/VeryGoodOpenSource/very_good_infinite_list/workflows/ci/badge.svg
[ci_link]: https://github.com/VeryGoodOpenSource/very_good_infinite_list/actions
[coverage_badge]: coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[pub_badge]: https://img.shields.io/pub/v/very_good_infinite_list.svg
[pub_link]: https://pub.dartlang.org/packages/very_good_infinite_list
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_badge_link]: https://pub.dev/packages/very_good_analysis
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_logo]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_analysis/main/assets/vgv_logo.png
