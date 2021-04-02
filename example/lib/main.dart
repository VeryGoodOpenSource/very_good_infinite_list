import 'package:example/people_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        dividerTheme: const DividerThemeData(
          indent: 16.0,
          space: 0.0,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Infinite List 2 Example')),
        body: BlocProvider(
          create: (_) => PeopleCubit(),
          child: Example(),
        ),
      ),
    ),
  );
}

class Example extends StatefulWidget {
  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  var _reverse = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PeopleCubit>().state;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.white,
            elevation: 2.0,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 16.0,
                bottom: 8.0,
              ),
              child: Column(
                children: [
                  const Text(
                    'A maximum of 24 items can be fetched.',
                    textAlign: TextAlign.center,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => context.read<PeopleCubit>().clear(),
                        child: const Text('CLEAR STATE'),
                      ),
                      const SizedBox(width: 8.0),
                      TextButton(
                        onPressed: () => setState(() {
                          _reverse = !_reverse;
                        }),
                        child: const Text('REVERSE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: InfiniteList<Person>(
            reverse: _reverse,
            items: state.values,
            isLoading: state.isLoading,
            hasError: state.error != null,
            hasReachedMax: state.hasReachedMax,
            onFetchData: () => context.read<PeopleCubit>().loadData(),
            itemBuilder: (context, person) {
              return ListTile(
                dense: true,
                title: Text(person.name),
              );
            },
          ),
        ),
      ],
    );
  }
}
