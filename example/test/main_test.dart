import 'package:example/main.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main returns as expected', () {
    expect(example.main, returnsNormally);
  });
}
