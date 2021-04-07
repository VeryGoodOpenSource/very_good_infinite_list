// ignore_for_file: public_member_api_docs
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class Person {
  Person(this.name, this.age);

  final String name;
  final int age;
}

class PeopleCubit extends Cubit<PeopleState> {
  PeopleCubit() : super(PeopleState());

  void clear() {
    emit(PeopleState());
  }

  Future<void> loadData() async {
    emit(PeopleState(
      values: state.values,
      isLoading: true,
    ));
    await Future.delayed(const Duration(milliseconds: 500));

    if (state.values.length >= 15) {
      emit(PeopleState(
        values: state.values,
        isLoading: false,
        hasReachedMax: true,
      ));
      return;
    }

    emit(PeopleState(
      values: List.generate(
        state.values.length + 3,
        (i) => Person('Person $i', 20 + (i * 0.5).floor()),
      ),
      isLoading: false,
    ));
  }
}

class PeopleState extends Equatable {
  PeopleState({
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
