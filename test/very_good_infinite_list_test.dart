// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
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
      'disposes old scrollController when it is replaced',
      (tester) async {
        const key = Key('__test_target__');

        final scrollController = ScrollController();

        Future<void> rebuild() async {
          await tester.tap(find.byKey(key));
          await tester.pumpAndSettle();
        }

        var useExternalScrollController = true;

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
                    child: InfiniteList<int>(
                      key: const Key('__infinite_list__'),
                      scrollController: !useExternalScrollController
                          ? null
                          : scrollController,
                      items: List.generate(1000, (i) => i),
                      hasReachedMax: false,
                      onFetchData: emptyCallback,
                      itemBuilder: (_, i) => Text('$i'),
                    ),
                  ),
                ],
              );
            },
          ),
        );

        useExternalScrollController = false;
        await rebuild();

        expect(
          () => scrollController.hasListeners,
          throwsFlutterError,
        );
      },
    );

    testWidgets(
      'attempts to fetch new elements if rebuild occurs '
      'with different set of items',
      (tester) async {
        const key = Key('__test_target__');

        Future<void> rebuild() async {
          await tester.tap(find.byKey(key));
          await tester.pumpAndSettle();
        }

        var items = [1, 2, 3];
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
                    child: InfiniteList<int>(
                      items: items,
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

        items = [1, 2, 3, 4, 5];
        hasReachedMax = false;
        await rebuild();

        expect(onFetchDataCalls, equals(1));
      },
    );

    testWidgets(
      'renders ListView',
      (tester) async {
        await tester.pumpApp(
          InfiniteList<int>(
            items: [1, 2, 3],
            hasReachedMax: false,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) => Text('$i'),
          ),
        );

        expect(find.byType(ListView), findsOneWidget);
      },
    );

    testWidgets(
      'renders items using itemBuilder',
      (tester) async {
        var itemBuilderCalls = 0;

        await tester.pumpApp(
          InfiniteList<int>(
            items: [1, 2, 3],
            hasReachedMax: false,
            onFetchData: emptyCallback,
            itemBuilder: (_, i) {
              itemBuilderCalls++;
              return Text(
                '$i',
                key: Key('__test_target_${i}__'),
              );
            },
          ),
        );

        expect(itemBuilderCalls, equals(3));
        expect(find.byKey(const Key('__test_target_1__')), findsOneWidget);
        expect(find.byKey(const Key('__test_target_2__')), findsOneWidget);
        expect(find.byKey(const Key('__test_target_3__')), findsOneWidget);
      },
    );

    testWidgets(
      'renders separators in between items using separatorBuilder',
      (tester) async {
        var separatorBuilderCalls = 0;

        await tester.pumpApp(
          InfiniteList<int>(
            items: [1, 2, 3],
            hasReachedMax: false,
            onFetchData: emptyCallback,
            separatorBuilder: (_) {
              separatorBuilderCalls++;
              return const Divider();
            },
            itemBuilder: (_, i) => Text('$i'),
          ),
        );

        expect(separatorBuilderCalls, equals(2));
        expect(find.byType(Divider), findsNWidgets(2));
      },
    );

    group('with an empty set of items', () {
      testWidgets(
        'renders no list items by default',
        (tester) async {
          await tester.pumpApp(
            InfiniteList<int>(
              items: [],
              hasReachedMax: false,
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
            InfiniteList<int>(
              items: [],
              hasReachedMax: false,
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
            InfiniteList<int>(
              hasError: true,
              items: [],
              hasReachedMax: false,
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
            InfiniteList<int>(
              hasError: true,
              items: [],
              hasReachedMax: false,
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
            InfiniteList<int>(
              isLoading: true,
              items: [1, 2, 3],
              hasReachedMax: false,
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
            InfiniteList<int>(
              isLoading: true,
              items: [1, 2, 3],
              hasReachedMax: false,
              onFetchData: emptyCallback,
              loadingBuilder: (_) => const Text('__LOADING__', key: key),
              itemBuilder: (_, i) => Text('$i'),
            ),
          );

          expect(find.byKey(key), findsOneWidget);
        },
      );
    });
  });
}
