import 'package:flutter/material.dart';

/// {@template sliver_centralized}
/// A sliver that centers its child and fills the remaining space.
///
/// This is useful for centering a child in a [CustomScrollView].
/// {@endtemplate}
class SliverCentralized extends StatefulWidget {
  /// Constructs a [SliverCentralized]. <br />
  /// {@macro sliver_centralized}
  const SliverCentralized({
    required this.child,
    super.key,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<SliverCentralized> createState() => _SliverCentralizedState();
}

class _SliverCentralizedState extends State<SliverCentralized> {
  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: widget.child,
      ),
    );
  }
}
