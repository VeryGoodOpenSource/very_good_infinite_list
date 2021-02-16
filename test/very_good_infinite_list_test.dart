import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:very_good_infinite_list/very_good_infinite_list.dart';

void main() {
  group('InfiniteList', () {
    testWidgets('invokes itemLoader immediately', (tester) async {
      var itemLoaderCallCount = 0;
      final itemLoader = (int limit, {int? start}) async {
        itemLoaderCallCount++;
      };

      await tester.pumpApp(InfiniteList(
        itemLoader: itemLoader,
        builder: InfiniteListBuilder(success: (_, __) => const SizedBox()),
      ));

      expect(itemLoaderCallCount, equals(1));
    });

    testWidgets('renders default loading widget by default', (tester) async {
      await tester.pumpApp(InfiniteList(
        itemLoader: (int limit, {int? start}) async => [],
        builder: InfiniteListBuilder(success: (_, __) => const SizedBox()),
      ));

      expect(find.byKey(const Key('__default_loading__')), findsOneWidget);
    });

    testWidgets('renders default bottom loader widget by default',
        (tester) async {
      await tester.pumpApp(InfiniteList(
        itemLoader: (int limit, {int? start}) async {
          return List.generate(1, (i) => i);
        },
        builder: InfiniteListBuilder(success: (_, __) => const SizedBox()),
      ));

      await tester.pump();

      expect(
        find.byKey(const Key('__default_bottom_loader__')),
        findsOneWidget,
      );
    });

    testWidgets('renders default error loader widget by default',
        (tester) async {
      var itemLoaderCallCount = 0;
      final itemLoaderResults = [
        (int limit, {int? start}) async {
          return List.generate(15, (i) => i);
        },
        (int limit, {int? start}) async {
          throw Exception('oops');
        },
      ];
      await tester.pumpApp(InfiniteList<int>(
        itemLoader: (int limit, {int? start}) async {
          itemLoaderCallCount++;
          return itemLoaderResults.removeAt(0).call(limit, start: start);
        },
        builder: InfiniteListBuilder(
          success: (_, item) {
            return ListTile(
              key: Key('__item_${item}__'),
              title: Text('Item $item'),
            );
          },
        ),
      ));

      await tester.pump();

      expect(itemLoaderCallCount, equals(1));

      await tester.drag(
        find.byKey(const Key('__item_9__')),
        const Offset(0, -500),
      );

      await tester.pump();

      expect(
        find.byKey(const Key('__default_bottom_loader__')),
        findsOneWidget,
      );

      await tester.pumpAndSettle();

      expect(itemLoaderCallCount, equals(2));
      expect(
        find.byKey(const Key('__default_error_loader__')),
        findsOneWidget,
      );
    });

    testWidgets('renders default error widget by default', (tester) async {
      var itemLoaderCallCount = 0;
      final itemLoaderResults = [
        (int limit, {int? start}) async {
          return List.generate(15, (i) => i);
        },
        (int limit, {int? start}) async {
          throw InfiniteListException();
        },
      ];
      await tester.pumpApp(InfiniteList<int>(
        itemLoader: (int limit, {int? start}) async {
          itemLoaderCallCount++;
          return itemLoaderResults.removeAt(0).call(limit, start: start);
        },
        builder: InfiniteListBuilder(
          success: (_, item) {
            return ListTile(
              key: Key('__item_${item}__'),
              title: Text('Item $item'),
            );
          },
        ),
      ));

      await tester.pump();

      expect(itemLoaderCallCount, equals(1));

      await tester.drag(
        find.byKey(const Key('__item_9__')),
        const Offset(0, -500),
      );

      await tester.pump();

      expect(
        find.byKey(const Key('__default_bottom_loader__')),
        findsOneWidget,
      );

      await tester.pumpAndSettle();

      expect(itemLoaderCallCount, equals(2));
      expect(
        find.byKey(const Key('__default_error__')),
        findsOneWidget,
      );
    });

    testWidgets('retry from first time failure', (tester) async {
      var itemLoaderCallCount = 0;
      final itemLoaderResults = [
        (int limit, {int? start}) async {
          throw InfiniteListException();
        },
        (int limit, {int? start}) async {
          return List.generate(15, (i) => i);
        },
      ];
      await tester.pumpApp(InfiniteList<int>(
        itemLoader: (int limit, {int? start}) async {
          itemLoaderCallCount++;
          return itemLoaderResults.removeAt(0).call(limit, start: start);
        },
        builder: InfiniteListBuilder(
          success: (_, item) {
            return ListTile(
              key: Key('__item_${item}__'),
              title: Text('Item $item'),
            );
          },
        ),
      ));

      await tester.pump();

      expect(itemLoaderCallCount, equals(1));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(find.byKey(const Key('__item_9__')), findsOneWidget);
      expect(itemLoaderCallCount, equals(2));
    });

    testWidgets('retry from subsequent failure (critical)', (tester) async {
      var itemLoaderCallCount = 0;
      final itemLoaderResults = [
        (int limit, {int? start}) async {
          return List.generate(15, (i) => i);
        },
        (int limit, {int? start}) async {
          throw InfiniteListException();
        },
        (int limit, {int? start}) async {
          return List.generate(15, (i) => i + start!);
        },
      ];
      await tester.pumpApp(InfiniteList<int>(
        itemLoader: (int limit, {int? start}) async {
          itemLoaderCallCount++;
          return itemLoaderResults.removeAt(0).call(limit, start: start);
        },
        builder: InfiniteListBuilder(
          success: (_, item) {
            return ListTile(
              key: Key('__item_${item}__'),
              title: Text('Item $item'),
            );
          },
        ),
      ));

      await tester.pump();

      expect(itemLoaderCallCount, equals(1));

      await tester.drag(
        find.byKey(const Key('__item_9__')),
        const Offset(0, -500),
      );

      await tester.pump();

      expect(
        find.byKey(const Key('__default_bottom_loader__')),
        findsOneWidget,
      );

      await tester.pumpAndSettle();

      expect(itemLoaderCallCount, equals(2));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      await tester.drag(
        find.byKey(const Key('__item_10__')),
        const Offset(0, -500),
      );
      expect(itemLoaderCallCount, equals(3));
    });

    testWidgets('retry from subsequent failure', (tester) async {
      var itemLoaderCallCount = 0;
      final itemLoaderResults = [
        (int limit, {int? start}) async {
          return List.generate(15, (i) => i);
        },
        (int limit, {int? start}) async {
          throw Exception('oops');
        },
        (int limit, {int? start}) async {
          return List.generate(15, (i) => i + start!);
        },
      ];
      await tester.pumpApp(InfiniteList<int>(
        itemLoader: (int limit, {int? start}) async {
          itemLoaderCallCount++;
          return itemLoaderResults.removeAt(0).call(limit, start: start);
        },
        builder: InfiniteListBuilder(
          success: (_, item) {
            return ListTile(
              key: Key('__item_${item}__'),
              title: Text('Item $item'),
            );
          },
        ),
      ));

      await tester.pump();

      expect(itemLoaderCallCount, equals(1));

      await tester.drag(
        find.byKey(const Key('__item_9__')),
        const Offset(0, -500),
      );

      await tester.pump();

      expect(
        find.byKey(const Key('__default_bottom_loader__')),
        findsOneWidget,
      );

      await tester.pumpAndSettle();

      expect(itemLoaderCallCount, equals(2));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      await tester.drag(
        find.byKey(const Key('__item_10__')),
        const Offset(0, -500),
      );
      expect(itemLoaderCallCount, equals(3));
    });

    testWidgets('does not render bottom loader when there are no more results',
        (tester) async {
      var itemLoaderCallCount = 0;
      final itemLoaderResults = [
        (int limit, {int? start}) async {
          return List.generate(15, (i) => i);
        },
        (int limit, {int? start}) async => <int>[],
      ];
      await tester.pumpApp(InfiniteList<int>(
        itemLoader: (int limit, {int? start}) async {
          itemLoaderCallCount++;
          return itemLoaderResults.removeAt(0).call(limit, start: start);
        },
        builder: InfiniteListBuilder(
          success: (_, item) {
            return ListTile(
              key: Key('__item_${item}__'),
              title: Text('Item $item'),
            );
          },
        ),
      ));

      await tester.pump();

      expect(itemLoaderCallCount, equals(1));

      await tester.drag(
        find.byKey(const Key('__item_9__')),
        const Offset(0, -500),
      );

      await tester.pump();

      expect(
        find.byKey(const Key('__default_bottom_loader__')),
        findsOneWidget,
      );

      await tester.pumpAndSettle();

      expect(itemLoaderCallCount, equals(2));
      expect(
        find.byKey(const Key('__default_error_loader__')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('__default_bottom_loader__')),
        findsNothing,
      );
    });

    testWidgets('renders default empty widget by default', (tester) async {
      await tester.pumpApp(InfiniteList(
        itemLoader: (int limit, {int? start}) async => [],
        builder: InfiniteListBuilder(success: (_, __) => const SizedBox()),
      ));

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('__default_empty__')), findsOneWidget);
    });

    testWidgets('renders default error widget by default (generic)',
        (tester) async {
      await tester.pumpApp(InfiniteList(
        itemLoader: (int limit, {int? start}) async {
          throw Exception('oops');
        },
        builder: InfiniteListBuilder(success: (_, __) => const SizedBox()),
      ));

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('__default_error__')), findsOneWidget);
    });

    testWidgets('renders default error widget by default (specific)',
        (tester) async {
      await tester.pumpApp(InfiniteList(
        itemLoader: (int limit, {int? start}) async {
          throw InfiniteListException();
        },
        builder: InfiniteListBuilder(success: (_, __) => const SizedBox()),
      ));

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('__default_error__')), findsOneWidget);
    });
  });
}

extension on WidgetTester {
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      MaterialApp(home: Scaffold(body: widget)),
    );
  }
}
