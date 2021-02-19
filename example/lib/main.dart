import 'dart:math';

import 'package:flutter/material.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Infinite List')),
        body: Builder(
          builder: (context) {
            return ListView(
              children: [
                ListTile(
                  title: const Text('Default Infinite List'),
                  onTap: () {
                    Navigator.of(context).push(_DefaultInfiniteList.route());
                  },
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTile(
                  title: const Text('Reversed Infinite List'),
                  onTap: () {
                    Navigator.of(context).push(_ReversedInfiniteList.route());
                  },
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTile(
                  title: const Text('Custom Infinite List'),
                  onTap: () {
                    Navigator.of(context).push(_CustomInfiniteList.route());
                  },
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DefaultInfiniteList extends StatelessWidget {
  static Route route() {
    return MaterialPageRoute(builder: (_) => _DefaultInfiniteList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Default Infinite List')),
      body: InfiniteList<String>(
        itemLoader: _itemLoader,
        builder: InfiniteListBuilder<String>(
          success: (context, item) => ListTile(title: Text(item)),
        ),
      ),
    );
  }
}

class _ReversedInfiniteList extends StatelessWidget {
  static Route route() {
    return MaterialPageRoute(builder: (_) => _ReversedInfiniteList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reversed Infinite List')),
      body: InfiniteList<String>(
        itemLoader: _itemLoader,
        builder: InfiniteListBuilder<String>(
          success: (context, item) => ListTile(title: Text(item)),
        ),
        reverse: true,
      ),
    );
  }
}

class _CustomInfiniteList extends StatelessWidget {
  static Route route() {
    return MaterialPageRoute(builder: (_) => _CustomInfiniteList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Infinite List')),
      body: InfiniteList<String>(
        padding: const EdgeInsets.all(0),
        itemLoader: _itemLoader,
        builder: InfiniteListBuilder<String>(
          empty: (context) => _Empty(),
          loading: (context) => _Loading(),
          success: (context, item) => ListTile(title: Text(item)),
          error: (context, retry, error) {
            return _Error(error: error, retry: retry);
          },
        ),
        onError: (context, retry, error) {
          Scaffold.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(error.toString()),
              action: SnackBarAction(label: 'Retry', onPressed: retry),
            ));
        },
        bottomLoader: (context) => _Loading(),
        errorLoader: (context, retry, error) => _ErrorLoader(retry: retry),
      ),
    );
  }
}

Future<List<String>> _itemLoader(int limit, {int start = 0}) async {
  await Future<void>.delayed(const Duration(seconds: 1));
  if (start >= 100) return null;
  if (Random().nextInt(2) == 0) throw Exception('Oops!');
  if (Random().nextInt(5) == 0) throw InfiniteListException();
  return List.generate(limit, (index) => 'Item ${start + index}');
}

class _Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _Error extends StatelessWidget {
  const _Error({
    Key key,
    this.error,
    this.retry,
  }) : super(key: key);

  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error.toString(),
            style: theme.textTheme.headline4.copyWith(color: theme.errorColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: retry,
          ),
        ],
      ),
    );
  }
}

class _ErrorLoader extends StatelessWidget {
  const _ErrorLoader({Key key, @required this.retry}) : super(key: key);
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
        onPressed: retry,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Empty'));
  }
}
