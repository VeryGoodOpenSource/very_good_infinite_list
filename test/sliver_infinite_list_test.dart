import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:very_good_infinite_list/src/sliver_infinite_list.dart';

extension on WidgetTester {
  Future<void> pumpSlivers(List<Widget> slivers) async {
    await pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: CustomScrollView(
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
          [
            StatefulBuilder(
              builder: (context, setState) {
                return SliverInfiniteList(
                  itemCount: itemCount,
                  debounceDuration: Duration.zero,
                  hasReachedMax: itemCount == 12,
                  onFetchData: () {
                    setState(() {
                      itemCount += 3;
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

        expect(onFetchDataCalls, equals(4));
      });
    });
    group('consider preceding slivers', () {
      testWidgets('on mount', (tester) async {
        var itemCount = 0;
        var onFetchDataCalls = 0;

        await tester.pumpSlivers(
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
                  hasReachedMax: itemCount == 12,
                  onFetchData: () {
                    setState(() {
                      itemCount += 3;
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

  group('CallbackDebouncer', () {
    test('calls callback after specified duration expires', () async {
      const duration = Duration(milliseconds: 250);

      var callCount = 0;

      CallbackDebouncer(duration)(() => callCount++);

      expect(callCount, equals(0));

      await Future<void>.delayed(duration);
      expect(callCount, equals(1));
    });

    test('immediately calls callback if specified duration is zero', () async {
      var callCount = 0;

      CallbackDebouncer(Duration.zero)(() => callCount++);

      expect(callCount, equals(1));
    });
  });
}
