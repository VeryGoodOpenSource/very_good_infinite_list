import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:very_good_infinite_list/src/sliver_infinite_grid.dart';

extension on WidgetTester {
  Future<void> pumpSlivers(
    List<Widget> slivers, {
    double? cacheExtent,
    double height = 500,
  }) async {
    await pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: height,
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
  group('SliverInfiniteGrid', () {
    group('fetches only the necessary items', () {
      testWidgets('on mount', (tester) async {
        var itemCount = 0;
        var onFetchDataCalls = 0;
        const crossAxisCount = 2;
        const itemSize = Size.square(20);

        await tester.pumpSlivers(
          cacheExtent: 0,
          height: itemSize.height * 3,
          [
            StatefulBuilder(
              builder: (context, setState) {
                return SliverInfiniteGrid(
                  itemCount: itemCount,
                  debounceDuration: Duration.zero,
                  onFetchData: () {
                    setState(() {
                      itemCount += 1;
                      onFetchDataCalls++;
                    });
                  },
                  itemBuilder: (_, i) => SizedBox.fromSize(size: itemSize),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                  ),
                );
              },
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(onFetchDataCalls, equals(4));
      });
    });
    group('consider preceding slivers', () {
      testWidgets('on mount', (tester) async {
        var itemCount = 0;
        var onFetchDataCalls = 0;
        const crossAxisCount = 2;
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
                return SliverInfiniteGrid(
                  itemCount: itemCount,
                  debounceDuration: Duration.zero,
                  onFetchData: () {
                    setState(() {
                      itemCount += 8;
                      onFetchDataCalls++;
                    });
                  },
                  itemBuilder: (_, i) => Text('$i'),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                  ),
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
