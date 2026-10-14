import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:very_good_infinite_list/src/sliver_centralized.dart';

extension on WidgetTester {
  Future<void> pumpSlivers(List<Widget> slivers, {double? cacheExtent}) async {
    await pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        debugShowCheckedModeBanner: false,
        builder: (_, _) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 500,
            child: CustomScrollView(
              scrollCacheExtent: cacheExtent == null
                  ? null
                  : ScrollCacheExtent.pixels(cacheExtent),
              slivers: slivers,
            ),
          ),
        ),
      ),
    );
    await pump();
  }
}

void main() {
  testWidgets('widget should be at the center of scroll view', (tester) async {
    await tester.pumpSlivers([
      SliverCentralized(
        child: Container(
          height: 100,
          width: 100,
          color: const Color(0xFFF44336),
        ),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(
      tester.getCenter(find.byType(Container)),
      tester.getCenter(find.byType(CustomScrollView)),
    );
  });
}
