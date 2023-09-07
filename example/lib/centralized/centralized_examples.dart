import 'package:flutter/material.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

class CentralizedExamples extends StatefulWidget {
  const CentralizedExamples({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) {
        return const CentralizedExamples();
      },
    );
  }

  @override
  State<CentralizedExamples> createState() => _CentralizedExamplesState();
}

class _CentralizedExamplesState extends State<CentralizedExamples>
    with SingleTickerProviderStateMixin {
  final tabs = const [
    Tab(text: 'Loading'),
    Tab(text: 'Empty'),
    Tab(text: 'Error'),
  ];

  late final tabBarController = TabController(length: 3, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centralized Examples'),
        bottom: TabBar(
          tabs: tabs,
          controller: tabBarController,
        ),
      ),
      body: TabBarView(
        controller: tabBarController,
        children: [
          _LoadingExample(),
          _EmptyExample(),
          _ErrorExample(),
        ],
      ),
    );
  }
}

Widget _buildItem(BuildContext context, int index) {
  return ListTile(
    title: Text('Item $index'),
  );
}

class _LoadingExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InfiniteList(
      itemCount: 0,
      isLoading: true,
      centerLoading: true,
      loadingBuilder: (_) => const SizedBox(
        height: 10,
        width: 120,
        child: LinearProgressIndicator(),
      ),
      onFetchData: () async {},
      itemBuilder: _buildItem,
    );
  }
}

class _EmptyExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InfiniteList(
      itemCount: 0,
      centerEmpty: true,
      emptyBuilder: (_) => const Text(
        'No items',
        style: TextStyle(fontSize: 20),
      ),
      onFetchData: () async {},
      itemBuilder: _buildItem,
    );
  }
}

class _ErrorExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InfiniteList(
      itemCount: 0,
      hasError: true,
      centerError: true,
      errorBuilder: (_) => const Icon(
        Icons.error,
        size: 60,
        color: Colors.red,
      ),
      onFetchData: () async {},
      itemBuilder: _buildItem,
    );
  }
}
