import 'package:flutter/material.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

class SimpleExample extends StatefulWidget {
  const SimpleExample({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) {
        return const SimpleExample();
      },
    );
  }

  @override
  SimpleExampleState createState() => SimpleExampleState();
}

class SimpleExampleState extends State<SimpleExample> {
  var _items = <String>[];
  var _isLoading = false;

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
      _items = List.generate(_items.length + 10, (i) => 'Item $i');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Example'),
      ),
      body: InfiniteList(
        itemCount: _items.length,
        isLoading: _isLoading,
        onFetchData: _fetchData,
        separatorBuilder: (context, index) {
          return Divider(
            color: index.isOdd ? Colors.black : Colors.blue,
          );
        },
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            title: Text(_items[index]),
          );
        },
      ),
    );
  }
}
