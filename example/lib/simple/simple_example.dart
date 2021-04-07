import 'package:flutter/material.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

class SimpleExample extends StatefulWidget {
  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) {
        return SimpleExample();
      },
    );
  }

  @override
  _SimpleExampleState createState() => _SimpleExampleState();
}

class _SimpleExampleState extends State<SimpleExample> {
  var _items = <String>[];
  var _isLoading = false;

  void _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _items = List.generate(_items.length + 10, (i) => 'Item $i');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Example'),
      ),
      body: InfiniteList<String>(
        items: _items,
        hasReachedMax: false,
        isLoading: _isLoading,
        onFetchData: _fetchData,
        separatorBuilder: (context) => const Divider(),
        itemBuilder: (context, item) {
          return ListTile(
            dense: true,
            title: Text(item),
          );
        },
      ),
    );
  }
}
