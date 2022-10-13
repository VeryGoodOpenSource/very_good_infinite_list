import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:very_good_infinite_list/src/sliver_infinite_list.dart';

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
  group('SliverInfiniteList', () {
    group('fetches only the necessary items', () {
      testWidgets('on mount', (tester) async {
        var itemCount = 0;
        var onFetchDataCalls = 0;

        await tester.pumpSlivers(
          cacheExtent: 0,
          [
            StatefulBuilder(
              builder: (context, setState) {
                return SliverInfiniteList(
                  itemCount: itemCount,
                  debounceDuration: Duration.zero,
                  onFetchData: () {
                    setState(() {
                      itemCount += 8;
                      onFetchDataCalls++;
                    });
                  },
                  itemBuilder: (_, i) => SizedBox(
                    child: Text('$i'),
                  ),
                );
              },
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(onFetchDataCalls, equals(5));
      });
    });
    group('consider preceding slivers', () {
      testWidgets('on mount', (tester) async {
        var itemCount = 0;
        var onFetchDataCalls = 0;
        await tester.pumpSlivers(
          cacheExtent: 0,
          [
            const SliverAppBar(
              expandedHeight: 500,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('title'),
              ),
            ),
            StatefulBuilder(
              builder: (context, setState) {
                return SliverInfiniteList(
                  itemCount: itemCount,
                  debounceDuration: Duration.zero,
                  onFetchData: () {
                    setState(() {
                      itemCount += 8;
                      onFetchDataCalls++;
                    });
                  },
                  itemBuilder: (_, i) => Text('$i'),
                );
              },
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(onFetchDataCalls, equals(1));
      });
    });
  });
}
