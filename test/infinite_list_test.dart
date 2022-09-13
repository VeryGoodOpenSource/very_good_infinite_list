import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

extension on WidgetTester {
  Future<void> pumpApp(Widget widget) async {
    await pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          body: widget,
        ),
      ),
    );
    await pump();
  }
}

void main() {
  group('InfiniteList', () {
    void emptyCallback() {}

    testWidgets(
      'attempts to fetch new elements if rebuild occurs '
      'with different set of items',
      (tester) async {
        const key = Key('__test_target__');

        Future<void> rebuild() async {
          await tester.tap(find.byKey(key));
          await tester.pumpAndSettle();
        }

        var itemCount = 3;
        var hasReachedMax = true;

        var onFetchDataCalls = 0;

        await tester.pumpApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  TextButton(
                    key: key,
                    onPressed: () => setState(() {}),
                    child: const Text('REBUILD'),
                  ),
                  Expanded(
                    child: InfiniteList(
                      itemCount: itemCount,
                      hasReachedMax: hasReachedMax,
                      onFetchData: () => onFetchDataCalls++,
                      itemBuilder: (_, i) => Text('$i'),
                    ),
                  ),
                ],
              );
            },
          ),
        );

        itemCount = 5;
        hasReachedMax = false;
        await rebuild();

        expect(onFetchDataCalls, equals(1));
      },
    );

    testWidgets(
      'renders CustomScrollView',
      (tester) async {
        await tester.pumpApp(
          InfiniteList(
            itemCount: 3,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
          ),
        );

        expect(find.byType(CustomScrollView), findsOneWidget);
      },
    );

    testWidgets(
      'passes padding to internal SliverPadding',
      (tester) async {
        const padding = EdgeInsets.all(16);

        await tester.pumpApp(
          InfiniteList(
            padding: padding,
            itemCount: 3,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
          ),
        );

        final sliverPadding =
            tester.widget<SliverPadding>(find.byType(SliverPadding));
        expect(sliverPadding.padding, equals(padding));
      },
    );

    testWidgets(
      'uses media query padding when padding is omitted',
      (tester) async {
        const padding = EdgeInsets.all(40);

        await tester.pumpApp(
          Builder(builder: (context) {
            final data = MediaQuery.of(context);
            return MediaQuery(
              data: data.copyWith(padding: padding),
              child: InfiniteList(
                padding: padding,
                itemCount: 3,
                onFetchData: emptyCallback,
                itemBuilder: (_, i) => Text('$i'),
              ),
            );
          }),
        );

        final sliverPadding =
            tester.widget<SliverPadding>(find.byType(SliverPadding));
        expect(sliverPadding.padding, equals(padding));
      },
    );

    testWidgets(
      'renders items using itemBuilder',
      (tester) async {
        const itemCount = 50;
        var itemBuilderCalls = 0;

        await tester.pumpApp(
          InfiniteList(
            itemCount: itemCount,
            hasReachedMax: true,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) {
              itemBuilderCalls++;
              return Text('$i');
            },
          ),
        );

        expect(itemBuilderCalls, equals(itemCount));
      },
    );

    testWidgets(
      'renders separators in between items using separatorBuilder',
      (tester) async {
        const itemCount = 20;
        const separatorCount = itemCount - 1;
        var separatorBuilderCalls = 0;

        await tester.pumpApp(
          InfiniteList(
            itemCount: itemCount,
            onFetchData: emptyCallback,
            separatorBuilder: (_) {
              separatorBuilderCalls++;
              return const Divider();
            },
            itemBuilder: (_, i) => Text('$i'),
          ),
        );

        expect(separatorBuilderCalls, equals(separatorCount));
      },
    );

    group('with an empty set of items', () {
      testWidgets(
        'renders no list items by default',
        (tester) async {
          await tester.pumpApp(
            InfiniteList(
              itemCount: 0,
              onFetchData: emptyCallback,
              itemBuilder: (_, i) => Text('$i'),
            ),
          );

          expect(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Widget),
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'renders custom emptyBuilder',
        (tester) async {
          const key = Key('__test_target__');

          await tester.pumpApp(
            InfiniteList(
              itemCount: 0,
              onFetchData: emptyCallback,
              emptyBuilder: (_) => const Text('__EMPTY__', key: key),
              itemBuilder: (_, i) => Text('$i'),
            ),
          );

          expect(find.byKey(key), findsOneWidget);
        },
      );
    });

    group('with hasError set to true', () {
      testWidgets(
        'renders default errorBuilder',
        (tester) async {
          await tester.pumpApp(
            InfiniteList(
              hasError: true,
              itemCount: 0,
              onFetchData: emptyCallback,
              itemBuilder: (_, i) => Text('$i'),
            ),
          );

          expect(find.text('Error'), findsOneWidget);
        },
      );

      testWidgets(
        'renders custom errorBuilder',
        (tester) async {
          const key = Key('__test_target__');

          await tester.pumpApp(
            InfiniteList(
              hasError: true,
              itemCount: 0,
              onFetchData: emptyCallback,
              errorBuilder: (_) => const Text('__ERROR__', key: key),
              itemBuilder: (_, i) => Text('$i'),
            ),
          );

          expect(find.byKey(key), findsOneWidget);
        },
      );
    });

    group('with isLoading set to true', () {
      testWidgets(
        'renders default loadingBuilder',
        (tester) async {
          await tester.pumpApp(
            InfiniteList(
              isLoading: true,
              itemCount: 3,
              onFetchData: emptyCallback,
              itemBuilder: (_, i) => Text('$i'),
            ),
          );

          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        },
      );

      testWidgets(
        'renders custom loadingBuilder',
        (tester) async {
          const key = Key('__test_target__');

          await tester.pumpApp(
            InfiniteList(
              isLoading: true,
              itemCount: 3,
              onFetchData: emptyCallback,
              loadingBuilder: (_) => const Text('__LOADING__', key: key),
              itemBuilder: (_, i) => Text('$i'),
            ),
          );

          expect(find.byKey(key), findsOneWidget);
        },
      );
    });

    group('goldens', () {
      const tags = 'golden';
      String goldenPath(String fileName) => 'goldens/$fileName.png';

      testWidgets(
        'renders successfully when scrolled vertically to bottom',
        tags: tags,
        (tester) async {
          const path = 'successful_vertical_scroll';

          const colors = [Colors.red, Colors.green, Colors.blue];
          final subject = InfiniteList(
            onFetchData: emptyCallback,
            isLoading: true,
            itemCount: 30,
            itemBuilder: (_, i) => SizedBox.square(
              dimension: 40,
              child: ColoredBox(color: colors[i % colors.length]),
            ),
            separatorBuilder: (_) => const SizedBox.square(
              dimension: 10,
              child: ColoredBox(color: Colors.pink),
            ),
          );
          await tester.pumpApp(subject);

          await expectLater(
            find.byWidget(subject),
            matchesGoldenFile(goldenPath('$path/before_scroll')),
          );

          await tester.fling(
            find.byWidget(subject),
            const Offset(0, -1000),
            1000,
          );

          await tester.pump(const Duration(milliseconds: 16));
          await expectLater(
            find.byWidget(subject),
            matchesGoldenFile(goldenPath('$path/after_scroll')),
          );
        },
      );
    });
  });
}
