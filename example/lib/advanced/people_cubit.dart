import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class Person {
  Person(this.name, this.age);

  final String name;
  final int age;
}

class PeopleCubit extends Cubit<PeopleState> {
  PeopleCubit() : super(const PeopleState());

  void clear() {
    emit(const PeopleState());
  }

  Future<void> loadData() async {
    emit(
      PeopleState(
        values: state.values,
        isLoading: true,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (state.values.length >= 24) {
      emit(
        PeopleState(
          values: state.values,
          hasReachedMax: true,
        ),
      );
      return;
    }

    emit(
      PeopleState(
        values: List.generate(
          state.values.length + 3,
          (i) => Person('Person $i', 20 + (i * 0.5).floor()),
        ),
      ),
    );
  }
}

class PeopleState extends Equatable {
  const PeopleState({
    this.values = const <Person>[],
    this.isLoading = false,
    this.error,
    this.hasReachedMax = false,
  });

  final List<Person> values;
  final bool isLoading;
  final Object? error;
  final bool hasReachedMax;

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [values, isLoading, error, hasReachedMax];
}
