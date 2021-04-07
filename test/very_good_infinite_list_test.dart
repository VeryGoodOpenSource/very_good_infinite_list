import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

class MockScrollPosition extends Mock implements ScrollPosition {}

class MockScrollController extends Mock implements ScrollController {}

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
    Widget emptyBuilder(BuildContext _, int __) => const SizedBox();

    ScrollPosition scrollPosition;
    ScrollController scrollController;

    setUp(() {
      scrollPosition = MockScrollPosition();
      when(scrollPosition.maxScrollExtent).thenReturn(1000.0);

      scrollController = MockScrollController();
      when(scrollController.hasClients).thenReturn(true);
      when(scrollController.offset).thenReturn(0.0);
      when(scrollController.position).thenReturn(scrollPosition);
    });

    test('throws AssertionError when items is null', () {
      expect(
        () => InfiniteList<int>(
          items: null,
          hasReachedMax: false,
          onFetchData: emptyCallback,
          itemBuilder: emptyBuilder,
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when hasReachedMax is null', () {
      expect(
        () => InfiniteList<int>(
          items: [],
          hasReachedMax: null,
          onFetchData: emptyCallback,
          itemBuilder: emptyBuilder,
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when onFetchData is null', () {
      expect(
        () => InfiniteList<int>(
          items: [],
          hasReachedMax: false,
          onFetchData: null,
          itemBuilder: emptyBuilder,
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when itemBuilder is null', () {
      expect(
        () => InfiniteList<int>(
          items: [],
          hasReachedMax: false,
          onFetchData: emptyCallback,
          itemBuilder: null,
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when scrollExtentThreshold is null', () {
      expect(
        () => InfiniteList<int>(
          items: [],
          hasReachedMax: false,
          onFetchData: emptyCallback,
          itemBuilder: emptyBuilder,
          scrollExtentThreshold: null,
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when debounceDuration is null', () {
      expect(
        () => InfiniteList<int>(
          items: [],
          hasReachedMax: false,
          onFetchData: emptyCallback,
          itemBuilder: emptyBuilder,
          debounceDuration: null,
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when reverse is null', () {
      expect(
        () => InfiniteList<int>(
          items: [],
          hasReachedMax: false,
          onFetchData: emptyCallback,
          itemBuilder: emptyBuilder,
          reverse: null,
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when isLoading is null', () {
      expect(
        () => InfiniteList<int>(
          items: [],
          hasReachedMax: false,
          onFetchData: emptyCallback,
          itemBuilder: emptyBuilder,
          isLoading: null,
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when hasError is null', () {
      expect(
        () => InfiniteList<int>(
          items: [],
          hasReachedMax: false,
          onFetchData: emptyCallback,
          itemBuilder: emptyBuilder,
          hasError: null,
        ),
        throwsAssertionError,
      );
    });

    testWidgets(
      'disposes old scrollController when it is replaced',
      (tester) async {
        const key = Key('__test_target__');

        var useExternalScrollController = true;

        await tester.pumpApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  TextButton(
                    key: key,
                    onPressed: () {
                      setState(() {
                        useExternalScrollController = false;
                      });
                    },
                    child: const Text('REPLACE CONTROLLER'),
                  ),
                  Expanded(
                    child: InfiniteList<int>(
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

        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();

        verify(scrollController.removeListener(any)).called(1);
        verify(scrollController.dispose()).called(1);
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
