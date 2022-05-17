import 'package:example/advanced/advanced_example.dart';
import 'package:example/simple/simple_example.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        dividerTheme: const DividerThemeData(
          indent: 16,
          space: 0,
        ),
      ),
      home: const Example(),
    ),
  );
}

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite List'),
      ),
      body: ListView(
        children: [
          ListTile(
            isThreeLine: true,
            onTap: () => Navigator.of(context).push(SimpleExample.route()),
            title: const Text('Simple Example'),
            subtitle: const Text(
              'A simple example that uses an Infinite List '
              'in a StatefulWidget.',
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            isThreeLine: true,
            onTap: () => Navigator.of(context).push(AdvancedExample.route()),
            title: const Text('Advanced Example'),
            subtitle: const Text(
              'An advanced example that uses an Infinite List '
              'in combination with a Cubit from the Bloc package.',
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
