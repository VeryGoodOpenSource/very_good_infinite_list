import 'dart:math';

import 'package:flutter/material.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

class SimpleGridExample extends StatefulWidget {
  const SimpleGridExample({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) {
        return const SimpleGridExample();
      },
    );
  }

  @override
  SimpleGridExampleState createState() => SimpleGridExampleState();
}

class SimpleGridExampleState extends State<SimpleGridExample> {
  var _items = <String>[];
  var _isLoading = false;

  late final random = Random();

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _items = List.generate(_items.length + 100, (i) => 'Item $i');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Example'),
      ),
      body: InfiniteGrid(
        itemCount: _items.length,
        isLoading: _isLoading,
        onFetchData: _fetchData,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final color = ((0xFFFFFF / 60) * (index % 60)).floor();

          return SizedBox.expand(
            child: ColoredBox(
              color: Color(0xFF000000 + color),
              child: Text(_items[index]),
            ),
          );
        },
      ),
    );
  }
}
