import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

extension on WidgetTester {
  Future<void> pumpApp(Widget widget) async {
    await pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.transparent,
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

        hasReachedMax = true;
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

    testWidgets('passes findChildIndexCallback to internal SliverList.delegate',
        (tester) async {
      await tester.pumpApp(
        InfiniteList(
          itemCount: 2,
          onFetchData: emptyCallback,
          itemBuilder: (_, i) => Text('$i', key: ValueKey('key_$i')),
          findChildIndexCallback: (key) {
            final valueKey = key as ValueKey;
            final keyId = valueKey.value as String;
            return int.parse(keyId.split('_')[1]);
          },
        ),
      );

      final sliverList = tester.widget<SliverList>(find.byType(SliverList));
      expect(sliverList.delegate.findIndexByKey(const Key('key_0')), equals(0));
      expect(sliverList.delegate.findIndexByKey(const Key('key_1')), equals(1));
    });

    testWidgets(
      'uses media query padding when padding is omitted',
      (tester) async {
        const padding = EdgeInsets.all(40);

        await tester.pumpApp(
          Builder(
            builder: (context) {
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
            },
          ),
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
        const itemSize = Size.square(10);

        await tester.pumpApp(
          SizedBox(
            width: itemSize.width * itemCount,
            height: itemSize.height * itemCount,
            child: InfiniteList(
              itemCount: itemCount,
              hasReachedMax: true,
              onFetchData: emptyCallback,
              itemBuilder: (_, i) {
                itemBuilderCalls++;
                return SizedBox.fromSize(size: itemSize);
              },
            ),
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
            separatorBuilder: (_, __) {
              separatorBuilderCalls++;
              return const Divider();
            },
            itemBuilder: (_, i) => Text('$i'),
          ),
        );

        expect(separatorBuilderCalls, equals(separatorCount));
      },
    );

    testWidgets(
      'forward the correct indexes to separatorBuilder',
      (tester) async {
        const itemCount = 20;
        final indexes = <int>[];

        await tester.pumpApp(
          InfiniteList(
            itemCount: itemCount,
            onFetchData: emptyCallback,
            separatorBuilder: (_, index) {
              indexes.add(index);
              return const Divider();
            },
            itemBuilder: (_, i) => Text('$i'),
          ),
        );

        expect(indexes, equals(List.generate(itemCount - 1, (index) => index)));
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

    group('transitionary properties', () {
      testWidgets('scrollDirection', (tester) async {
        await tester.pumpApp(
          InfiniteList(
            itemCount: 10,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            scrollDirection: Axis.horizontal,
          ),
        );

        final customScrollView =
            tester.widget<CustomScrollView>(find.byType(CustomScrollView));
        expect(customScrollView.scrollDirection, equals(Axis.horizontal));
      });

      testWidgets('scrollController', (tester) async {
        final scrollController = ScrollController();
        await tester.pumpApp(
          InfiniteList(
            itemCount: 10,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            scrollController: scrollController,
          ),
        );

        final customScrollView =
            tester.widget<CustomScrollView>(find.byType(CustomScrollView));
        expect(customScrollView.controller, scrollController);
      });

      testWidgets('physics', (tester) async {
        const physics = ScrollPhysics();
        await tester.pumpApp(
          InfiniteList(
            itemCount: 10,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            physics: physics,
          ),
        );

        final customScrollView =
            tester.widget<CustomScrollView>(find.byType(CustomScrollView));
        expect(customScrollView.physics, physics);
      });

      testWidgets('reverse', (tester) async {
        const reverse = true;
        await tester.pumpApp(
          InfiniteList(
            itemCount: 10,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            reverse: reverse,
          ),
        );

        final customScrollView =
            tester.widget<CustomScrollView>(find.byType(CustomScrollView));
        expect(customScrollView.reverse, reverse);
      });

      testWidgets('shrinkWrap', (tester) async {
        const shrinkWrap = true;
        await tester.pumpApp(
          InfiniteList(
            itemCount: 10,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            shrinkWrap: shrinkWrap,
          ),
        );

        final customScrollView =
            tester.widget<CustomScrollView>(find.byType(CustomScrollView));
        expect(customScrollView.shrinkWrap, isTrue);
      });

      testWidgets('shrinkWrap defaults to false', (tester) async {
        await tester.pumpApp(
          InfiniteList(
            itemCount: 10,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
          ),
        );

        final customScrollView =
            tester.widget<CustomScrollView>(find.byType(CustomScrollView));
        expect(customScrollView.shrinkWrap, isFalse);
      });
    });

    group('centralized properties', () {
      testWidgets('centerEmpty', (tester) async {
        await tester.pumpApp(
          InfiniteList(
            itemCount: 0,
            centerEmpty: true,
            emptyBuilder: (_) => const Text('No items'),
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
          ),
        );

        expect(find.text('No items'), findsOneWidget);
      });

      testWidgets('centerError', (tester) async {
        await tester.pumpApp(
          InfiniteList(
            itemCount: 0,
            hasError: true,
            centerError: true,
            errorBuilder: (_) => const Text('Error'),
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
          ),
        );

        expect(find.text('Error'), findsOneWidget);
      });

      testWidgets('centerLoading', (tester) async {
        await tester.pumpApp(
          InfiniteList(
            itemCount: 0,
            isLoading: true,
            centerLoading: true,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('goldens', () {
      const tags = 'golden';
      String goldenPath(String fileName) => 'goldens/$fileName.png';

      testWidgets(
        'renders successfully when scrolled vertically to the end',
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
            separatorBuilder: (_, __) => const SizedBox.square(
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

      testWidgets(
        'renders successfully when scrolled horizontally to the end',
        tags: tags,
        (tester) async {
          const path = 'successful_horizontal_scroll';

          const colors = [Colors.red, Colors.green, Colors.blue];
          final subject = InfiniteList(
            onFetchData: emptyCallback,
            isLoading: true,
            itemCount: 30,
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) => SizedBox.square(
              dimension: 40,
              child: ColoredBox(color: colors[i % colors.length]),
            ),
            separatorBuilder: (_, __) => const SizedBox.square(
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
            const Offset(-1000, 0),
            1000,
          );

          await tester.pump(const Duration(milliseconds: 16));

          await expectLater(
            find.byWidget(subject),
            matchesGoldenFile(goldenPath('$path/after_scroll')),
          );
        },
      );

      testWidgets(
        'render horizontally when horizontally scrolled to the end '
        'with centered loading',
        tags: tags,
        (tester) async {
          const path = 'successful_horizontally_scroll_with_centered_loading';

          const colors = [Colors.red, Colors.green, Colors.blue];
          final subject = InfiniteList(
            onFetchData: emptyCallback,
            isLoading: true,
            itemCount: 30,
            centerLoading: true,
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) => SizedBox.square(
              dimension: 40,
              child: ColoredBox(color: colors[i % colors.length]),
            ),
            separatorBuilder: (_, __) => const SizedBox.square(
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

      testWidgets(
        'renders successfully when scrolled vertically to the end '
        'with centered loading',
        tags: tags,
        (tester) async {
          const path = 'successful_vertically_scroll_with_centered_loading';

          const colors = [Colors.red, Colors.green, Colors.blue];
          final subject = InfiniteList(
            onFetchData: emptyCallback,
            isLoading: true,
            itemCount: 30,
            centerLoading: true,
            itemBuilder: (_, i) => SizedBox.square(
              dimension: 40,
              child: ColoredBox(color: colors[i % colors.length]),
            ),
            separatorBuilder: (_, __) => const SizedBox.square(
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
