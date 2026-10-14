import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

void main() {
  group('InfiniteListLoadingIndicator', () {
    CustomPaint findPaint(WidgetTester tester) {
      return tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(InfiniteListLoadingIndicator),
          matching: find.byType(CustomPaint),
        ),
      );
    }

    testWidgets('renders with default size', (tester) async {
      await tester.pumpWidget(
        const Center(child: InfiniteListLoadingIndicator()),
      );

      expect(
        tester.getSize(find.byType(InfiniteListLoadingIndicator)),
        equals(const Size.square(36)),
      );
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        const Center(child: InfiniteListLoadingIndicator(size: 20)),
      );

      expect(
        tester.getSize(find.byType(InfiniteListLoadingIndicator)),
        equals(const Size.square(20)),
      );
    });

    testWidgets('keeps spinning', (tester) async {
      await tester.pumpWidget(
        const Center(child: InfiniteListLoadingIndicator()),
      );

      RotationTransition rotation() =>
          tester.widget<RotationTransition>(find.byType(RotationTransition));

      final initialTurns = rotation().turns.value;
      await tester.pump(const Duration(milliseconds: 250));
      expect(rotation().turns.value, isNot(equals(initialTurns)));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('repaints only when appearance changes', (tester) async {
      await tester.pumpWidget(
        const Center(child: InfiniteListLoadingIndicator()),
      );
      final defaultPainter = findPaint(tester).painter!;

      await tester.pumpWidget(
        const Center(child: InfiniteListLoadingIndicator()),
      );
      final samePainter = findPaint(tester).painter!;
      expect(samePainter.shouldRepaint(defaultPainter), isFalse);

      await tester.pumpWidget(
        const Center(
          child: InfiniteListLoadingIndicator(color: Color(0xFF000000)),
        ),
      );
      final colorPainter = findPaint(tester).painter!;
      expect(colorPainter.shouldRepaint(defaultPainter), isTrue);

      await tester.pumpWidget(
        const Center(child: InfiniteListLoadingIndicator(strokeWidth: 2)),
      );
      final strokePainter = findPaint(tester).painter!;
      expect(strokePainter.shouldRepaint(defaultPainter), isTrue);
    });
  });
}
