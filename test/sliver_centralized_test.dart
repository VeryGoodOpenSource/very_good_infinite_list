import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:very_good_infinite_list/src/sliver_centralized.dart';

extension on WidgetTester {
  Future<void> pumpSlivers(
    List<Widget> slivers, {
    double? cacheExtent,
  }) async {
    await pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: CustomScrollView(
              cacheExtent: cacheExtent,
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
  testWidgets(
    'widget should be at the center of scroll view',
    (tester) async {
      await tester.pumpSlivers(
        [
          SliverCentralized(
            child: Container(
              height: 100,
              width: 100,
              color: Colors.red,
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(
        tester.getCenter(find.byType(Container)),
        tester.getCenter(find.byType(CustomScrollView)),
      );
    },
  );
}
