import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:very_good_infinite_list/src/sliver_infinite_list.dart';

extension on WidgetTester {
  Future<void> pumpSlivers(
    List<Widget> slivers, {
    double? cacheExtent,
    double height = 500,
  }) async {
    await pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        debugShowCheckedModeBanner: false,
        builder:
            (_, __) => Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
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
  group('SliverInfiniteList', () {
    group('fetches only the necessary items', () {
      testWidgets('on mount', (tester) async {
        var itemCount = 0;
        var onFetchDataCalls = 0;
        const itemSize = Size.square(10);

        await tester.pumpSlivers(cacheExtent: 0, height: itemSize.height * 3, [
          StatefulBuilder(
            builder: (context, setState) {
              return SliverInfiniteList(
                itemCount: itemCount,
                debounceDuration: Duration.zero,
                onFetchData: () {
                  setState(() {
                    itemCount += 1;
                    onFetchDataCalls++;
                  });
                },
                itemBuilder: (_, i) => SizedBox.fromSize(size: itemSize),
              );
            },
          ),
        ]);
        await tester.pumpAndSettle();

        expect(onFetchDataCalls, equals(5));
      });
    });
    group('consider preceding slivers', () {
      testWidgets('on mount', (tester) async {
        var itemCount = 0;
        var onFetchDataCalls = 0;
        await tester.pumpSlivers(cacheExtent: 0, [
          const SliverToBoxAdapter(child: SizedBox(height: 500)),
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
        ]);
        await tester.pumpAndSettle();

        expect(onFetchDataCalls, equals(1));
      });
    });
  });
}
