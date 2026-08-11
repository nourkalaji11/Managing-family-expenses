import 'package:flutter_bloc/flutter_bloc.dart';

class ToggleCubit extends Cubit<bool> {
  ToggleCubit() : super(false) {
    emit(false);
  }

  bool toggleState = false;

  void toggle() {
    toggleState = !toggleState;
    emit(toggleState);
  }

  void toggleMainState(bool s) {
    toggleState = s;
    emit(toggleState);
  }
}
