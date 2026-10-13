import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// {@template infinite_list_loading_indicator}
/// A spinning circular loading indicator that only depends on the widgets
/// library.
///
/// Used as the default loading widget of the infinite lists.
/// {@endtemplate}
class InfiniteListLoadingIndicator extends StatefulWidget {
  /// {@macro infinite_list_loading_indicator}
  const InfiniteListLoadingIndicator({
    super.key,
    this.color = defaultColor,
    this.size = 36,
    this.strokeWidth = 4,
  });

  /// The default value of [color].
  static const defaultColor = Color(0xFF6750A4);

  /// The color of the spinning arc.
  final Color color;

  /// The width and height of the indicator.
  final double size;

  /// The width of the spinning arc.
  final double strokeWidth;

  @override
  State<InfiniteListLoadingIndicator> createState() =>
      _InfiniteListLoadingIndicatorState();
}

class _InfiniteListLoadingIndicatorState
    extends State<InfiniteListLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: RotationTransition(
        turns: _controller,
        child: CustomPaint(
          painter: _LoadingIndicatorPainter(
            color: widget.color,
            strokeWidth: widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicatorPainter extends CustomPainter {
  const _LoadingIndicatorPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    canvas.drawArc(
      (Offset.zero & size).deflate(strokeWidth / 2),
      0,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoadingIndicatorPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
