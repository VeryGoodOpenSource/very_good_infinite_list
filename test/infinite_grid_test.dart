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
  group('InfiniteGrid', () {
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
        const crossAxisCount = 2;

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
                    child: InfiniteGrid(
                      itemCount: itemCount,
                      hasReachedMax: hasReachedMax,
                      onFetchData: () => onFetchDataCalls++,
                      itemBuilder: (_, i) => Text('$i'),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                      ),
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
        const crossAxisCount = 2;

        await tester.pumpApp(
          InfiniteGrid(
            itemCount: 3,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
            ),
          ),
        );

        expect(find.byType(CustomScrollView), findsOneWidget);
      },
    );

    testWidgets(
      'passes padding to internal SliverPadding',
      (tester) async {
        const padding = EdgeInsets.all(16);
        const crossAxisCount = 2;

        await tester.pumpApp(
          InfiniteGrid(
            padding: padding,
            itemCount: 3,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
            ),
          ),
        );

        final sliverPadding =
            tester.widget<SliverPadding>(find.byType(SliverPadding));
        expect(sliverPadding.padding, equals(padding));
      },
    );

    testWidgets('passes findChildIndexCallback to internal SliverGrid.delegate',
        (tester) async {
      const crossAxisCount = 2;
      await tester.pumpApp(
        InfiniteGrid(
          itemCount: 10,
          onFetchData: emptyCallback,
          itemBuilder: (_, i) => Text('$i', key: ValueKey('key_$i')),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
          ),
          findChildIndexCallback: (key) {
            final valueKey = key as ValueKey;
            final keyId = valueKey.value as String;
            return int.parse(keyId.split('_')[1]);
          },
        ),
      );

      final sliverList = tester.widget<SliverGrid>(find.byType(SliverGrid));
      expect(sliverList.delegate.findIndexByKey(const Key('key_0')), equals(0));
      expect(sliverList.delegate.findIndexByKey(const Key('key_1')), equals(1));
    });

    testWidgets(
      'uses media query padding when padding is omitted',
      (tester) async {
        const padding = EdgeInsets.all(40);
        const crossAxisCount = 2;

        await tester.pumpApp(
          Builder(
            builder: (context) {
              final data = MediaQuery.of(context);
              return MediaQuery(
                data: data.copyWith(padding: padding),
                child: InfiniteGrid(
                  padding: padding,
                  itemCount: 3,
                  onFetchData: emptyCallback,
                  itemBuilder: (_, i) => Text('$i'),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                  ),
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
        const itemSize = Size.square(0.4);
        const crossAxisCount = 2;

        await tester.pumpApp(
          SizedBox(
            width: itemSize.width * itemCount,
            height: itemSize.height * itemCount,
            child: InfiniteGrid(
              itemCount: itemCount,
              hasReachedMax: true,
              onFetchData: emptyCallback,
              itemBuilder: (_, i) {
                itemBuilderCalls++;
                return SizedBox.fromSize(size: itemSize);
              },
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
              ),
            ),
          ),
        );

        expect(itemBuilderCalls, equals(itemCount));
      },
    );

    group('with an empty set of items', () {
      testWidgets(
        'renders no list items by default',
        (tester) async {
          const crossAxisCount = 2;

          await tester.pumpApp(
            InfiniteGrid(
              itemCount: 0,
              onFetchData: emptyCallback,
              itemBuilder: (_, i) => Text('$i'),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
              ),
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
          const crossAxisCount = 2;

          await tester.pumpApp(
            InfiniteGrid(
              itemCount: 0,
              onFetchData: emptyCallback,
              emptyBuilder: (_) => const Text('__EMPTY__', key: key),
              itemBuilder: (_, i) => Text('$i'),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
              ),
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
          const crossAxisCount = 2;

          await tester.pumpApp(
            InfiniteGrid(
              hasError: true,
              itemCount: 0,
              onFetchData: emptyCallback,
              itemBuilder: (_, i) => Text('$i'),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
              ),
            ),
          );

          expect(find.text('Error'), findsOneWidget);
        },
      );

      testWidgets(
        'renders custom errorBuilder',
        (tester) async {
          const key = Key('__test_target__');
          const crossAxisCount = 2;

          await tester.pumpApp(
            InfiniteGrid(
              hasError: true,
              itemCount: 0,
              onFetchData: emptyCallback,
              errorBuilder: (_) => const Text('__ERROR__', key: key),
              itemBuilder: (_, i) => Text('$i'),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
              ),
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
          const crossAxisCount = 2;
          await tester.pumpApp(
            InfiniteGrid(
              isLoading: true,
              itemCount: 3,
              onFetchData: emptyCallback,
              itemBuilder: (_, i) => Text('$i'),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
              ),
            ),
          );

          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        },
      );

      testWidgets(
        'renders custom loadingBuilder',
        (tester) async {
          const key = Key('__test_target__');
          const crossAxisCount = 2;

          await tester.pumpApp(
            InfiniteGrid(
              isLoading: true,
              itemCount: 3,
              onFetchData: emptyCallback,
              loadingBuilder: (_) => const Text('__LOADING__', key: key),
              itemBuilder: (_, i) => Text('$i'),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
              ),
            ),
          );

          expect(find.byKey(key), findsOneWidget);
        },
      );
    });

    group('transitionary properties', () {
      testWidgets('scrollDirection', (tester) async {
        const crossAxisCount = 2;
        await tester.pumpApp(
          InfiniteGrid(
            itemCount: 10,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
            ),
          ),
        );

        final customScrollView =
            tester.widget<CustomScrollView>(find.byType(CustomScrollView));
        expect(customScrollView.scrollDirection, equals(Axis.horizontal));
      });

      testWidgets('scrollController', (tester) async {
        final scrollController = ScrollController();
        const crossAxisCount = 2;
        await tester.pumpApp(
          InfiniteGrid(
            itemCount: 10,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            scrollController: scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
            ),
          ),
        );

        final customScrollView =
            tester.widget<CustomScrollView>(find.byType(CustomScrollView));
        expect(customScrollView.controller, scrollController);
      });

      testWidgets('physics', (tester) async {
        const physics = ScrollPhysics();
        const crossAxisCount = 2;
        await tester.pumpApp(
          InfiniteGrid(
            itemCount: 10,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            physics: physics,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
            ),
          ),
        );

        final customScrollView =
            tester.widget<CustomScrollView>(find.byType(CustomScrollView));
        expect(customScrollView.physics, physics);
      });

      testWidgets('reverse', (tester) async {
        const reverse = true;
        const crossAxisCount = 2;
        await tester.pumpApp(
          InfiniteGrid(
            itemCount: 10,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            reverse: reverse,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
            ),
          ),
        );

        final customScrollView =
            tester.widget<CustomScrollView>(find.byType(CustomScrollView));
        expect(customScrollView.reverse, reverse);
      });
    });

    group('centralized properties', () {
      testWidgets('centerEmpty', (tester) async {
        const crossAxisCount = 2;
        await tester.pumpApp(
          InfiniteGrid(
            itemCount: 0,
            centerEmpty: true,
            emptyBuilder: (_) => const Text('No items'),
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
            ),
          ),
        );

        expect(find.text('No items'), findsOneWidget);
      });

      testWidgets('centerError', (tester) async {
        const crossAxisCount = 2;
        await tester.pumpApp(
          InfiniteGrid(
            itemCount: 0,
            hasError: true,
            centerError: true,
            errorBuilder: (_) => const Text('Error'),
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
            ),
          ),
        );

        expect(find.text('Error'), findsOneWidget);
      });

      testWidgets('centerLoading', (tester) async {
        const crossAxisCount = 2;

        await tester.pumpApp(
          InfiniteGrid(
            itemCount: 0,
            isLoading: true,
            centerLoading: true,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });
  });
}
