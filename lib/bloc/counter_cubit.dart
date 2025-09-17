import 'package:flutter_bloc/flutter_bloc.dart';

class CounterCubit extends Cubit<int> {
  CounterCubit({int initialValue = 0}) : super(initialValue);

  void increment() => emit(state + 1);

  void decrement() {
    if (state > 0) emit(state - 1);
  }

  void set(int value) => emit(value);
}
